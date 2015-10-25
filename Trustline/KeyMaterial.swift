//
//  KeyMaterial.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import CoreData

class CDKeyMaterial: NSManagedObject {
  @NSManaged var creation: NSDate
  @NSManaged var crKey: NSData
  @NSManaged var reqKey: NSData

  @NSManaged var profile: CDProfile
}
