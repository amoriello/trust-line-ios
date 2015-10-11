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
  
  
  class func getAccountInfo() -> AccountInfos {
    let accountInfos = AccountInfos();
    
    let CreateFakeAccount = {(title: String) -> Account in
      let fakePassData = [UInt8]();
      let fakeLogin = "amoriello.hutti@gmail.com"
      
      let q1 = "First pet's name?"
      let q2 = "Preferred movie's name?"
      
      let a1 = [UInt8]()
      let a2 = [UInt8]()
      
      let QAs = [SecurityQA(question: q1, answer: a1),
                 SecurityQA(question: q2, answer: a2)]
      
      return Account(title: title, login: fakeLogin, password: fakePassData, securityQA: QAs)
    }
    
    accountInfos.add(CreateFakeAccount("Abricot"))
    accountInfos.add(CreateFakeAccount("Absinthe"))
    accountInfos.add(CreateFakeAccount("Acajou"))
    accountInfos.add(CreateFakeAccount("Acide"))
    accountInfos.add(CreateFakeAccount("acidulé"))
    accountInfos.add(CreateFakeAccount("acier"))
    
    accountInfos.add(CreateFakeAccount("délavé"))
    accountInfos.add(CreateFakeAccount("diapré"))
    accountInfos.add(CreateFakeAccount("doux"))

    
    accountInfos.add(CreateFakeAccount("nacarat"))
    accountInfos.add(CreateFakeAccount("Naples"))
    accountInfos.add(CreateFakeAccount("noir"))
    
    return accountInfos
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
  var login: String
  var password: [UInt8]  // Password is encrypted using token
  var securityQA: [SecurityQA]?

  init (title: String, login: String, password: [UInt8]) {
    self.title = title
    self.login = login
    self.password = password;
  }
  
  init(title: String, login: String, password: [UInt8], securityQA: [SecurityQA]) {
    self.title = title
    self.login = login
    self.password = password;
    self.securityQA = securityQA;
  }
  
}
