//
//  KeyMaterial2.swift
//  Trustline
//
//  Created by matt on 23/11/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation
import SwiftyJSON
import KeychainAccess

class KeyMaterial {
  let version : UInt8 = 1
  let keySize = 16
  
  var passKey = NSData() // In memory only
  
  var crKey = NSData()
  var comKey = NSData()
  
  
  init() { }
  
  init?(fromBase64 data: String) {
    if loadFrom(fromBase64: data) != nil {
      return nil
    }
  }
  
  
  class func getFromUUID(identifier: NSUUID) -> KeyMaterial? {
    let keychain = Keychain(service: "com.Trustline")

    if let kmString = keychain[identifier.UUIDString] {
      return KeyMaterial(fromBase64: kmString)
    } else {
      return nil
    }
  }
  
  
  class func secureSave(identifier: NSUUID, km: KeyMaterial) {
    let keychain = Keychain(service: "com.Trustline")
    do {
      try keychain
        .accessibility(.WhenUnlockedThisDeviceOnly)
        .synchronizable(false)
        .set(km.base64Data(), key: identifier.UUIDString)
    } catch {
      print("error saving Key Material: \(error)")
    }
  }
  
  
  private func loadFrom(fromBase64 data: String) -> NSError? {
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
