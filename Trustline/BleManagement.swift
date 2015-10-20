//
//  BleManagement.swift
//  Trustline
//
//  Created by matt on 20/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation

class BleManagement {
  typealias PairHandler = (token: Token2?, error: NSError?) -> (Void)
  typealias ConnectedHandler = (token: Token2?, error: NSError?) -> (Void)
  
  // Discovers and pair to a new token
  
  class func pairWithNewToken(bleManager :BleManager2, handler: PairHandler) {
    doPairWithNewToken(bleManager, handler: handler)
  }
  
  
  class func connectToPairedToken(bleManager :BleManager2, pairedDevice :PairedDevice, handler :ConnectedHandler) {
    doConnectToPairedToken(bleManager, pairedDevice: pairedDevice, handler: handler)
  }
  
  
  
  
  // MARK: - Implementation details for pairing with new token
  private class func doPairWithNewToken(bleManager :BleManager2, handler: PairHandler) {
    showMessage("Searching Tokens", hideOnTap: false, showAnnimation: true)
    
    bleManager.discoverTokens { (tokens, error) in
      if error != nil {
        async { handler(token: nil, error: error) }
        return
      }
      
      if (tokens.count == 0) {
        async { handler(token: nil, error: createError("No token found", description: "Try to be closer to your token", code: 1)) }
        return
      }
      
      if (tokens.count > 1) {
        async { handler(token: nil, error: createError("Too many tokens found", description: "\(tokens.count) found, isolate the one you don't want", code: 1)) }
        return
      }
      
      showMessage("Token found", hideOnTap: false, showAnnimation: true)
      showMessage("Connecting...", hideOnTap: false, showAnnimation: true)
      
      
      let token = tokens[0];
      connectAndPair(token, handler: handler)
    }
  }
  
  // Connect to a token
  private class func connectAndPair(token: Token2, handler: PairHandler) {
    token.connect { (error) -> (Void) in
      if error != nil {
        async { handler(token: nil, error: error) }
        return
      }
      
      showMessage("Connected!", hideOnTap: false, showAnnimation: true)
      showMessage("Pairing...", hideOnTap: false, showAnnimation: true)
      
      pairWithConnectedToken(token, handler: handler)
    }
  }
  
  // Pair with a connected token
  private class func pairWithConnectedToken(token: Token2, handler: PairHandler) {
    token.pair { (error) in
      async { handler(token: token, error: error) }
    }
  }
  
  
  // MARK: - Implementation details for connecting with existing token
  private class func doConnectToPairedToken(bleManager :BleManager2, pairedDevice :PairedDevice, handler: PairHandler) {
    showMessage("Searching token", hideOnTap: false, showAnnimation: true)
    
    
    bleManager.discoverTokens(pairedDevice) { (tokens, error) -> (Void) in
      if error != nil {
        async { handler(token: nil, error: error) }
        return
      }
      
      if tokens.count == 0 {
        async { handler(token: nil, error: createError("No token found", description: "Try to be closer to your token", code: 1)) }
        return
      }
      
      async { handler(token: tokens[0], error: nil) }
    }
  }
  

  private class func async(handler: () -> (Void)) {
    dispatch_async(dispatch_get_main_queue(), handler)
  }
  
}
