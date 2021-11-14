//  Copyright © MonitorControlLite. @waydabber

import AVFoundation
import Cocoa
import Foundation
import os.log
import Preferences
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  var keyboardShortcuts = KeyboardShortcutsManager()
  var reconfigureID: Int = 0 // dispatched reconfigure command ID
  var sleepID: Int = 0 // sleep event ID
  var safeMode = false

  var preferencePaneStyle: Preferences.Style {
    if !DEBUG_MACOS10, #available(macOS 11.0, *) {
      return Preferences.Style.toolbarItems
    } else {
      return Preferences.Style.segmentedControl
    }
  }

  lazy var preferencesWindowController: PreferencesWindowController = {
    PreferencesWindowController(
      preferencePanes: [
        mainPrefsVc!,
        menuslidersPrefsVc!,
        keyboardPrefsVc!,
        displaysPrefsVc!,
        aboutPrefsVc!,
      ],
      style: preferencePaneStyle,
      animated: true
    )
  }()

  func applicationDidFinishLaunching(_: Notification) {
    app = self
    menu = MenuHandler()
    menu.delegate = menu
    self.subscribeEventListeners()
    if NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.shift) {
      self.safeMode = true
      let alert = NSAlert()
      alert.messageText = NSLocalizedString("Safe Mode Activated", comment: "Shown in the alert dialog")
      alert.informativeText = NSLocalizedString("Shift was pressed during launch. MonitorControl Lite started in safe mode. Default preferences are reloaded.", comment: "Shown in the alert dialog")
      alert.runModal()
    }
    let currentBuildNumber = Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1") ?? 1
    let previousBuildNumber: Int = (Int(prefs.string(forKey: PrefKey.buildNumber.rawValue) ?? "0") ?? 0)
    if self.safeMode || ((previousBuildNumber < MIN_PREVIOUS_BUILD_NUMBER) && previousBuildNumber > 0) || (previousBuildNumber > currentBuildNumber), let bundleID = Bundle.main.bundleIdentifier {
      if !self.safeMode {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Incompatible previous version", comment: "Shown in the alert dialog")
        alert.informativeText = NSLocalizedString("Preferences for an incompatible previous app version detected. Default preferences are reloaded.", comment: "Shown in the alert dialog")
        alert.runModal()
      }
      prefs.removePersistentDomain(forName: bundleID)
    }
    prefs.set(currentBuildNumber, forKey: PrefKey.buildNumber.rawValue)
    self.setDefaultPrefs()
    if !DEBUG_MACOS10, #available(macOS 11.0, *) {
      self.statusItem.button?.image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "MonitorControl Lite")
    } else {
      self.statusItem.button?.image = NSImage(named: "status")
    }
    self.statusItem.menu = menu
    CGDisplayRegisterReconfigurationCallback({ _, _, _ in app.displayReconfigured() }, nil)
    self.configure(firstrun: true)
    DisplayManager.shared.createGammaActivityEnforcer()
  }

  @objc func quitClicked(_: AnyObject) {
    os_log("Quit clicked", type: .info)
    NSApplication.shared.terminate(self)
  }

  @objc func prefsClicked(_: AnyObject) {
    os_log("Preferences clicked", type: .info)
    self.preferencesWindowController.show()
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
    app.prefsClicked(self)
    return true
  }

  func applicationWillTerminate(_: Notification) {
    os_log("Goodbye!", type: .info)
    DisplayManager.shared.resetSwBrightnessForAllDisplays(noPrefSave: true)
    self.statusItem.isVisible = true
  }

  func setDefaultPrefs() {
    if !prefs.bool(forKey: PrefKey.appAlreadyLaunched.rawValue) {
      // Only preferences that are not false, 0 or "" by default are set here. Assumes pre-wiped database.
      prefs.set(true, forKey: PrefKey.appAlreadyLaunched.rawValue)
    }
  }

  @objc func displayReconfigured() {
    DisplayManager.shared.resetSwBrightnessForAllDisplays(noPrefSave: true)
    CGDisplayRestoreColorSyncSettings()
    self.reconfigureID += 1
    os_log("Bumping reconfigureID to %{public}@", type: .info, String(self.reconfigureID))
    _ = DisplayManager.shared.destroyAllShades()
    if self.sleepID == 0 {
      let dispatchedReconfigureID = self.reconfigureID
      os_log("Display to be reconfigured with reconfigureID %{public}@", type: .info, String(dispatchedReconfigureID))
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.configure(dispatchedReconfigureID: dispatchedReconfigureID)
      }
    }
  }

  func configure(dispatchedReconfigureID: Int = 0, firstrun: Bool = false) {
    guard self.sleepID == 0, dispatchedReconfigureID == self.reconfigureID else {
      return
    }
    os_log("Request for configuration with reconfigreID %{public}@", type: .info, String(dispatchedReconfigureID))
    self.reconfigureID = 0
    DisplayManager.shared.gammaInterferenceCounter = 0
    DisplayManager.shared.configureDisplays()
    DisplayManager.shared.addDisplayCounterSuffixes()
    if firstrun && prefs.integer(forKey: PrefKey.startupAction.rawValue) != StartupAction.write.rawValue {
      DisplayManager.shared.resetSwBrightnessForAllDisplays(prefsOnly: true)
    }
    DisplayManager.shared.setupOtherDisplays(firstrun: firstrun)
    self.updateMenusAndKeys()
    if !firstrun || prefs.integer(forKey: PrefKey.startupAction.rawValue) == StartupAction.write.rawValue {
      DisplayManager.shared.restoreSwBrightnessForAllDisplays(async: !prefs.bool(forKey: PrefKey.disableSmoothBrightness.rawValue))
    }
    displaysPrefsVc?.loadDisplayList()
  }

  func updateMenusAndKeys() {
    menu.updateMenus()
  }

  private func subscribeEventListeners() {
    DistributedNotificationCenter.default.addObserver(self, selector: #selector(self.displayReconfigured), name: NSNotification.Name(rawValue: kColorSyncDisplayDeviceProfilesNotification.takeRetainedValue() as String), object: nil) // ColorSync change
    NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepNotification), name: NSWorkspace.screensDidSleepNotification, object: nil) // sleep and wake listeners
    NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.wakeNotification), name: NSWorkspace.screensDidWakeNotification, object: nil)
    NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepNotification), name: NSWorkspace.willSleepNotification, object: nil)
    NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.wakeNotification), name: NSWorkspace.didWakeNotification, object: nil)
  }

  @objc private func sleepNotification() {
    self.sleepID += 1
    os_log("Sleeping with sleep %{public}@", type: .info, String(self.sleepID))
  }

  @objc private func wakeNotification() {
    if self.sleepID != 0 {
      os_log("Waking up from sleep %{public}@", type: .info, String(self.sleepID))
      let dispatchedSleepID = self.sleepID
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { // Some displays take time to recover...
        self.soberNow(dispatchedSleepID: dispatchedSleepID)
      }
    }
  }

  private func soberNow(dispatchedSleepID: Int) {
    if self.sleepID == dispatchedSleepID {
      os_log("Sober from sleep %{public}@", type: .info, String(self.sleepID))
      self.sleepID = 0
      if self.reconfigureID != 0 {
        let dispatchedReconfigureID = self.reconfigureID
        os_log("Displays need reconfig after sober with reconfigureID %{public}@", type: .info, String(dispatchedReconfigureID))
        self.configure(dispatchedReconfigureID: dispatchedReconfigureID)
      }
    }
  }

  func preferenceReset() {
    os_log("Resetting all preferences.")
    DisplayManager.shared.resetSwBrightnessForAllDisplays(async: false)
    if let bundleID = Bundle.main.bundleIdentifier {
      prefs.removePersistentDomain(forName: bundleID)
    }
    app.statusItem.isVisible = true
    self.setDefaultPrefs()
    self.configure(firstrun: true)
  }

  func setStartAtLogin(enabled: Bool) {
    let identifier = "\(Bundle.main.bundleIdentifier!)Helper" as CFString
    SMLoginItemSetEnabled(identifier, enabled)
  }

  func getSystemPreferences() -> [String: AnyObject]? {
    var propertyListFormat = PropertyListSerialization.PropertyListFormat.xml
    let plistPath = NSString(string: "~/Library/Preferences/.GlobalPreferences.plist").expandingTildeInPath
    guard let plistXML = FileManager.default.contents(atPath: plistPath) else {
      return nil
    }
    do {
      return try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListFormat) as? [String: AnyObject]
    } catch {
      os_log("Error reading system prefs plist: %{public}@", type: .info, error.localizedDescription)
      return nil
    }
  }

  func macOS10() -> Bool {
    if !DEBUG_MACOS10, #available(macOS 11.0, *) {
      return false
    } else {
      return true
    }
  }
}
