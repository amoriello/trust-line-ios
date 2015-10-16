//
//  PasswordsTableViewController.swift
//  Trustline
//
//  Created by matt on 05/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import SwiftSpinner

class AccountsTableViewController: UITableViewController, AddAccountDelegate {
  var accountInfos = AccountInfos()
  
  var bleManager :BleManager2!
  var token :Token2!
  var settings = TrustLineSettings()
  var keyMaterial = KeyMaterial()
  var navigationLocked = true;
  
  var accountSectionTitles = [String]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    lockCapabilities()
    
    bleManager = BleManager2(managerStateErrorHandler: self.bleManagerStateChange, keyMaterial: keyMaterial)
    showMessage("Searching Tokens...", hideOnTap: false, showAnnimation: true)
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
    if navigationLocked {
      return
    }
    
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
  
  func lockCapabilities() {
    navigationLocked = true;
    navigationController?.navigationBar.userInteractionEnabled = false
  }
  
  
  func unlockCapabilities() {
    navigationLocked = false;
    navigationController?.navigationBar.userInteractionEnabled = true
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
  

  
  // MARK: - Shortcuts Events Management
  func onKeyboardTriggered(account: Account) {
    if token == nil {
      showMessage("Cannot handle action", subtitle: "Token is not connected")
      return
    }

    
    showMessage("Sending Keystrokes...", hideOnTap: false, showAnnimation: true)
    token.writePassword(account.password) { (error) in
      if let err = error {
        showError("Woww...", error: err)
      } else {
        account.updateUsageInfo(.Keyboard)
        self.tableView.reloadData()
        hideMessage()
      }
    }
  }

  
  func onKeyboardEnterTriggered(account: Account) {
    if token == nil {
      showMessage("Cannot handle action", subtitle: "Token is not connected")
      return
    }

    var additionalKeys = [UInt8]();
    additionalKeys.append(0xB0);
    
    showMessage("Sending Keystrokes...", hideOnTap: false, showAnnimation: true)
    token.writePassword(account.password, additionalKeys: additionalKeys) { (error) in
      if let err = error {
        showError("Woww...", error: err)
      } else {
        account.updateUsageInfo(.Keyboard)
        self.tableView.reloadData()
        hideMessage()
      }
    }
  }
  
  

  func onClipboardTriggered(account: Account) {
    if token == nil {
      showMessage("Cannot handle action", subtitle: "Token is not connected")
      return
    }
  }

  
  
  
  // MARK: - Ble Token discovery, connection and state management
  func initializeToken() {
    bleManager.discoverTokens(self.onTokensDiscovered)
  }
  
  
  func onTokensDiscovered(tokens: [Token2], error: NSError?) {
    if let err = error {
      showError("Woww!", error: err)
      print(err.description)
      return
    }

    if (tokens.isEmpty) {
      showMessage("No token found")
      return
    }
    
    self.token = tokens[0]
    
    var message: String
    if tokens.count > 1 {
      message = "Found\n\(tokens.count)\nTokens"
    } else {
      message = "Found\n\(tokens.count)\nToken"
    }
    
    showMessage(message, hideOnTap: false, showAnnimation: true)
    showMessage("Connecting...", hideOnTap: false, showAnnimation: true)
    
    token.connect(self.onTokenConnected)
  }


  func onTokenConnected(error: NSError?) {
    if let err = error {
      showError("Connection Failed", error: err)
    } else {
      print("token connected!")
      showMessage("Connected!", hideOnTap: false, showAnnimation: true)
      showMessage("Pairing...", hideOnTap: false, showAnnimation: true)
      
      token.pair({ (error) -> (Void) in
        if let err = error {
          showError("Cannot Pair", error: err)
        } else {
          self.unlockCapabilities()
          showMessage("Token Paired and Ready")
        }
      })
    }
  }
  
  func bleManagerStateChange(error: NSError?) {
    if let err = error {
      showError("Connection Error", error: err)
      print(err.description)
      lockCapabilities()
      token = nil
    }
  }
}
