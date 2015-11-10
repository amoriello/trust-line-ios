//
//  KeyboardStrength.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import CoreData

@objc(CDStrength)
class CDStrength: NSManagedObject {
  @NSManaged var nbChars: Int16
  @NSManaged var pickerDescription: String
  @NSManaged var settings: Set<CDSettings>
}
