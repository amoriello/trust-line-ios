//
//  AccountDetailTableViewController.swift
//  Trustline
//
//  Created by matt on 07/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit

class AccountDetailTableViewController: UITableViewController {
  var account: Account!
  
  // MARK - IBOutlets
  @IBOutlet weak var accountTitle: UILabel!
  @IBOutlet weak var accountLogin: UILabel!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    self.accountTitle.text = account.title;
    self.accountLogin.text = account.login;
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
