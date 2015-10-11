//
//  KeyMaterial.swift
//  Trustline
//
//  Created by matt on 10/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation


class KeyMaterial {
  var CRKey  :[UInt8]?
  var ReqKey :[UInt8]?
  
  init() {
  }
  
  init(CRKey: [UInt8], ReqKey: [UInt8]) {
    self.CRKey = CRKey
    self.ReqKey = ReqKey
  }
}