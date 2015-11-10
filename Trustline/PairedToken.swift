//
//  PairedToken.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import CoreData
import CoreBluetooth

@objc(CDPairedToken)
class CDPairedToken: NSManagedObject {
  @NSManaged private var tokenIdentifier: String
  
  @NSManaged var creation: NSDate
  
  var identifier: NSUUID {
    get {
      return NSUUID(UUIDString: self.tokenIdentifier)!
    }
    
    set {
      self.tokenIdentifier = newValue.UUIDString
    }
  }
  
  @NSManaged var profile: CDProfile
}
