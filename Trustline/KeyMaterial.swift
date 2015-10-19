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
  var passKey :[UInt8]?
  var crKey   :[UInt8]?
  var reqKey  :[UInt8]?
  
  init() {
  }
  
  init(crKey: [UInt8], reqKey: [UInt8]) {
    self.crKey = crKey
    self.reqKey = reqKey
  }
  
  
  init?(fromBase64 data: String) {
    let res = NSData(base64EncodedString: data, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)

    if let data = res?.arrayOfBytes() {
      if data.count == 49 {
        version = data[0]
        passKey = Array(data[1...16])
        crKey = Array(data[17...32])
        reqKey = Array(data[33...48])
        return
      }
    }
    return nil
  }
  
  func base64Data() -> NSData {
    var result: [UInt8] = []
    
    result.append(version)
    result.appendContentsOf(passKey!)
    result.appendContentsOf(crKey!)
    result.appendContentsOf(reqKey!)
    
    return NSData(bytes: result, length: result.count).base64EncodedDataWithOptions(.Encoding64CharacterLineLength)
  }
}