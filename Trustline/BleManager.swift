//
//  BleManager.swift
//  Trustline
//
//  Created by matt on 10/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation
import CoreBluetooth



let g_tokenServiceCBUUID = CBUUID(string:"713D0000-503E-4C75-BA94-3148F18D941E")
let g_tokenReadCharacteristicUUID = CBUUID(string:"713D0002-503E-4C75-BA94-3148F18D941E")
let g_tokenWriteCharacteristicUUID = CBUUID(string:"713D0003-503E-4C75-BA94-3148F18D941E")

//----------------------------------------------------------------------------------------
class BleManager: NSObject, CBCentralManagerDelegate {
  typealias DiscoverHandler = ([Token], NSError?) -> (Void)
  typealias ConnectToPairedTokenHander = (Token?, NSError?) -> (Void)
  typealias ManagerStateErrorHandler = (NSError?) -> (Void)
  
  var centralManager :CBCentralManager!
  var tokens :[Token] = []

  var managerStateErrorHandler :ManagerStateErrorHandler
  var discoverHandler :DiscoverHandler?
  var keyMaterial :CDKeyMaterial
  var pairedTokens : Set<CDPairedToken>?
  var discoveredPaired = false
  
  var tokenServiceCBUUID = g_tokenServiceCBUUID
  
  init(managerStateErrorHandler: ManagerStateErrorHandler, keyMaterial: CDKeyMaterial) {
    self.managerStateErrorHandler = managerStateErrorHandler
    self.keyMaterial = keyMaterial
  }
  

  func discoverTokens(pairedTokens :Set<CDPairedToken>? = nil, completion: DiscoverHandler) {
    print("initializing central manager");
    discoverHandler = completion
    self.pairedTokens = pairedTokens
    
    if centralManager == nil {
      print("Creating central manager")
      centralManager = CBCentralManager(delegate:self, queue:nil)
    } else {
      tokens = []
      centralManager.scanForPeripheralsWithServices([tokenServiceCBUUID], options: nil)
    }

    NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "scanTimeout:", userInfo: nil, repeats: false)
  }
  
  func notify(error: NSError) {
    if let _ = discoverHandler {
      discoverHandler!([], error)
      discoverHandler = nil
    }
    
    managerStateErrorHandler(error);
  }
  
  func centralManagerDidUpdateState(central: CBCentralManager) {
    print("central manager updated state");
    
    switch (central.state) {
    case .PoweredOff:
      notify(createError("Bluetooth error", description: "Hardware is powered off"));
      
    case .Resetting:
      notify(createError("Bluetooth error", description: "Hardware is resetting"));
      
    case .Unauthorized:
      notify(createError("Bluetooth error", description: "State is unauthorized"))
      
    case .Unknown:
      notify(createError("Bluetooth error", description: "State is unknown"))
      
    case .Unsupported:
      notify(createError("Bluetooth error", description: "Hardware is unsupported on this platform"))
      
    case .PoweredOn:
      if discoverHandler != nil {
        centralManager.scanForPeripheralsWithServices([tokenServiceCBUUID], options: nil)
      } else {
        print("No discoverHandler")
      }
    }
  }
  
  func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
    print("Discovered \(peripheral.name), RSSI: \(RSSI) UUID: \(peripheral.identifier.UUIDString)")

    if pairedTokens != nil {
      for pairedToken in pairedTokens! {
        if peripheral.identifier == pairedToken.identifier {
          let token = Token(centralManager: centralManager, peripheral: peripheral, keyMaterial: keyMaterial, identifier: peripheral.identifier, connectionStateHandler: managerStateErrorHandler)
          discoveredPaired = true;
          discoverHandler!([token], nil)
          centralManager.stopScan()
          return
        }
      }
    }
    
    tokens.append(Token(centralManager: centralManager, peripheral: peripheral,
                        keyMaterial: keyMaterial, identifier: peripheral.identifier,
                        connectionStateHandler: managerStateErrorHandler))
  }
  
  
  func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    managerStateErrorHandler(error);
  }

  func scanTimeout(timer: NSTimer) {
    if !discoveredPaired {
      centralManager.stopScan()
      // discoverHandler normaly set to nil in notify function
      if discoverHandler != nil {
        discoverHandler!(tokens, nil)
      }
    }
    // Re-initialize value
    discoveredPaired = false
  }
  
  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
    print("Connected to \(peripheral.name)")
    peripheral.discoverServices(nil)
  }  
}
