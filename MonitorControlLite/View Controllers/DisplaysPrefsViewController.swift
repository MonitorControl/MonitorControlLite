//  Copyright © MonitorControlLite. @waydabber

import Cocoa
import os.log
import Preferences

class DisplaysPrefsViewController: NSViewController, PreferencePane, NSTableViewDataSource, NSTableViewDelegate {
  let preferencePaneIdentifier = Preferences.PaneIdentifier.displays
  let preferencePaneTitle: String = NSLocalizedString("Displays", comment: "Shown in the main prefs window")

  var toolbarItemIcon: NSImage {
    if !DEBUG_MACOS10, #available(macOS 11.0, *) {
      return NSImage(systemSymbolName: "display.2", accessibilityDescription: "Displays")!
    } else {
      return NSImage(named: NSImage.infoName)!
    }
  }

  var displays: [Display] = []

  @IBOutlet var displayList: NSTableView!
  @IBOutlet var displayScrollView: NSScrollView!
  @IBOutlet var constraintHeight: NSLayoutConstraint!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.displayScrollView.scrollerStyle = .legacy
    self.loadDisplayList()
  }

  override func viewWillAppear() {
    super.viewWillAppear()
  }

  @objc func loadDisplayList() {
    guard self.displayList != nil else {
      os_log("Reloading Displays preferences display list skipped as there is no display list table yet.", type: .info)
      return
    }
    os_log("Reloading Displays preferences display list", type: .info)
    self.displays = DisplayManager.shared.getAllDisplays()
    self.displayList?.reloadData()
    self.updateDisplayListRowHeight()
  }

  func numberOfRows(in _: NSTableView) -> Int {
    return self.displays.count
  }

  public static func isImac() -> Bool {
    let platformExpertDevice = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
    if let modelData = IORegistryEntryCreateCFProperty(platformExpertDevice, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data, let modelIdentifierCString = String(data: modelData, encoding: .utf8)?.cString(using: .utf8) {
      let modelIdentifier = String(cString: modelIdentifierCString)
      return modelIdentifier.contains("iMac")
    }
    return false
  }

  public struct DisplayInfo {
    var displayType = ""
    var displayImage = ""
    var controlMethod = ""
    var controlStatus = ""
  }

  public static func getDisplayInfo(display: Display) -> DisplayInfo {
    var displayType = NSLocalizedString("Other Display", comment: "Shown in the Display Preferences")
    var displayImage = "display.trianglebadge.exclamationmark"
    if display.isDummy {
      displayType = NSLocalizedString("Dummy Display", comment: "Shown in the Display Preferences")
    } else if display.isVirtual {
      displayType = NSLocalizedString("Virtual Display", comment: "Shown in the Display Preferences")
      displayImage = "tv.and.mediabox"
    } else if !display.isDummy {
      if display.isBuiltIn() {
        displayType = NSLocalizedString("Built-in Display", comment: "Shown in the Display Preferences")
        if self.isImac() {
          displayImage = "desktopcomputer"
        } else {
          displayImage = "laptopcomputer"
        }
      } else {
        displayType = NSLocalizedString("External Display", comment: "Shown in the Display Preferences")
        displayImage = "display"
      }
    }
    return DisplayInfo(displayType: displayType, displayImage: displayImage)
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let tableColumn = tableColumn else {
      return nil
    }
    os_log("Populating Displays Table")
    let display = self.displays[row]
    if let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: nil) as? DisplaysPrefsCellView {
      cell.display = display

      // ID
      cell.displayId.stringValue = String(display.identifier)
      // Firendly name
      cell.friendlyName.stringValue = (display.readPrefAsString(key: .friendlyName) != "" ? display.readPrefAsString(key: .friendlyName) : display.name)
      cell.friendlyName.isEditable = true
      // Enabled
      cell.enabledButton.state = display.readPrefAsBool(key: .isDisabled) ? .off : .on
      // Enabled
      cell.avoidGamma.state = display.readPrefAsBool(key: .avoidGamma) ? .on : .off
      if display.isVirtual {
        cell.avoidGamma.isEnabled = false
      } else {
        cell.avoidGamma.isEnabled = true
      }
      // Display type, image, control method
      let displayInfo = DisplaysPrefsViewController.getDisplayInfo(display: display)
      cell.displayType.stringValue = displayInfo.displayType
      if !DEBUG_MACOS10, #available(macOS 11.0, *) {
        cell.displayImage.image = NSImage(systemSymbolName: displayInfo.displayImage, accessibilityDescription: display.name)!
      } else {
        cell.displayImage.image = NSImage(named: NSImage.touchBarIconViewTemplateName)!
      }
      return cell
    }
    return nil
  }

  func updateDisplayListRowHeight() {
    self.displayList?.rowHeight = 210
    self.constraintHeight?.constant = self.displayList.rowHeight * 2.1
  }
}
