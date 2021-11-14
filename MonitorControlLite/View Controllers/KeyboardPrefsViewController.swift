//  Copyright © MonitorControlLite. @waydabber

import Cocoa
import KeyboardShortcuts
import Preferences
import ServiceManagement

class KeyboardPrefsViewController: NSViewController, PreferencePane {
  let preferencePaneIdentifier = Preferences.PaneIdentifier.keyboard
  let preferencePaneTitle: String = NSLocalizedString("Keyboard", comment: "Shown in the main prefs window")

  var toolbarItemIcon: NSImage {
    if !DEBUG_MACOS10, #available(macOS 11.0, *) {
      return NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyboard")!
    } else {
      return NSImage(named: NSImage.infoName)!
    }
  }

  @IBOutlet var customBrightnessUp: NSView!
  @IBOutlet var customBrightnessDown: NSView!

  @IBOutlet var keyboardBrightness: NSPopUpButton!

  @IBOutlet var multiKeyboardBrightness: NSPopUpButton!

  @IBOutlet var rowKeyboardBrightnessPopUp: NSGridRow!
  @IBOutlet var rowCustomBrightnessShortcuts: NSGridRow!
  @IBOutlet var rowMultiKeyboardBrightness: NSGridRow!
  @IBOutlet var rowUseFocusText: NSGridRow!

  func updateGridLayout() {
    if self.keyboardBrightness.selectedTag() == KeyboardBrightness.custom.rawValue {
      self.rowCustomBrightnessShortcuts.isHidden = false
    } else {
      self.rowCustomBrightnessShortcuts.isHidden = true
    }

    if self.keyboardBrightness.selectedTag() == KeyboardBrightness.disabled.rawValue {
      self.multiKeyboardBrightness.isEnabled = false
    } else {
      self.multiKeyboardBrightness.isEnabled = true
    }

    if self.multiKeyboardBrightness.selectedTag() == MultiKeyboardBrightness.focusInsteadOfMouse.rawValue {
      self.rowUseFocusText.isHidden = false
    } else {
      self.rowUseFocusText.isHidden = true
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let customBrightnessUpRecorder = KeyboardShortcuts.RecorderCocoa(for: .brightnessUp)
    let customBrightnessDownRecorder = KeyboardShortcuts.RecorderCocoa(for: .brightnessDown)

    self.customBrightnessUp.addSubview(customBrightnessUpRecorder)
    self.customBrightnessDown.addSubview(customBrightnessDownRecorder)

    self.populateSettings()
  }

  func populateSettings() {
    self.keyboardBrightness.selectItem(withTag: prefs.integer(forKey: PrefKey.keyboardBrightness.rawValue))
    self.multiKeyboardBrightness.selectItem(withTag: prefs.integer(forKey: PrefKey.multiKeyboardBrightness.rawValue))
    self.updateGridLayout()
  }

  @IBAction func multiKeyboardBrightness(_ sender: NSPopUpButton) {
    prefs.set(sender.selectedTag(), forKey: PrefKey.multiKeyboardBrightness.rawValue)
    self.updateGridLayout()
  }

  @IBAction func keyboardBrightness(_ sender: NSPopUpButton) {
    prefs.set(sender.selectedTag(), forKey: PrefKey.keyboardBrightness.rawValue)
    app.updateMenusAndKeys()
    self.updateGridLayout()
  }
}
