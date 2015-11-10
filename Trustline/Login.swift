//
//  CDLogin.swift
//  Trustline
//
//  Created by matt on 01/11/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import CoreData

class CDLogin: NSManagedObject {
  @NSManaged var enc_string: NSData
  @NSManaged var accounts: Set<CDAccount>?
}
