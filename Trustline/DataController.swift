//
//  DataController.swift
//  Trustline
//
//  Created by matt on 21/11/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation
import CoreData

class DataController: NSObject {
  typealias CompletionHandler = (NSError?) -> Void
  var managedObjectContext: NSManagedObjectContext
  
  init(completion: CompletionHandler? = nil) {
    guard let modelURL = NSBundle.mainBundle().URLForResource("Trustline", withExtension: "momd") else {
      fatalError("Error loading model from bundle")
    }
    
    guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
      fatalError("Error initializing managed object model from \(modelURL)")
    }
    
    let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
    
    self.managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    self.managedObjectContext.persistentStoreCoordinator = psc
    
    super.init()
    
    // Lamda to initialize persistent store
    let initPersistentStore = { () -> NSError? in
      let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
      let docURL = urls.last!
      let storeURL = docURL.URLByAppendingPathComponent("Trustline.sqlite")
      
      do {
        try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
      } catch {
        return error as NSError
      }
      return nil
    }
    
    // Either call persistance store initialization on background
    // or in main thread (blocking) depending on the availability of
    // the completion handler (optional parameter)
    if  completion != nil {
      background { let err = initPersistentStore(); completion!(err) }
    } else {
      if let error = initPersistentStore() {
        fatalError("Cannot initialize peristance store: \(error)")
      }
    }
  }
  
  
  func createAccount(profile: CDProfile, title: String, login: String, password: [UInt8]) -> CDAccount {
    let newAccount: CDAccount = createCDObject(managedObjectContext)
    let newLogin: CDLogin = createCDObject(managedObjectContext)
    
    let firstLetterAsCap = { (name: String) -> String in
      String(name[name.startIndex]).uppercaseString
    }
    
    newAccount.creation = NSDate()
    newAccount.profile = profile
    newAccount.title = title
    newAccount.firstLetterAsCap = firstLetterAsCap(title)
    newAccount.login = newLogin
    newAccount.enc_password = NSData(bytes: password, length: password.count)
    newAccount.usages = Set<CDUsageInfo>()
    
    return newAccount
  }
  
  
  func save() {
    if !managedObjectContext.hasChanges {
      return
    }
    
    do {
      try managedObjectContext.save()
    } catch {
      fatalError("Failure to save context: \(error)")
    }
  }
  
  
  func updateUsageInfo(account: CDAccount, type: CDUsageInfo.UsageType) {
    let newUsage : CDUsageInfo = createCDObject(managedObjectContext)
    newUsage.date = NSDate()
    newUsage.type = type
    account.usages.insert(newUsage)
    
    save()
  }
  
  
  private func background(action: () -> Void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), action)
  }
}