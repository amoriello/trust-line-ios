//
//  KeyMaterial.swift
//  Trustline
//
//  Created by matt on 10/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation


class KeyMaterial {
  let version :UInt8 = 1;
  var passKey :[UInt8]?
  var crKey   :[UInt8]?
  var reqKey  :[UInt8]?
  
  init() {
  }
  
  init(crKey: [UInt8], reqKey: [UInt8]) {
    self.crKey = crKey
    self.reqKey = reqKey
  }
  
  func rawData() -> [UInt8] {
    var result: [UInt8] = []
    
    result.append(version)
    result.appendContentsOf(passKey!)
    result.appendContentsOf(crKey!)
    result.appendContentsOf(reqKey!)
    return result
  }
}