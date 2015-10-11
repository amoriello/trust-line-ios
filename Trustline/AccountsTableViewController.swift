//
//  PasswordsTableViewController.swift
//  Trustline
//
//  Created by matt on 05/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import DRCellSlideGestureRecognizer

class AccountsTableViewController: UITableViewController, AddAccountDelegate {
  var accountInfos = AccountInfos()
  
  
  var bleManager :BleManager2!
  var token :Token2!
  var settings = TrustLineSettings()
  var keyMaterial = KeyMaterial()
  
  var accountSectionTitles = [String]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    bleManager = BleManager2(managerStateErrorHandler: self.bleManagerStateChange, keyMaterial: keyMaterial)
    initializeToken();
    
    accountSectionTitles = Array(accountInfos.accountDict.keys);
    accountSectionTitles.sortInPlace();
  }
  

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: - Table view data source
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return accountInfos.accountDict.count
  }

  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return accountSectionTitles[section];
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionTitle = accountSectionTitles[section];
    return accountInfos.accountDict[sectionTitle]!.count;
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("AccountCell", forIndexPath: indexPath) as! AccountTableViewCell;
    let account = accountAtIndexPath(indexPath)
    
    cell.account = account
    cell.onKeyboardTriggered(self.onKeyboardTriggered)
    cell.onKeyboardEnterTriggered(self.onKeyboardEnterTriggered)
    cell.onClipBoardTriggered(self.onClipboardTriggered)
    
    return cell;
  }
  
  
  
  // MARK: - Navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let identifier = segue.identifier {
      switch identifier {
        case "showAccountDetail":
          let accountDetailVC = segue.destinationViewController as! AccountDetailTableViewController
          if let indexPath = self.tableView.indexPathForCell(sender as! UITableViewCell) {
            accountDetailVC.account = accountAtIndexPath(indexPath)
          }
        case "addAccount":
          let addAccountVC = segue.destinationViewController as! AddAccountViewController
          addAccountVC.settings = settings
          addAccountVC.token = token
          addAccountVC.delegate = self
        
        default: break;
      }
    }
  }
  
  
  // MARK: - AddAccountDelegate
  func accoundAdded(controller: AddAccountViewController, newAccount: Account) {
    accountInfos.add(newAccount)
    accountSectionTitles = Array(accountInfos.accountDict.keys);
    accountSectionTitles.sortInPlace();
    tableView.reloadData()
    controller.navigationController?.popViewControllerAnimated(true)
  }
  
  
  
  // MARK: - Helper Methods
  func accountAtIndexPath(indexPath: NSIndexPath) -> Account {
    let sectionTitle = accountSectionTitles[indexPath.section]
    let accounts = accountInfos.accountDict[sectionTitle]!
    let account = accounts[indexPath.row]
    return account
  }
  
  
  // MARK: - Ble Token discovery, connection and state management
  func initializeToken() {
    bleManager.discoverTokens(self.onTokensDiscovered)
  }
  
  
  // MARK: - Shortcuts Events Management
  func onKeyboardTriggered(account :Account) {
    if token == nil {
      print("Cannot handle action : Token is nil")
      return
    }
    
    token.writePassword(account.password) { (error) in
      if let err = error {
        print("Error typing password: \(err.description)")
      } else {
        print("Password typed!!")
      }
    }
  }

  func onKeyboardEnterTriggered(account :Account) {
    if token == nil {
      print("Cannot handle action : Token is nil")
      return
    }
    
  }
  
  

  func onClipboardTriggered(account :Account) {
    if token == nil {
      print("Cannot handle action : Token is nil")
      return
    }
    
  }

  
  
  func onTokensDiscovered(tokens: [Token2], error: NSError?) {
    if let err = error {
      print(err.description)
      return
    }
    if (tokens.count != 1) {
      print("tokens count: \(tokens.count)")
      return
    }
    print("Discovered \(tokens.count) Tokens")
    self.token = tokens[0]

    print("Connecting to token 1...")
    token.connect(self.onTokenConnected)
  }
  
  
  func onTokenConnected(error: NSError?) {
    if let err = error {
      print("Cannot connect to token: \(err.description)")
    } else {
      print("token connected!")
      print("Pairing...")
      
      token.pair({ (error) -> (Void) in
        if let err = error {
          print("error pairing device: \(err.description)")
        } else {
          print("Token Paired and Ready!!")
        }
      })
    }
  }
  
  
  func bleManagerStateChange(error: NSError?) {
    if let err = error {
      print(err.description)
    }
  }
}
