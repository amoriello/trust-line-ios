//
//  AccountDict.swift
//  Trustline
//
//  Created by matt on 11/11/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation
import CoreData

class AccountManager {
  typealias AccountDict = [String: [CDAccount]]
  typealias ActionHandler = (NSError?) -> Void
  
  var accounts = AccountDict()
  let managedCtx: NSManagedObjectContext!
  let profile: CDProfile!
  
  init(profile: CDProfile, managedCtx: NSManagedObjectContext) {
    self.managedCtx = managedCtx
    self.profile = profile
    initializeDict(profile.accounts)
  }
  
  
  func hasEncryptedAccounts() -> Int {
    return encryptedAccounts.count
  }
  
  
  func decryptAccounts(token: Token, handler: ActionHandler) {
    handler(createError("No implemented Yet", description: "But it will be for sure."))
  }
  
  
  func createAccount(title: String, login: String, password: [UInt8]) -> CDAccount {
    let newAccount: CDAccount = createCDObject(managedCtx)
    let newLogin: CDLogin = createCDObject(managedCtx)
    
    newAccount.creation = NSDate()
    newAccount.profile = profile
    newAccount.title = title
    newAccount.login = newLogin
    newAccount.enc_password = NSData(bytes: password, length: password.count)
    newAccount.usages = Set<CDUsageInfo>()
    
    return newAccount
  }
  

  func add(account: CDAccount, save : Bool = true) -> NSError? {
    let keyCharacter = String(account.title![account.title!.startIndex]).uppercaseString
    if let _ = accounts[keyCharacter] {
      accounts[keyCharacter]?.append(account);
    } else {
      accounts[keyCharacter] = [account];
    }
    
    if save {
      return self.save()
    } else {
      return nil
    }
  }
  
  
  private func save() -> NSError? {
    do {
      try managedCtx.save()
    } catch {
      return error as NSError
    }
    return nil
  }

  
  func updateUsageInfo(account: CDAccount, type: CDUsageInfo.UsageType) -> NSError? {
    let newUsage : CDUsageInfo = createCDObject(managedCtx)
    newUsage.date = NSDate()
    newUsage.type = type
    account.usages.insert(newUsage)
    
    return save()
  }
  
  private func initializeDict(accounts: Set<CDAccount>) {
    //------- Lambda
    let isEncrypted = { (account: CDAccount) in
      return account.title == nil
    }
    
    for account in accounts {
      if isEncrypted(account) {
        encryptedAccounts.append(account)
      } else {
        // We are only loading here, no need to save
        add(account, save: false)
      }
    }
  }
  
  private var encryptedAccounts = [CDAccount]()
}
