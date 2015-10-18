//
//  Token.swift
//  Trustline
//
//  Created by matt on 10/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation
import CoreBluetooth

class Token2 {
  // MARK - Type definitions
  typealias CompletionHandler = (error: NSError?) -> (Void);
  typealias DataCompletionHandler = (data: [UInt8], error: NSError?) -> (Void);
  
  // MARK - Variable on init
  var centralManager :CBCentralManager
  var tokenPeriperal :CBPeripheral
  var tokenPeriperalProtocolImpl :TokenPeripheralProtocolImpl
  var tokenCommander :TokenCommander
  var keyMaterial :KeyMaterial
  
  // MARK - member varibales
  var isConnected = false
  var connectHandler :CompletionHandler?
  var connectionStateHandler: BleManager2.ManagerStateErrorHandler
  
  
  
  
  
  init(centralManager :CBCentralManager, peripheral: CBPeripheral, keyMaterial :KeyMaterial?, connectionStateHandler: BleManager2.ManagerStateErrorHandler) {
    self.centralManager = centralManager
    self.tokenPeriperal = peripheral
    self.tokenPeriperalProtocolImpl = TokenPeripheralProtocolImpl()
    self.tokenPeriperal.delegate = self.tokenPeriperalProtocolImpl
    self.connectionStateHandler = connectionStateHandler
    
    if let material = keyMaterial {
      self.keyMaterial = material
    } else {
      self.keyMaterial = KeyMaterial()
    }
    
    self.tokenCommander = TokenCommander(keyMaterial: self.keyMaterial, protocolImpl: tokenPeriperalProtocolImpl)
  }
  
  func connect(hanlder: CompletionHandler) {
    self.tokenPeriperalProtocolImpl.connectionHandler = self.connectHandlerHook
    self.connectHandler = hanlder;
    self.centralManager.connectPeripheral(tokenPeriperal, options: nil);
  }
  
  func pair(handler: CompletionHandler) {
    tokenCommander.PairWithDevice(handler)
  }
  
  func createPassword(strength: UInt8, handler: DataCompletionHandler) {
    tokenCommander.CreatePassword(strength, handler: handler)
  }
  
  func writePassword(password: [UInt8], additionalKeys: [UInt8]? = nil, handler: CompletionHandler) {
    tokenCommander.keystrokesPassword(password, additionalKeys: additionalKeys, handler: handler)
  }
  
  
  func connectHandlerHook(error: NSError?) {
    if let _ = error {
      isConnected = false;
    } else {
      isConnected = true;
    }
    
    // in case of connect, call user handler
    if let _ = connectHandler {
      connectHandler!(error: error)
    }
    
    connectionStateHandler(error)
  }
  
  
  
}


class TokenCommander {
  // MARK - Type definitions
  typealias ResponseHandler = (Response, error: NSError?) -> (Void);
  typealias CreatePasswordHandler = (cipheredPassword:[UInt8], error: NSError?) -> (Void);
  typealias PairWithDeviceHandler = (NSError?) -> (Void);
  typealias CompletionHandler = (NSError?) -> (Void)
  typealias AuthCmdHandler = (nonce: [UInt8], error: NSError?) -> (Void);
  
  
  var passKey = [UInt8]()
  var keyMaterial :KeyMaterial
  var protocolImpl :TokenPeripheralProtocolImpl
  
  init(keyMaterial :KeyMaterial, protocolImpl :TokenPeripheralProtocolImpl) {
    self.keyMaterial = keyMaterial;
    self.protocolImpl = protocolImpl;
  }
  
  
  
  func PairWithDevice(handler: PairWithDeviceHandler) {
    let cmd = Command(cmdId: Command.Id.Pair, arg: [UInt8]())!;
    
    self.send(cmd) { (response, error) -> (Void) in
      if let _ = error {
        handler(error);
        return;
      }
      
      if response.isValid() {  // Token is Paired
//        self.passKey = Array(response.bytes[2...17]);
        self.keyMaterial.passKey = Array(response.bytes[2...17])
        self.keyMaterial.crKey = Array(response.bytes[18...33])
        self.keyMaterial.reqKey = Array(response.bytes[34...49])
        
        print("Pass Key: \(self.keyMaterial.passKey)");
        print("Cr   Key: \(self.keyMaterial.crKey)");
        print("Req  Key: \(self.keyMaterial.reqKey)");
        handler(nil);
        return;
      }
      
      handler(NSError(domain: "Invalid Response", code: 1, userInfo: nil))
    }
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
        return
      }
      let cipheredPassword = response.argData()!
      handler(cipheredPassword: cipheredPassword, error: error);
    }
  }

  
  func keystrokesPassword(password: [UInt8], additionalKeys: [UInt8]? = nil, handler: CompletionHandler) {
    var cmd :Command!
    
    if let addKeys = additionalKeys {
      var arg = password;
      arg.appendContentsOf(addKeys)
      cmd = Command(cmdId: .TypePassword, arg: arg)!
    } else {
      cmd = Command(cmdId: .TypePassword, arg: password)!
    }

    send(cmd) { (reponse, error) in
      if let _ = error {
        handler(error)
      } else {
        handler(nil)
      }
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
      
      cmd.setSecurityToken(nonce, key: self.keyMaterial.crKey!);
      
      self.doSend(cmd, handler: handler);
    }
  }
  
  
  
  private func doSend(cmd: Command, handler: ResponseHandler) {
    let data = NSMutableData(bytes: cmd.bytes, length: cmd.bytes.count)
    protocolImpl.asyncWriteData(data, handler: handler);
  }
  
}



class TokenPeripheralProtocolImpl : NSObject, CBPeripheralDelegate {
  typealias ResponseHandler = (Response, error: NSError?) -> (Void);
  typealias ConnectionHandler = BleManager2.ManagerStateErrorHandler
  
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
  
  private var connectionHandler :ConnectionHandler!
  
  private var tokenPeripheral:CBPeripheral!
  private var tokenReadCharacteristic:CBCharacteristic!
  private var tokenWriteCharacteristic:CBCharacteristic!
  private var dispatchQueue: dispatch_queue_t;
  
  
  private var currentResponse = Response()
  private var bleReady = false;
  
  let kMaxBurst = 15;
  private var rCtx: ReadCtx;
  private var wCtx: WriteCtx;
  
  override init() {
    rCtx = ReadCtx();
    wCtx = WriteCtx();
    dispatchQueue = dispatch_queue_create("MY Queue", nil);
    
    super.init();
  }
  
  
  func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
    if let _ = error {
      connectionHandler(error)
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
      connectionHandler(nil);
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
    
    //print("Successful Read:");
    //print(data.hexString());
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
      //print("sending \(bytesToSend.hexString())")
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
          handler!(Response(), error: createError("Error during communication"))
          break;
        }
      }
      
    }
  }
  

  func writeDataToBle(data: NSData, type: CBCharacteristicWriteType = .WithoutResponse) {
    tokenPeripheral.writeValue(data, forCharacteristic: tokenWriteCharacteristic, type: type);
  }
  
}