//
//  BleToken.swift
//  Trustline
//
//  Created by matt on 04/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//


import Foundation
import CoreBluetooth
import CryptoSwift

let g_tokenServiceCBUUID = CBUUID(string:"713D0000-503E-4C75-BA94-3148F18D941E")
let g_tokenReadCharacteristicUUID = CBUUID(string:"713D0002-503E-4C75-BA94-3148F18D941E")
let g_tokenWriteCharacteristicUUID = CBUUID(string:"713D0003-503E-4C75-BA94-3148F18D941E")


extension NSData {
  
  /// Create hexadecimal string representation of NSData object.
  ///
  /// - returns: NSString representation of this NSData object.
  
  func hexString() -> NSString {
    let str = NSMutableString()
    let bytes = UnsafeBufferPointer<UInt8>(start: UnsafePointer(self.bytes), count:self.length)
    for byte in bytes {
      str.appendFormat("%02hhx.", byte)
    }
    return str
  }
}




protocol BleStateChangeDelegate {
  func onBleStatusError(message: String)
  func onConnected()
  func onDisconnect()
}



class Token: BleStateChangeDelegate {
  enum ConnectedState : UInt8 {
    case Connected = 0,
    Disconnected
  }
  
  typealias ResponseHandler = (Response, error: NSError?) -> (Void);
  typealias CreatePasswordHandler = (cipheredPassword:[UInt8], error: NSError?) -> (Void);
  typealias PairWithDeviceHandler = (NSError?) -> (Void);
  typealias AuthCmdHandler = (nonce: [UInt8], error: NSError?) -> (Void);
  typealias StateUpdateHandler = (state :ConnectedState, message: String?) -> (Void);
  
  var tokenDelegate :TokenPeripheralDelegate!
  var bleManager :BleManager!
  var isConnected = false;
  var passKey = [UInt8](count: 16, repeatedValue: 0)
  var crKey = [UInt8](count: 16, repeatedValue: 0)
  var reqKey = [UInt8](count: 16, repeatedValue: 0)
  
  var connectedHandler :StateUpdateHandler!
  var stateUpdateHandler :StateUpdateHandler!;
  var ErrorHandler :StateUpdateHandler!
  
  
  init(handler: StateUpdateHandler, connected: StateUpdateHandler) {
    stateUpdateHandler = handler;
    connectedHandler = connected;
    //bleManager = BleManager(stateChange: self);
    //tokenDelegate = TokenPeripheralDelegate(stateChange: self);
    //bleManager.tokenPeripheralDelegate = tokenDelegate;
  }

  
  
  func onConnected() {
    print("State: Connected to Token");
    isConnected = true;
    connectedHandler!(state: .Connected, message: nil);
  }
  
  
  func onDisconnect() {
    isConnected = false;
    stateUpdateHandler!(state: .Disconnected, message: nil);
  }
  

  func onBleStatusError(message: String) {
    print(message);
    isConnected = false;
    stateUpdateHandler!(state: .Disconnected, message: message);
  }
  

  
  func CreatePassword(length: UInt8, handler: CreatePasswordHandler) {
    if length > 63 {
      let error = NSError(domain: "Invalid password size", code: 1, userInfo: nil)
      handler(cipheredPassword: [UInt8](), error: error)
      return;
    }
    
    
    let arg:[UInt8] = [length];
    let cmd = Command(cmdId: Command.Id.CreatePassword, arg: arg)!
    
    send(cmd) { (response, error) in
      if let _ = error {
        let cipherPassword = [UInt8]()
        handler(cipheredPassword: cipherPassword, error: error)
      }
      
      let cipheredPassword = Array(response.bytes[2...79]);
      handler(cipheredPassword: cipheredPassword, error: error);
    }
  }
  
  
  
  func PairWithDevice(handler: PairWithDeviceHandler) {
    let cmd = Command(cmdId: Command.Id.Pair, arg: [UInt8]())!;

    self.send(cmd) { (response, error) -> (Void) in
      if let _ = error {
        handler(error);
        return;
      }
      
      if response.isValid() {  // Token is Paired
        self.passKey = Array(response.bytes[2...17]);
        self.crKey = Array(response.bytes[18...33]);
        self.reqKey = Array(response.bytes[34...49]);
        
        print("Pass Key: \(self.passKey)");
        print("Cr   Key: \(self.crKey)");
        print("Req  Key: \(self.reqKey)");
        handler(nil);
        return;
      }
      
      handler(NSError(domain: "Invalid Response", code: 1, userInfo: nil))
    }
    
  }
  
  
  func send(cmd: Command, handler: ResponseHandler) {
    if let needAuth = cmd.needAuth() {
      if (needAuth) {
        doSendCmdAuth(cmd, handler: handler);
      } else {
        doSend(cmd, handler: handler);
      }
    }
  }
  
  
  private func prepareAuthCmd(handler: AuthCmdHandler) {
    let cmd = Command(cmdId: Command.Id.CreateChallenge, arg: [UInt8]())!;
    
    self.doSend(cmd) { (response, error) in
      if let _ = error {
        handler(nonce: [UInt8](), error: error);
        return;
      }
      
      let nonce = Array(response.bytes[2...9]);
      print("Challenge: \(nonce)");
      
      handler(nonce: nonce, error: error);
    }
  }
  
  
  private func doSendCmdAuth(cmd: Command, handler: ResponseHandler) {
    prepareAuthCmd { (nonce, error) in
      if let _ = error {
        handler(Response(), error: error);
        return;
      }
      
      cmd.setSecurityToken(nonce, key: self.crKey);
      
      self.doSend(cmd, handler: handler);
    }
  }
  
  
  
  private func doSend(cmd: Command, handler: ResponseHandler) {
    let data = NSMutableData(bytes: cmd.bytes, length: cmd.bytes.count)
    tokenDelegate.asyncWriteData(data, handler: handler);
  }
  
  
  
  
  func TestWrite() {
    let cmd = Command(cmdId: Command.Id.Pair, arg: [UInt8]())!;
    
    send(cmd) { [weak self] (response, error)  in
      if let err = error {
        print("Error processing command: \(err.description)");
        return;
      }
      print("Response: \(response.bytes)");
      
      if response.isValid() {  // Token is Paired
        print("Bytes count: \(response.bytes.count)");
        self!.passKey = Array(response.bytes[2...17]);
        self!.crKey = Array(response.bytes[18...33]);
        self!.reqKey = Array(response.bytes[34...49]);
        
        
        print("Pass Key: \(self!.passKey)");
        print("Cr   Key: \(self!.crKey)");
        print("Req  Key: \(self!.reqKey)");
      }
      
      let arg:[UInt8] = [10];
      let cmd = Command(cmdId: Command.Id.CreatePassword, arg: arg)!;
      
      
      self!.send(cmd) { (response, error) in
        if let err = error {
          print("Error processing command: \(err.description)");
          return;
        }
        print("Response: \(response.bytes)");
        
        let cipheredPassword = Array(response.bytes[2...79]);
        
        
        let cmd = Command(cmdId: Command.Id.TypePassword, arg: cipheredPassword)!;
        
        
        self!.send(cmd){ (response, error) in
          print("Reponse type password: \(response.bytes)")
        }
      }
    }
  }
}



//----------------------------------------------------------------------------------------
class TokenPeripheralDelegate: NSObject, CBPeripheralDelegate {
  typealias ResponseHandler = (Response, error: NSError?) -> (Void);
  private var handler: ResponseHandler?
  
  private class ReadCtx {
    var bytesRead = 0
    var missingBytes = 0
    var needAck = false;
  }
  
  private class WriteCtx {
    var bytesSent = 0;
    var isAckCond = NSCondition();
    var isWaitingAck = false;
    var isAck = false;
  }
  
  private var tokenPeripheral:CBPeripheral!
  private var tokenReadCharacteristic:CBCharacteristic!
  private var tokenWriteCharacteristic:CBCharacteristic!
  private var stateChange: BleStateChangeDelegate!
  private var dispatchQueue: dispatch_queue_t;
  
  
  private var currentResponse = Response()
  private var bleReady = false;
  
  let kMaxBurst = 15;
  private var rCtx: ReadCtx;
  private var wCtx: WriteCtx;
  
  init(stateChange: BleStateChangeDelegate) {
    rCtx = ReadCtx();
    wCtx = WriteCtx();
    dispatchQueue = dispatch_queue_create("MY Queue", nil);
    
    super.init();
    self.stateChange = stateChange;
  }
  
  
  func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
    if let err = error {
      stateChange.onBleStatusError(err.description)
      return
    }
    
    // @todo Check if periperal is real token peripheral
    tokenPeripheral = peripheral;
    
    for service in peripheral.services! {
      print("Discovered service UUID: \(service.UUID)")
      peripheral.discoverCharacteristics(nil, forService: service)
    }
  }
  
  
  func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
    if error != nil {
      print("Error characteristics for service")
      return
    }
    for characteristic in service.characteristics! {
      switch characteristic.UUID {
      case g_tokenReadCharacteristicUUID:
        print("Found Read characteristic")
        tokenReadCharacteristic = characteristic
        tokenPeripheral.setNotifyValue(true, forCharacteristic: characteristic);
      case g_tokenWriteCharacteristicUUID:
        print("Found Write characteristic")
        tokenWriteCharacteristic = characteristic
      default:
        continue
      }
    }
    
    if (tokenReadCharacteristic != nil && tokenWriteCharacteristic != nil && !bleReady) {
      bleReady = true;
      stateChange.onConnected();
    }
  }
  
  
  func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
    if (peripheral == tokenPeripheral && characteristic == tokenReadCharacteristic) {
      if let value = characteristic.value  {
        onReceivedData(value, error: error);
      }
    }
  }
  
  
  func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
    if (peripheral == tokenPeripheral && characteristic == tokenWriteCharacteristic) {
      onWriteData(error)
    }
  }
  
  
  func asyncWriteData(data: NSData, handler: ResponseHandler) {
    // Init context
    self.handler = handler;
    currentResponse = Response();
    rCtx = ReadCtx();
    wCtx = WriteCtx();
    
    dispatch_async(dispatchQueue, { [weak self] in
      self!.doWriteData(data);
      });
  }
  
  
  private func onReceivedData(data: NSData, error: NSError?) {
    if let err = error {
      //  Re-initialize context
      rCtx = ReadCtx();
      wCtx = WriteCtx();
      currentResponse = Response();
      handler!(Response(), error: err);
      return;
    }
    
    print("Successful Read:");
    print(data.hexString());
    // Successful read
    
    if data.length == 1 && wCtx.isWaitingAck { // Wait for ack
      wCtx.isAck = true;
      wCtx.isAckCond.signal();
      return;
    }
    
    
    rCtx.bytesRead += data.length;
    currentResponse.appendBytes(data);
    
    if (rCtx.bytesRead == kMaxBurst) {
      let ack :UInt8 = (UInt8)(rCtx.bytesRead);
      rCtx.bytesRead = 0;
      let ackNSData = NSData(bytes: [ack], length: 1)
      writeDataToBle(ackNSData, type: .WithoutResponse);
    }
    
    if (currentResponse.isComplete()) {
      rCtx = ReadCtx();
      wCtx = WriteCtx();
      let responseCopy = currentResponse;
      currentResponse = Response();
      handler!(responseCopy, error: nil);
    }
    
  }
  
  
  func onWriteData(error: NSError?) {
    if let err = error {
      print("Error while writing to the token: \(err.description)");
      return;
    }
    print("data wrote!");
  }
  
  
  private func waitAck() -> Bool {
    let maxCycles = 5;
    var cycles = 0;
    wCtx.isAckCond.lock();
    wCtx.isWaitingAck = true;
    
    while !wCtx.isAck && cycles < maxCycles {
      wCtx.isAckCond.waitUntilDate(NSDate(timeIntervalSinceNow: NSTimeInterval(1)));
      ++cycles
    }
    wCtx.isAckCond.unlock();
    wCtx.isWaitingAck = false;
    return wCtx.isAck;
  }
  
  
  
  private func doWriteData(data :NSData) {
    var size = data.length;
    var session_bytes_sent = 0;
    
    while size > 0 {
      let bytes_to_write = min(size, kMaxBurst - wCtx.bytesSent);
      let rangeToSend = NSRange(location: session_bytes_sent, length: bytes_to_write)
      let bytesToSend = data.subdataWithRange(rangeToSend)
      print("sending \(bytesToSend.hexString())")
      writeDataToBle(bytesToSend);
      
      size -= bytes_to_write;
      wCtx.bytesSent += bytes_to_write;
      session_bytes_sent += bytes_to_write;
      
      if (wCtx.bytesSent == kMaxBurst) {
        if waitAck() {
          wCtx.bytesSent = 0;
          wCtx.isAck = false;
        } else {
          print("No ack for write");
          break;
        }
      }
      
    }
  }
  
  
  func writeDataToBle(data: NSData, type: CBCharacteristicWriteType = .WithoutResponse) {
    tokenPeripheral.writeValue(data, forCharacteristic: tokenWriteCharacteristic, type: type);
  }
  
}



//----------------------------------------------------------------------------------------
class BleManager: NSObject, CBCentralManagerDelegate {
  var centralManager :CBCentralManager!
  var tokenPeripheral :CBPeripheral!
  var tokenServiceCBUUID :CBUUID!
  var tokenPeripheralDelegate :TokenPeripheralDelegate!
  var stateChange: BleStateChangeDelegate!
  
  var managerInitialized = false;
  var managerActive = false;
  
  init(stateChange: BleStateChangeDelegate) {
    super.init();
    self.stateChange = stateChange;
    tokenServiceCBUUID = g_tokenServiceCBUUID;
    startupCentralManager();
    managerActive = false;
  }
  
  func startupCentralManager() {
    print("initializing central manager");
    centralManager = CBCentralManager(delegate:self, queue:nil)
  }
  
  func centralManagerDidUpdateState(central: CBCentralManager) {
    print("central manager updated state");
    
    switch (central.state) {
    case .PoweredOff:
      stateChange.onBleStatusError("CoreBluetooth BLE hardware is powered off")
      
    case .Resetting:
      stateChange.onBleStatusError("CoreBluetooth BLE hardware is resetting")
      
    case .Unauthorized:
      stateChange.onBleStatusError("CoreBluetooth BLE state is unauthorized")
      
    case .Unknown:
      stateChange.onBleStatusError("CoreBluetooth BLE state is unknown");
      
    case .Unsupported:
      stateChange.onBleStatusError("CoreBluetooth BLE hardware is unsupported on this platform");
      
    case .PoweredOn:
      managerInitialized = true;
    }
    
    if managerInitialized {
      centralManager.scanForPeripheralsWithServices([tokenServiceCBUUID], options: nil)
    }
  }
  
  func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
    print("Discovered \(peripheral.name), RSSI: \(RSSI)")
    centralManager.stopScan();
    tokenPeripheral = peripheral;
    tokenPeripheral.delegate = tokenPeripheralDelegate;
    
    centralManager.connectPeripheral(tokenPeripheral, options: nil)
  }
  
  
  
  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
    print("Connected to \(peripheral.name)")
    tokenPeripheral!.discoverServices(nil)
  }
  
}


