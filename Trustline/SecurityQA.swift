//
//  SecurityQA.swift
//  Trustline
//
//  Created by matt on 25/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import CoreData

@objc(CDSecurityQA)
class CDSecurityQA: NSManagedObject {
  @NSManaged var question: String
  @NSManaged var answer: NSData
  @NSManaged var account: CDAccount
}
