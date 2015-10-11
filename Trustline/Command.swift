//
//  Command.swift
//  Trustline
//
//  Created by matt on 04/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation
import CryptoSwift

class Command {
  let sizeOfHeader = 2;
  let sizeOfSecurityToken = 32;
  let MaxArgCount = 100;
  
  var bytes = [UInt8](count: 34, repeatedValue: 0);
  
  
  enum Id : UInt8 {
    case Pair = 0,
    CreateChallenge,
    CreatePassword,
    TypePassword,
    ReturnPassword,
    Reset,
    TestEcho,
    TestPassword,
    TestKey,
    TestPasswordCrypto,
    TestIsInitialized,
    TestIsAuthorized,
    TestChallenge,
    NbCmd
  }
  
  init?(cmdId: Id, arg: [UInt8] = []) {
    if !setId(cmdId) {
      return nil;
    }
    
    if !setArg(arg) {
      return nil;
    }
  }
  
  
  func setId(cmdId: Id) -> Bool {
    if (cmdId.rawValue >= Id.NbCmd.rawValue) {
      return false;
    }
    bytes[32] = cmdId.rawValue;
    return true;
  }
  
  
  
  func setArg(arg: [UInt8]) -> Bool {
    if arg.count > MaxArgCount {
      return false;
    }
    
    bytes[33] = (UInt8)(arg.count);
    
    if arg.count == 0 {
      return true;
    }
    
    for i in 0...arg.count - 1 {
      bytes.append(arg[i]);
    }
    
    return true;
  }
  
  
  func needAuth() -> Bool? {
    if bytes.count < 31 {
      return nil;
    }
    
    if let id = Id(rawValue: bytes[32]) {
      switch id {
      case .CreatePassword, .TypePassword, .ReturnPassword:
        return true;
      default:
        return false;
      }
    } else {
      return nil;
    }
  }
  
  
  func setSecurityToken(nonce: [UInt8], key: [UInt8]) {
    var message_to_authenticate = nonce;
    message_to_authenticate.appendContentsOf(bytes[32...bytes.count - 1]);
    
    print("Message to authenticate: \(message_to_authenticate)");
    
    var security_token = Authenticator.HMAC(key: key, variant: .sha256).authenticate(message_to_authenticate);
    
    print("SecurityToken \(security_token)");
    
    for i in 0...31 {
      bytes[i] = security_token![i];
    }
  }
  
}



class Response {
  var bytes = [UInt8]();
  
  let sizeOfHeader = 2;
  let sizeOfSecurityToken = 32;
  
  
  enum Status: UInt8 {
    case Ok = 0,
    PairWithDeviceFirst,
    DeviceAlreadyPaired,
    BadAuth,
    InvalidCmd,
    InvalidPassword,
    Message,
    InvalidArgument,
    InvalidResponse
  }
  
  
  func isComplete() -> Bool {
    if bytes.isEmpty {
      return false;
    }
    if (bytes.count > 1) {
      print("hdr.size: \(bytes[1])   bytes.count - 2: \(bytes.count - 2)")
      return bytes[1] == (UInt8)(bytes.count - 2);
    } else {
      return false;
    }
  }
  
  
  func status() -> Status {
    if !isComplete() {
      return Status.InvalidResponse;
    }
    
    let statusRawValue = bytes[0];
    
    if (statusRawValue > Status.InvalidResponse.rawValue) {
      return Status.InvalidResponse;
    }
    
    return Status(rawValue: statusRawValue)!;
  }
  
  
  func isValid() -> Bool {
    return status() == Status.Ok;
  }
  
  func argSize() -> UInt8 {
    if !isComplete() {
      return 0;
    }
    
    return UInt8(bytes[1]);
  }
  
  
  func securityToken() -> [UInt8]? {
    let securityTokenStartIndex = sizeOfHeader;
    let securityTokenEndIndex = securityTokenStartIndex + sizeOfSecurityToken - 1;
    
    if bytes.count < (sizeOfHeader + sizeOfSecurityToken) {
      return nil;
    }
    
    return Array(bytes[securityTokenStartIndex...securityTokenEndIndex]);
  }
  
  
  func argData() -> [UInt8]? {
    let dataStartIndex = sizeOfHeader + sizeOfSecurityToken;
    let dataEndIndex = dataStartIndex + (Int)(argSize()) - 1;
    
    if !isComplete() {
      return nil;
    }
    
    if bytes.count < dataEndIndex + 1 {
      return nil;
    }
    
    return Array(bytes[dataStartIndex...dataEndIndex]);
  }
  
  
  func appendBytes(data: NSData) -> Bool {
    let p_data = UnsafePointer<UInt8>(data.bytes);
    let buffer = UnsafeBufferPointer<UInt8>(start:p_data, count: data.length);
    
    bytes.appendContentsOf(buffer);
    
    return isComplete();
  }
}