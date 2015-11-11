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
  //var accountInfos = AccountInfos()
  let managedObjectCtx = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
  
  
  // Set by PairingViewController
  var bleManager :BleManager2!
  var token :Token2!
  var profile: CDProfile!
  var accountMgr: AccountManager!

  var navigationLocked = true;
  
  var accountSectionTitles = [String]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    unlockCapabilities()
  }
  
  override func viewWillAppear(animated: Bool) {
    accountMgr = AccountManager(profile: profile, managedCtx: managedObjectCtx)
    accountSectionTitles = Array(accountMgr.accounts.keys).sort()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: - Table view data source
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return accountMgr.accounts.count
  }

  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return accountSectionTitles[section];
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionTitle = accountSectionTitles[section];
    return accountMgr.accounts[sectionTitle]!.count;
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("AccountCell", forIndexPath: indexPath) as! AccountTableViewCell;
    let account = accountAtIndexPath(indexPath)
    
    cell.account = account
    cell.keyboardTriggeredHandler = self.onKeyboardTriggered
    cell.keyboardEnterTriggeredHandler = self.onKeyboardEnterTriggered
    cell.showPasswordTriggeredHandler = self.onShowPasswordTriggered
    cell.clipboardTriggeredHandler = self.onClipboardTriggered
    
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
          addAccountVC.accountMgr = accountMgr
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
  func accoundAdded(controller: AddAccountViewController, newAccount: CDAccount) {
    
    accountMgr.add(newAccount)
    do {
     try managedObjectCtx.save()
    } catch {
      showError(error: error as NSError)
      print("Cannot save new account: \(error)")
    }
    
    accountSectionTitles = Array(accountMgr.accounts.keys);
    accountSectionTitles.sortInPlace();
    tableView.reloadData()
    controller.navigationController?.popViewControllerAnimated(true)
  }
  
  
  
  // MARK: - Helper Methods
  func accountAtIndexPath(indexPath: NSIndexPath) -> CDAccount {
    let sectionTitle = accountSectionTitles[indexPath.section]
    let accounts = accountMgr.accounts[sectionTitle]!
    let account = accounts[indexPath.row]
    return account
  }
  
  func phoneticDescription(password: String) -> String {
    let phoneticAlphabet : [Character : String] = [
      "a" : "alfa",
      "b" : "bravo",
      "c" : "charlie",
      "d" : "delta",
      "e" : "echo",
      "f" : "foxtrot",
      "g" : "golf",
      "h" : "hotel",
      "i" : "india",
      "j" : "juliette",
      "k" : "kilo",
      "l" : "lima",
      "m" : "mike",
      "n" : "november",
      "o" : "oscar",
      "p" : "papa",
      "q" : "quebec",
      "r" : "romeo",
      "s" : "sierra",
      "t" : "tango",
      "u" : "uniform",
      "v" : "victor",
      "w" : "whiskey",
      "x" : "xray",
      "y" : "yankee",
      "z" : "zulu"]
    
    var resultString = ""
    
    for character in password.characters {
      let lowerCaseCharacter = String(character).lowercaseString.characters.first!;
      if let phoneticName = phoneticAlphabet[lowerCaseCharacter] {
        if character == lowerCaseCharacter {
          resultString += " " + phoneticName
        } else {
          resultString += " " + phoneticName.uppercaseString
        }
      } else {
        // Character is a numeric or special one
        resultString += " " + String(character)
      }
    }
    return resultString
  }
  
  
  // MARK: - Shortcuts Events Management
  func onKeyboardTriggered(account: CDAccount) {
    if token == nil {
      showMessage("Cannot handle action", subtitle: "Token is not connected")
      return
    }

    
    showMessage("Sending Keystrokes...", hideOnTap: false, showAnnimation: true)
    token.writePassword(account.enc_password.arrayOfBytes()) { (error) in
      if let err = error {
        showError("Woww...", error: err)
      } else {
        self.accountMgr.updateUsageInfo(account, type: .Keyboard)
        self.tableView.reloadData()
        hideMessage()
      }
    }
  }

  
  func onKeyboardEnterTriggered(account: CDAccount) {
    if token == nil {
      showMessage("Cannot handle action", subtitle: "Token is not connected")
      return
    }

    var additionalKeys = [UInt8]();
    additionalKeys.append(0xB0);
    
    showMessage("Sending Keystrokes...", hideOnTap: false, showAnnimation: true)
    token.writePassword(account.enc_password.arrayOfBytes(), additionalKeys: additionalKeys) { (error) in
      if let err = error {
        showError("Woww...", error: err)
      } else {
        self.accountMgr.updateUsageInfo(account, type: .Keyboard)
        self.tableView.reloadData()
        hideMessage()
      }
    }
  }
  

  func onShowPasswordTriggered(account: CDAccount) {
    if token == nil {
      showMessage("Cannot handle action", subtitle: "Token is not connected")
      return
    }
    
    showMessage("Retrieving password...", hideOnTap: false, showAnnimation: true)
    
    token.retrievePassword(account.enc_password.arrayOfBytes()) { (clearPassword, error) in
      if let err = error {
        showError(error: err)
      } else {
        let passwordFont = UIFont(name: "Menlo-Regular", size: 18)
        let phoneticDesciprion = self.phoneticDescription(clearPassword)
        showMessage(clearPassword, subtitle: phoneticDesciprion, font: passwordFont)
        self.accountMgr.updateUsageInfo(account, type: .Display)
      }
    }
  }
  

  func onClipboardTriggered(account: CDAccount) {
    if token == nil {
      showMessage("Cannot handle action", subtitle: "Token is not connected")
      return
    }
    
    showMessage("Retrieving password...", hideOnTap: false, showAnnimation: true)
    
    token.retrievePassword(account.enc_password.arrayOfBytes()) { (clearPassword, error) in
      if let err = error {
        showError(error: err)
      } else {
        UIPasteboard.generalPasteboard().string = clearPassword;
        self.accountMgr.updateUsageInfo(account, type: .Clipboard)
        showMessage("Password copied to clipboard")
      }
    }
  }
  
  
  
  
}
