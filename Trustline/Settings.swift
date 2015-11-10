//
//  Settings.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import CoreData

@objc(CDSettings)
class CDSettings: NSManagedObject {
  @NSManaged private var keyboardLayout: Int16
  
  enum KeyboardLayoutOptions: Int16 {
    case EnglishUS = 0
  }
  
  @NSManaged var useiCloud: Bool
  
  @NSManaged var profile: CDProfile
//  @NSManaged var strengths: NSSet
  @NSManaged var strengths: Set<CDStrength>

  
  var layoutOption: KeyboardLayoutOptions {
    get {
      return KeyboardLayoutOptions(rawValue: self.keyboardLayout)!
    }
    
    set {
      self.keyboardLayout = newValue.rawValue
    }
  }
}
