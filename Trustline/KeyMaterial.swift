//
//  KeyMaterial.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import CoreData

@objc(CDKeyMaterial)
class CDKeyMaterial: NSManagedObject {
  let version : UInt8 = 1
  let keySize = 16

  var passKey = NSData() // In memory only
  
  @NSManaged var creation: NSDate
  @NSManaged var crKey: NSData
  @NSManaged var comKey: NSData

  @NSManaged var profile: CDProfile
  
  
  func loadFrom(fromBase64 data: String) -> NSError? {
    let res = NSData(base64EncodedString: data, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
    
    
    if let data = res {
      if data.length == 1 + (3 * keySize) {
        passKey = data.subdataWithRange(NSRange(location: 1 + (0 * keySize), length: keySize))
        crKey   = data.subdataWithRange(NSRange(location: 1 + (1 * keySize), length: keySize))
        comKey  = data.subdataWithRange(NSRange(location: 1 + (2 * keySize), length: keySize))
        return nil
      }
    }
    return createError("Invalid QrCode", description: "Cannot load Trustline secret data from this QrCode")
  }
  
  
  func base64Data() -> NSData {
    let keyData = data()
    return NSData(bytes: keyData, length: keyData.count).base64EncodedDataWithOptions(.Encoding64CharacterLineLength)
  }
  
  
  func data() -> [UInt8] {
    var result: [UInt8] = []
    
    result.append(version)
    result.appendContentsOf(passKey.arrayOfBytes())
    result.appendContentsOf(crKey.arrayOfBytes())
    result.appendContentsOf(comKey.arrayOfBytes())
    
    return result
  }
}
