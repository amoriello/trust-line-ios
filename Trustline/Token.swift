//
//  Token.swift
//  Trustline
//
//  Created by matt on 10/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation
import CoreBluetooth
import CryptoSwift
import CoreData


private let kHexChars = Array("0123456789abcdef".utf8) as [UInt8];

extension NSData {
  
  public func hexString() -> String {
    guard length > 0 else {
      return ""
    }
    
    let buffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer(bytes), count: length)
    var output = [UInt8](count: length*2 + 1, repeatedValue: 0)
    var i: Int = 0
    for b in buffer {
      let h = Int((b & 0xf0) >> 4)
      let l = Int(b & 0x0f)
      output[i++] = kHexChars[h]
      output[i++] = kHexChars[l]
    }
    
    return String.fromCString(UnsafePointer(output))!
  }
}





class Token2 {
  // MARK - Type definitions
  typealias CompletionHandler = (error: NSError?) -> (Void)
  typealias DataCompletionHandler = (data: [UInt8], error: NSError?) -> (Void)
  typealias RetrievePasswordHandler = (clearPassword: String, error: NSError?) -> (Void)
  typealias DecryptAccountHandler = (account: CDAccount?, error: NSError?) -> (Void)
  
  // MARK - Variable on init
  var centralManager :CBCentralManager
  var tokenPeriperal :CBPeripheral
  var tokenPeriperalProtocolImpl = TokenPeripheralProtocolImpl()
  var identifier :NSUUID
  var tokenCommander :TokenCommander!
  var keyMaterial : CDKeyMaterial!
  
  let managedObjectCtx = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
  
  
  // MARK - member varibales
  var isConnected = false
  var connectHandler :CompletionHandler?
  var connectionStateHandler: BleManager2.ManagerStateErrorHandler
  
  
  
  init(centralManager :CBCentralManager, peripheral: CBPeripheral, keyMaterial :CDKeyMaterial, identifier: NSUUID, connectionStateHandler: BleManager2.ManagerStateErrorHandler) {
    self.centralManager = centralManager
    self.tokenPeriperal = peripheral
    self.tokenPeriperal.delegate = self.tokenPeriperalProtocolImpl
    self.connectionStateHandler = connectionStateHandler
    self.identifier = identifier
    self.keyMaterial = keyMaterial
    
    self.tokenCommander = TokenCommander(keyMaterial: self.keyMaterial, protocolImpl: tokenPeriperalProtocolImpl)
  }
  
  
  func createKeyMaterial() -> CDKeyMaterial {
    let kmEntity = NSEntityDescription.entityForName("CDKeyMaterial", inManagedObjectContext: managedObjectCtx)!
    let keyMaterial = NSManagedObject(entity: kmEntity, insertIntoManagedObjectContext: managedObjectCtx) as! CDKeyMaterial
    
    return keyMaterial
  }
  
  func setKeyMaterial(keyMaterial: CDKeyMaterial) {
    self.keyMaterial = keyMaterial
    // reset commander with new material
    self.tokenCommander = TokenCommander(keyMaterial: self.keyMaterial!, protocolImpl: tokenPeriperalProtocolImpl)
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
  
  func resetNewKeys(keyMaterialFromQrCode keyMaterial: CDKeyMaterial, handler: CompletionHandler) {
    tokenCommander.resetNewKeys(keyMaterial, handler: handler)
  }
  
  
  func retrievePassword(password: [UInt8], handler: RetrievePasswordHandler) {
    tokenCommander.retrievePassword(password, handler: handler)
  }
  
  
  func decryptAccount(encryptedAccount: CDAccount, handler: DecryptAccountHandler) {
    // not implemented yet
    return handler(account: nil, error: createError("Error", description: "Not implemented yet"))
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
  typealias RetrievePasswordHandler = (clearPassword: String, error: NSError?) -> (Void);
  typealias PairWithDeviceHandler = (NSError?) -> (Void);
  typealias CompletionHandler = (NSError?) -> (Void)
  typealias AuthCmdHandler = (nonce: [UInt8], error: NSError?) -> (Void);
  
  
  var passKey = [UInt8]()
  var keyMaterial :CDKeyMaterial
  var protocolImpl :TokenPeripheralProtocolImpl
  
  init(keyMaterial :CDKeyMaterial, protocolImpl :TokenPeripheralProtocolImpl) {
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
        let keySize = self.keyMaterial.keySize;
        
        let passKey = Array(response.bytes[2...1 + keySize])
        let crKey   = Array(response.bytes[2 + keySize...1 + (2 * keySize)])
        let comKey  = Array(response.bytes[2 + (2 * keySize)...1 + (3 * keySize)])
        
        self.keyMaterial.creation = NSDate()
        self.keyMaterial.passKey = NSData(bytes: passKey, length: passKey.count)
        self.keyMaterial.crKey = NSData(bytes: crKey, length: crKey.count)
        self.keyMaterial.comKey = NSData(bytes: comKey, length: comKey.count)
        
        print("Pass Key: \(self.keyMaterial.passKey)");
        print("Cr   Key: \(self.keyMaterial.crKey)");
        print("Req  Key: \(self.keyMaterial.comKey)");
        handler(nil);
        return;
      }

      handler(createError("Pairing Failed", description: "Invalid Response", status: response.status()))
    }
  }
  
  
  func CreatePassword(length: UInt8, handler: CreatePasswordHandler) {
    if length > 63 {
      let error = createError("Create Password Failed", description: "Invalid password size", status: Response.Status.InvalidArgument)
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
      handler(error)
    }
  }

  
  func retrievePassword(password: [UInt8], handler: RetrievePasswordHandler) {
    let cmd = Command(cmdId: .ReturnPassword, arg: password)!
    
    send(cmd) { (response, error) in
      if error != nil {
        handler(clearPassword: "", error: error)
        return
      }
      
      let argDataSize = response.argData()!.count
      
      if argDataSize != 80 {
        let error = createError("Invalid response", description: "Bad response length")
        handler(clearPassword: "", error: error)
        return
      }

      let iv = Array(response.argData()![0...self.keyMaterial.keySize - 1])
      let cipheredPassword = Array(response.argData()![16...argDataSize - 1])
      
      do {
        let clearData :[UInt8] = try AES(key: self.keyMaterial.comKey.arrayOfBytes(), iv: iv)!.decrypt(cipheredPassword)
        let clearPassword = String(bytes: clearData, encoding: NSUTF8StringEncoding)!
        handler(clearPassword: clearPassword, error: nil)
        return
      } catch {
        let error = createError("Invalid response", description: "Bad cryptographic input")
        handler(clearPassword: "", error: error)
      }
    }
  }
  
  
  func resetNewKeys(keyMaterial: CDKeyMaterial, handler: CompletionHandler) {
    let cmd = Command(cmdId: .ResetKeys, arg: keyMaterial.data())!
    
    send(cmd) { (response, error) in
      handler(error)
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
      
      cmd.setSecurityToken(nonce, key: self.keyMaterial.crKey.arrayOfBytes());
      
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
    dispatchQueue = dispatch_queue_create("BleQueue", nil);
    
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
      async { self.handler!(Response(), error: err); }
      return;
    }
    
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
      
      if responseCopy.isValid() {
        async { self.handler!(responseCopy, error: nil) }
      } else {
        let error = createError("Command Error", description: "Todo: Description here code \(responseCopy.status().rawValue)")
        async { self.handler!(Response(), error: error) }
      }
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
          async { self.handler!(Response(), error: createError("Protocol", description: "Error during communication")) }
          break;
        }
      }
      
    }
  }
  

  func writeDataToBle(data: NSData, type: CBCharacteristicWriteType = .WithoutResponse) {
    tokenPeripheral.writeValue(data, forCharacteristic: tokenWriteCharacteristic, type: type);
  }
  
  private func async(handler: () -> (Void)) {
    dispatch_async(dispatch_get_main_queue(), handler)
  }
  
}