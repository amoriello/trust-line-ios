//
//  AccountDetailTableViewController.swift
//  Trustline
//
//  Created by matt on 07/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit

class AccountDetailTableViewController: UITableViewController {
  var account: CDAccount!
  
  // MARK - IBOutlets
  @IBOutlet weak var accountTitle: UILabel!
  @IBOutlet weak var accountLogin: UILabel!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()

    self.accountTitle.text = account.title;
    self.accountLogin.text = "replace_this@gmail.com";
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
