//
//  Settings.swift
//  Trustline
//
//  Created by matt on 09/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation

class PairedDevice {
  var identifier :NSUUID?
}

class TrustLineSettings {
  class Strength {
    var description: String
    var nbCharacters: UInt8
    var pairedDevice: PairedDevice?
    
    init(description: String, nbCharacters: UInt8) {
      self.description = description
      self.nbCharacters = nbCharacters
    }
  }
  
  enum KeyboardLayout: UInt8 {
    case Qwerty = 1, Azerty
  }

  var strengths: [Strength] = { [
    Strength(description: "Serious (8)", nbCharacters: 8),
    Strength(description: "Strong (15)", nbCharacters: 15),
    Strength(description: "Insane (25)", nbCharacters: 25),
    Strength(description: "Ludicrous (40)", nbCharacters: 40)
    ]}()
  
  
  var currentLayout :KeyboardLayout = .Qwerty
  
  var useICloud = false;
}