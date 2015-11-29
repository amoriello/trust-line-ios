//
//  Profile.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import CoreData

@objc(CDProfile)
class CDProfile: NSManagedObject {
  @NSManaged var name: String
  @NSManaged var creation: NSDate
  
  @NSManaged var accounts: Set<CDAccount>

  @NSManaged var pairedTokens: Set<CDPairedToken>
  @NSManaged var settings: CDSettings
}

