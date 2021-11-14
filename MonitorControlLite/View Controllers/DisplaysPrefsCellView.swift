//  Copyright © MonitorControlLite. @waydabber

import Cocoa
import os.log

class DisplaysPrefsCellView: NSTableCellView {
  var display: Display?

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
  }

  @IBOutlet var displayImage: NSImageCell!
  @IBOutlet var friendlyName: NSTextFieldCell!
  @IBOutlet var displayId: NSTextFieldCell!
  @IBOutlet var enabledButton: NSButton!
  @IBOutlet var avoidGamma: NSButton!
  @IBOutlet var displayType: NSTextFieldCell!

  @IBAction func enabledButtonToggled(_ sender: NSButton) {
    if let disp = display {
      disp.savePref(sender.state == .off, key: .isDisabled)
    }
  }

  @IBAction func friendlyNameValueChanged(_ sender: NSTextFieldCell) {
    if let display = display {
      let newValue = sender.stringValue
      let originalValue = (display.readPrefAsString(key: .friendlyName) != "" ? display.readPrefAsString(key: .friendlyName) : display.name)

      if newValue.isEmpty {
        self.friendlyName.stringValue = originalValue
        return
      }

      if newValue != originalValue, !newValue.isEmpty {
        display.savePref(newValue, key: .friendlyName)
      }
      app.updateMenusAndKeys()
    }
  }

  @IBAction func avoidGamma(_ sender: NSButton) {
    if let display = display {
      _ = display.setSwBrightness(1)
      _ = display.setDirectBrightness(1)
      switch sender.state {
      case .on:
        display.savePref(true, key: .avoidGamma)
      case .off:
        display.savePref(false, key: .avoidGamma)
      default:
        break
      }
    }
  }
}
