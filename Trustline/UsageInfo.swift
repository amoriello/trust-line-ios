//
//  UsageInfo.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import CoreData

@objc(CDUsageInfo)
class CDUsageInfo: NSManagedObject {
  @NSManaged private var infoType: Int16
  
  enum UsageType: Int16 {
    case Keyboard, Clipboard, Display
  }
  
  @NSManaged var date: NSDate
  
  var type: UsageType {
    get {
      return UsageType(rawValue: self.infoType)!
    }
    set {
      self.infoType = newValue.rawValue
    }
  }
  
}
