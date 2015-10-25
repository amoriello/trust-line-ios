//
//  Profile.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import CoreData

class CDProfile: NSManagedObject {
  @NSManaged var creation: NSDate
  @NSManaged var name: String
  
  
  @NSManaged var accounts: [CDAccount]
  @NSManaged var keyMaterial: CDKeyMaterial
  @NSManaged var pairedTokens: [CDPairedToken]
  @NSManaged var settings: CDSettings
}
