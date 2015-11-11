//
//  CDLogin.swift
//  Trustline
//
//  Created by matt on 01/11/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import CoreData

@objc(CDLogin)
class CDLogin: NSManagedObject {
  @NSManaged var string: String?
  @NSManaged var enc_string: NSData?
  @NSManaged var accounts: Set<CDAccount>?
}
