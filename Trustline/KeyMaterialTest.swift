//
//  KeyMaterial.swift
//  Trustline
//
//  Created by matt on 10/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation


class KeyMaterial {
  var version :UInt8 = 1;
  
  let keySize = 16;
  
  var passKey :[UInt8]?
  var crKey   :[UInt8]?
  var comKey  :[UInt8]?
  
  init() {
  }
  
  init(crKey: [UInt8], reqKey: [UInt8]) {
    self.crKey = crKey
    self.comKey = reqKey
  }
  
  
  init?(fromBase64 data: String) {
    let res = NSData(base64EncodedString: data, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)

    if let data = res?.arrayOfBytes() {
      if data.count == 1 + (3 * keySize) {
        version = data[0]
        passKey = Array(data[1...keySize])
        crKey   = Array(data[1 + keySize...2 * keySize])
        comKey  = Array(data[1 + (2 * keySize)...3 * keySize])
        return
      }
    }
    return nil
  }
  
  func data() -> [UInt8] {
    var result: [UInt8] = []
    
    result.append(version)
    result.appendContentsOf(passKey!)
    result.appendContentsOf(crKey!)
    result.appendContentsOf(comKey!)

    return result
  }
  
  func base64Data() -> NSData {
    let keyData = data()
    return NSData(bytes: keyData, length: keyData.count).base64EncodedDataWithOptions(.Encoding64CharacterLineLength)
  }
}