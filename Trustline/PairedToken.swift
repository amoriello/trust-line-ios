//
//  PairedToken.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import CoreData
import CoreBluetooth

class CDPairedToken: NSManagedObject {
  @NSManaged private var tokenIdentifier: String
  
  @NSManaged var creation: NSDate
  
  var identifier: CBUUID {
    get {
      return CBUUID(string: self.tokenIdentifier)
    }
    
    set {
      self.tokenIdentifier = newValue.UUIDString
    }
  }
  
  @NSManaged var profile: CDProfile
}
