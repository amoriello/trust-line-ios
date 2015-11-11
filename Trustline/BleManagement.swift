//
//  BleManagement.swift
//  Trustline
//
//  Created by matt on 20/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation

class BleManagement {
  typealias Handler = (token: Token2?, error: NSError?) -> (Void)
  
  // Discovers and pair to a new token
  
  class func pairWithNewToken(bleManager :BleManager2, handler: Handler) {
    findIsolatedToken(bleManager, onFoundToken: connectAndPair, handler: handler);
  }
  
  
  class func findAndConnectToken(bleManager: BleManager2, handler: Handler) {
    findIsolatedToken(bleManager, onFoundToken: connect, handler: handler)
  }
  

  class func connectToPairedToken(bleManager :BleManager2, pairedTokens : Set<CDPairedToken>, handler :Handler) {
    findIsolatedToken(bleManager, pairedTokens: pairedTokens, onFoundToken: connect, handler: handler)
  }
  
  
  
  // MARK: - Implementation details for pairing with new token
  private typealias FoundIsolatedTokenHandler = (token: Token2, handler: Handler) -> (Void)
  
  private class func findIsolatedToken(bleManager :BleManager2, pairedTokens :Set<CDPairedToken>? = nil, onFoundToken: FoundIsolatedTokenHandler, handler: Handler) {
    showMessage("Searching Token", hideOnTap: false, showAnnimation: true)
    
    bleManager.discoverTokens(pairedTokens) { (tokens, error) in
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
      
      let token = tokens[0];
      onFoundToken(token: token, handler: handler)
    }
  }
  
  
  // Connect to a token
  private class func connect(token: Token2, handler: Handler) {
    showMessage("Connecting...", hideOnTap: false, showAnnimation: true)

    token.connect { (error) -> (Void) in
      if error != nil {
        async { handler(token: nil, error: error) }
        return
      }
      
      showMessage("Connected!", hideOnTap: false, showAnnimation: true)
      async { handler(token: token, error: error) }
    }
  }
  
  
  // Connect and pair to a token
  private class func connectAndPair(token: Token2, handler: Handler) {
    showMessage("Connecting...", hideOnTap: false, showAnnimation: true)

    token.connect { (error) -> (Void) in
      if error != nil {
        async { handler(token: nil, error: error) }
        return
      }
      
      showMessage("Connected!", hideOnTap: false, showAnnimation: true)
      showMessage("Pairing...", hideOnTap: false, showAnnimation: true)
      
      token.pair { error in
        async { handler(token: token, error: error) }
      }
    }
  }

  
  private class func async(handler: () -> (Void)) {
    dispatch_async(dispatch_get_main_queue(), handler)
  }
  
}
