//
//  Account.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import CoreData

class CDAccount: NSManagedObject {
  @NSManaged var creation: NSDate

  @NSManaged var enc_login: NSData
  @NSManaged var enc_password: NSData
  @NSManaged var enc_title: NSData
  
  @NSManaged var isEncrypted: Bool
  
  @NSManaged var login: String
  @NSManaged var title: String
  
  @NSManaged var profile: CDProfile
  @NSManaged var securityQAs: [CDSecurityQA]
  @NSManaged var usages: [CDUsageInfo]
}
