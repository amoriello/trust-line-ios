//
//  Account.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import CoreData

@objc(CDAccount)
class CDAccount: NSManagedObject {
  @NSManaged var creation: NSDate

  @NSManaged var login: CDLogin?
  @NSManaged var enc_password: NSData
  @NSManaged var enc_title: NSData?
  
  @NSManaged var title: String?
  @NSManaged var firstLetterAsCap: String
  
  @NSManaged var profile: CDProfile
  @NSManaged var securityQAs: Set<CDSecurityQA>?
  @NSManaged var usages: Set<CDUsageInfo>
}
