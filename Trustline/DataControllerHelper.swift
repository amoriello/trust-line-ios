//
//  CoreData.swift
//  Trustline
//
//  Created by matt on 09/11/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation
import CoreData


protocol NamedCDComponent : class {
  @nonobjc static var ComponentName: String { get }
}

extension CDAccount : NamedCDComponent {
  @nonobjc static let ComponentName = "CDAccount"
}

extension CDProfile : NamedCDComponent {
  @nonobjc static let ComponentName = "CDProfile"
}

extension CDSecurityQA : NamedCDComponent {
  @nonobjc static let ComponentName = "CDSecurityQA"
}

extension CDSettings : NamedCDComponent {
  @nonobjc static let ComponentName = "CDSettings"
}

extension CDStrength : NamedCDComponent {
  @nonobjc static let ComponentName = "CDStrength"
}

extension CDPairedToken : NamedCDComponent {
  @nonobjc static let ComponentName = "CDPairedToken"
}

extension CDUsageInfo : NamedCDComponent {
  @nonobjc static let ComponentName = "CDUsageInfo"
}

extension CDLogin : NamedCDComponent {
  @nonobjc static let ComponentName = "CDLogin"
}


func createCDObject<T:NamedCDComponent>(managedContext: NSManagedObjectContext) -> T {
  let objEntity = NSEntityDescription.entityForName(T.ComponentName, inManagedObjectContext: managedContext)!
  let obj = NSManagedObject(entity: objEntity, insertIntoManagedObjectContext: managedContext) as! T
  return obj
}

enum TryResult<T> {
  case Value(T)
  case Error(ErrorType)
}


func safeTry<T>(block: () throws -> T) -> TryResult<T> {
  do {
    let value = try block()
    return TryResult.Value(value)
  } catch {
    return TryResult.Error(error)
  }
}



func loadCDObjects<T:NamedCDComponent>(managedContext: NSManagedObjectContext) -> [T]? {
  let fetchRequest = NSFetchRequest(entityName: T.ComponentName);
  let result = safeTry { try managedContext.executeFetchRequest(fetchRequest) as! [T] }
  
  switch result {
  case .Value(let value):
    return value
  case .Error(let error):
    print("Error fecthing \(T.ComponentName): \(error)");
    return nil
  }
}



class Default {
  class func Profile(managedCtx: NSManagedObjectContext) -> CDProfile {
    let profile : CDProfile = createCDObject(managedCtx)
    
    profile.creation = NSDate()
    profile.name = "default"
    profile.accounts = Set<CDAccount>()
    
    let settings = Default.Settings(forProfile: profile, managedCtx: managedCtx)
    profile.settings = settings;
    
    return profile
  }

  
  private class func Settings(forProfile profile: CDProfile, managedCtx: NSManagedObjectContext) -> CDSettings {
    let settings : CDSettings = createCDObject(managedCtx)
    
    settings.useiCloud = false;
    settings.layoutOption = CDSettings.KeyboardLayoutOptions.EnglishUS
    settings.strengths = Default.Strengths(settings, managedCtx: managedCtx)
    settings.profile = profile
    
    return settings;
  }
  
  
  private class func Strengths(defaultSettings: CDSettings, managedCtx: NSManagedObjectContext) -> Set<CDStrength> {
    let createStrength = { (nbChars: Int16, description: String, settings: CDSettings) -> CDStrength in
      let strength : CDStrength = createCDObject(managedCtx)
      
      strength.nbChars = nbChars
      strength.pickerDescription = description
      strength.settings = [defaultSettings]
      return strength
    }
    
    let serious   = createStrength(8, "Serious (8)", defaultSettings)
    let strong    = createStrength(15, "Strong (15)", defaultSettings)
    let insane    = createStrength(25, "Insane (25)", defaultSettings)
    let ludicrous = createStrength(40, "Ludicrous (40)", defaultSettings)
    
    return [serious, strong, insane, ludicrous]
  }
}


class AccountHelper {

  
  private class func decryptAccounts(encryptedAccounts: [CDAccount], token: Token) -> [CDAccount]? {
    return nil
  }
}




