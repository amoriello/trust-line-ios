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
  var isPaired: Bool = false
  var pairedDevice: PairedDevice?

  
  class Strength {
    var picketDescription: String
    var userDescription: String
    var nbCharacters: UInt8
    
    init(picketDescription: String, userDescription: String, nbCharacters: UInt8) {
      self.picketDescription = picketDescription
      self.userDescription = userDescription
      self.nbCharacters = nbCharacters
    }
  }
  
  enum KeyboardLayout: UInt8 {
    case Qwerty = 1, Azerty
  }

  var strengths: [Strength] = { [
    Strength(picketDescription: "Serious (8)", userDescription: "a serious", nbCharacters: 8),
    Strength(picketDescription: "Strong (15)", userDescription: "a strong", nbCharacters: 15),
    Strength(picketDescription: "Insane (25)", userDescription: "an insane", nbCharacters: 25),
    Strength(picketDescription: "Ludicrous (40)", userDescription: "a ludicrous", nbCharacters: 40)
    ]}()
  
  var defaultStrengthIndex = 1;
  
  var currentLayout :KeyboardLayout = .Qwerty
  
  var useICloud = false;
}