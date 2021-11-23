//  Copyright © MonitorControlLite. @waydabber

import Cocoa

public extension NSScreen {
  var displayID: CGDirectDisplayID {
    return (self.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID)!
  }

  var vendorNumber: UInt32? {
    switch CGDisplayVendorNumber(self.displayID) {
    case 0xFFFF_FFFF:
      return nil
    case let vendorNumber:
      return vendorNumber
    }
  }

  var modelNumber: UInt32? {
    switch CGDisplayModelNumber(self.displayID) {
    case 0xFFFF_FFFF:
      return nil
    case let modelNumber:
      return modelNumber
    }
  }

  var serialNumber: UInt32? {
    switch CGDisplaySerialNumber(self.displayID) {
    case 0x0000_0000:
      return nil
    case let serialNumber:
      return serialNumber
    }
  }
}
