//  Copyright © MonitorControlLite. @waydabber

import Cocoa
import os.log
import Preferences
import ServiceManagement

class MainPrefsViewController: NSViewController, PreferencePane {
  let preferencePaneIdentifier = Preferences.PaneIdentifier.main
  let preferencePaneTitle: String = NSLocalizedString("General", comment: "Shown in the main prefs window")

  var toolbarItemIcon: NSImage {
    if !DEBUG_MACOS10, #available(macOS 11.0, *) {
      return NSImage(systemSymbolName: "switch.2", accessibilityDescription: "Display")!
    } else {
      return NSImage(named: NSImage.infoName)!
    }
  }

  @IBOutlet var startAtLogin: NSButton!
  @IBOutlet var allowZeroSwBrightness: NSButton!
  @IBOutlet var enableSmooth: NSButton!
  @IBOutlet var startupAction: NSPopUpButton!

  func updateGridLayout() {}

  @available(macOS, deprecated: 10.10)
  override func viewDidLoad() {
    super.viewDidLoad()
    self.populateSettings()
  }

  @available(macOS, deprecated: 10.10)
  func populateSettings() {
    // This is marked as deprectated but according to the function header it still does not have a replacement as of macOS 12 Monterey and is valid to use.
    let startAtLogin = (SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: AnyObject]])?.first { $0["Label"] as? String == "\(Bundle.main.bundleIdentifier!)Helper" }?["OnDemand"] as? Bool ?? false
    self.startAtLogin.state = startAtLogin ? .on : .off
    self.allowZeroSwBrightness.state = prefs.bool(forKey: PrefKey.allowZeroSwBrightness.rawValue) ? .on : .off
    self.enableSmooth.state = prefs.bool(forKey: PrefKey.disableSmoothBrightness.rawValue) ? .off : .on
    self.startupAction.selectItem(withTag: prefs.integer(forKey: PrefKey.startupAction.rawValue))
    // Preload Display preferences to some extent to properly set up size in orther that animation won't fail
    menuslidersPrefsVc?.view.layoutSubtreeIfNeeded()
    keyboardPrefsVc?.view.layoutSubtreeIfNeeded()
    displaysPrefsVc?.view.layoutSubtreeIfNeeded()
    aboutPrefsVc?.view.layoutSubtreeIfNeeded()
    self.updateGridLayout()
  }

  @IBAction func startAtLoginClicked(_ sender: NSButton) {
    switch sender.state {
    case .on:
      app.setStartAtLogin(enabled: true)
    case .off:
      app.setStartAtLogin(enabled: false)
    default: break
    }
  }

  @IBAction func allowZeroSwBrightness(_ sender: NSButton) {
    switch sender.state {
    case .on:
      prefs.set(true, forKey: PrefKey.allowZeroSwBrightness.rawValue)
    case .off:
      prefs.set(false, forKey: PrefKey.allowZeroSwBrightness.rawValue)
    default: break
    }
    for display in DisplayManager.shared.getAllDisplays() {
      _ = display.setDirectBrightness(1)
      _ = display.setSwBrightness(1)
    }
    self.updateGridLayout()
    app.configure()
  }

  @IBAction func enableSmooth(_ sender: NSButton) {
    switch sender.state {
    case .on:
      prefs.set(false, forKey: PrefKey.disableSmoothBrightness.rawValue)
    case .off:
      prefs.set(true, forKey: PrefKey.disableSmoothBrightness.rawValue)
    default: break
    }
  }

  @IBAction func startupAction(_ sender: NSPopUpButton) {
    prefs.set(sender.selectedTag(), forKey: PrefKey.startupAction.rawValue)
    self.updateGridLayout()
  }

  @available(macOS, deprecated: 10.10)
  func resetSheetModalHander(modalResponse: NSApplication.ModalResponse) {
    if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn {
      app.preferenceReset()
      self.populateSettings()
      menuslidersPrefsVc?.populateSettings()
      keyboardPrefsVc?.populateSettings()
    }
  }

  @available(macOS, deprecated: 10.10)
  @IBAction func resetPrefsClicked(_: NSButton) {
    let alert = NSAlert()
    alert.messageText = NSLocalizedString("Reset Preferences?", comment: "Shown in the alert dialog")
    alert.informativeText = NSLocalizedString("Are you sure you want to reset all preferences?", comment: "Shown in the alert dialog")
    alert.addButton(withTitle: NSLocalizedString("Yes", comment: "Shown in the alert dialog"))
    alert.addButton(withTitle: NSLocalizedString("No", comment: "Shown in the alert dialog"))
    alert.alertStyle = NSAlert.Style.warning
    if let window = self.view.window {
      alert.beginSheetModal(for: window, completionHandler: { modalResponse in self.resetSheetModalHander(modalResponse: modalResponse) })
    }
  }
}
