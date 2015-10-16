//
//  Password.swift
//  Trustline
//
//  Created by matt on 05/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation


class AccountInfos {
  // First title letter (Uppercase): Account Array
  typealias AccountDict = [String: [Account]]
  var accountDict = AccountDict();
  
  init() {
    createFakeInfo()
  }
  
  
  func createFakeInfo() {
    let CreateFakeAccount = {(title: String) -> Account in
      let fakePassData = [UInt8]();
      let fakeLogin = "amoriello.hutti@gmail.com"
      
      let q1 = "First pet's name?"
      let q2 = "Preferred movie's name?"
      
      let a1 = [UInt8]()
      let a2 = [UInt8]()
      
      let QAs = [SecurityQA(question: q1, answer: a1),
                 SecurityQA(question: q2, answer: a2)]
      
      let account = Account(title: title, password: fakePassData, login: fakeLogin, securityQA: QAs)
      account.usageInfos = [UsageInfo(usageType: .Keyboard)]
      
      return account
    }
    
    add(CreateFakeAccount("Abricot"))
    add(CreateFakeAccount("Absinthe"))
    add(CreateFakeAccount("Acajou"))
    add(CreateFakeAccount("Acide"))
    add(CreateFakeAccount("acidulé"))
    add(CreateFakeAccount("acier"))
    
    add(CreateFakeAccount("délavé"))
    add(CreateFakeAccount("diapré"))
    add(CreateFakeAccount("doux"))

    
    add(CreateFakeAccount("nacarat"))
    add(CreateFakeAccount("Naples"))
    add(CreateFakeAccount("noir"))
  }
    
  
  func add(account: Account) {
    let keyCharacter = String(account.title[account.title.startIndex]).uppercaseString
    if let _ = accountDict[keyCharacter] {
      accountDict[keyCharacter]?.append(account);
    } else {
      accountDict[keyCharacter] = [account];
    }
  }
}


class UsageInfo {
  enum UsageType {
    case Keyboard, Clipboard
  }
  
  var usageType :UsageType
  var date   :NSDate
  
  init(usageType: UsageType) {
    self.usageType = usageType
    self.date = NSDate()
  }
}


class AccountUsageHistory {
  
}


class SecurityQA {
  var question: String
  var answer: [UInt8]  // Answer is encrypted using token
  
  init(question: String, answer: [UInt8]) {
    self.question = question
    self.answer = answer;
  }
}


class Account {
  var title: String
  var password: [UInt8]  // Password is encrypted using token
  var login: String?
  var securityQA: [SecurityQA]?
  var usageInfos: [UsageInfo] = []

  init (title: String, password: [UInt8], login: String?) {
    self.title = title
    self.login = login
    self.password = password;
  }
  
  init(title: String, password: [UInt8], login: String?, securityQA: [SecurityQA]) {
    self.title = title
    self.login = login
    self.password = password;
    self.securityQA = securityQA;
  }
  
  func updateUsageInfo(usageType: UsageInfo.UsageType) {
    usageInfos.append(UsageInfo(usageType: usageType))
  }
  
}
