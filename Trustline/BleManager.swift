//
//  BleManager.swift
//  Trustline
//
//  Created by matt on 10/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation
import CoreBluetooth





//----------------------------------------------------------------------------------------
class BleManager2: NSObject, CBCentralManagerDelegate {
  typealias DiscoverHandler = ([Token2], NSError?) -> (Void)
  typealias ConnectToPairedTokenHander = (Token2?, NSError?) -> (Void)
  typealias ManagerStateErrorHandler = (NSError?) -> (Void)
  
  var centralManager :CBCentralManager!
  var tokens :[Token2] = []

  var managerStateErrorHandler :ManagerStateErrorHandler
  var discoverHandler :DiscoverHandler?
  var keyMaterial :KeyMaterial?
  var pairedIdentifier :NSUUID?
  var discoveredPaired = false
  
  var tokenServiceCBUUID = g_tokenServiceCBUUID
  
  init(managerStateErrorHandler: ManagerStateErrorHandler, keyMaterial :KeyMaterial?) {
    self.managerStateErrorHandler = managerStateErrorHandler
    self.keyMaterial = keyMaterial
  }
  
  func createError(description: String, code: Int = 1) -> NSError {
    let userInfo = [NSLocalizedDescriptionKey: description]
    return NSError(domain: "BletoothManager", code: code, userInfo: userInfo)
  }
  
  func discoverTokens(completion: DiscoverHandler) {
    print("initializing central manager");
    discoverHandler = completion
    
    if centralManager == nil {
      print("Creating central manager")
      centralManager = CBCentralManager(delegate:self, queue:nil)
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
      notify(createError("CoreBluetooth BLE hardware is powered off"));
      
    case .Resetting:
      notify(createError("CoreBluetooth BLE hardware is resetting"));
      
    case .Unauthorized:
      notify(createError("CoreBluetooth BLE state is unauthorized"))
      
    case .Unknown:
      notify(createError("CoreBluetooth BLE state is unknown"))
      
    case .Unsupported:
      notify(createError("CoreBluetooth BLE hardware is unsupported on this platform"))
      
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

    if let pairedTokenIdentifier = pairedIdentifier {
      if peripheral.identifier == pairedTokenIdentifier {
        let token = Token2(centralManager: centralManager, peripheral: peripheral, keyMaterial: keyMaterial)
        discoveredPaired = true;
        discoverHandler!([token], nil)
        centralManager.stopScan()
        return
      }
    }
    tokens.append(Token2(centralManager: centralManager, peripheral: peripheral, keyMaterial: keyMaterial))
  }
  
  func scanTimeout(timer: NSTimer) {
    print("Yeah!")
    if !discoveredPaired {
      centralManager.stopScan()
      discoverHandler!(tokens, nil)
    }
  }
  
  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
    print("Connected to \(peripheral.name)")
    peripheral.discoverServices(nil)
  }  
}
