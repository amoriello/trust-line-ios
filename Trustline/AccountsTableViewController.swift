//
//  PasswordsTableViewController.swift
//  Trustline
//
//  Created by matt on 05/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import CoreData

class AccountsTableViewController: UITableViewController, AddAccountDelegate, NSFetchedResultsControllerDelegate {
  
  // MARK: - Injected
  var dataController: DataController!
  var token :Token!
  var profile: CDProfile!
  
  // MARK: - Attributes
  var navigationLocked = true;
  var fetchedAccountController: NSFetchedResultsController!
  
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    unlockCapabilities()
  }
  
  override func viewWillAppear(animated: Bool) {
    initializeFetchedAccountController(dataController.managedObjectContext)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  
  func initializeFetchedAccountController(moc: NSManagedObjectContext) {
    let request = NSFetchRequest(entityName: "CDAccount")
    let firstLetterSort = NSSortDescriptor(key: "firstLetterAsCap", ascending:  true)
    let accountTitleSort = NSSortDescriptor(key: "title", ascending: true)
    request.sortDescriptors = [firstLetterSort, accountTitleSort]
    
    fetchedAccountController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc,
                                                          sectionNameKeyPath: "firstLetterAsCap", cacheName: "rootCache")
    self.fetchedAccountController.delegate = self
    
    do {
      try self.fetchedAccountController.performFetch()
    } catch {
      fatalError("Failed to initialize fetchedAccountController: \(error)")
    }
  }
  
  func configureCell(cell: AccountTableViewCell, indexPath: NSIndexPath) {
    let account = accountAtIndexPath(indexPath)
    
    cell.account = account
    cell.keyboardTriggeredHandler = self.onKeyboardTriggered
    cell.keyboardEnterTriggeredHandler = self.onKeyboardEnterTriggered
    cell.showPasswordTriggeredHandler = self.onShowPasswordTriggered
    cell.clipboardTriggeredHandler = self.onClipboardTriggered
  }
  
  // MARK: - Table view data source
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return fetchedAccountController.sections!.count
  }
  
  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let sections = fetchedAccountController.sections!
    let sectionInfo = sections[section]
    return sectionInfo.name
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sections = fetchedAccountController.sections!
    let sectionInfo = sections[section]
    return sectionInfo.numberOfObjects
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("AccountCell", forIndexPath: indexPath) as! AccountTableViewCell;
    configureCell(cell, indexPath: indexPath)
    return cell;
  }
  
  
  
  // MARK: - NSFetchedResultsControllerDelegate
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    self.tableView.beginUpdates()
  }
  
  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    switch type {
    case .Insert:
      self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    case .Delete:
      self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    case .Move:
      break
    case .Update:
      break
    }
  }
  
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    switch type {
    case .Insert:
      self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
    case .Delete:
      self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
    case .Update:
      let cell = self.tableView.cellForRowAtIndexPath(indexPath!)! as! AccountTableViewCell
      self.configureCell(cell, indexPath: indexPath!)
    case .Move:
      self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
      self.tableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
    }
  }
  
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    self.tableView.endUpdates()
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
          addAccountVC.token = token
          addAccountVC.profile = profile
          addAccountVC.dataController = dataController
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
    dataController.save()
    controller.navigationController?.popViewControllerAnimated(true)
  }
  
  
  // MARK: - Helper Methods
  func accountAtIndexPath(indexPath: NSIndexPath) -> CDAccount {
    return fetchedAccountController.objectAtIndexPath(indexPath) as! CDAccount
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
        self.dataController.updateUsageInfo(account, type: .Keyboard)
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
        self.dataController.updateUsageInfo(account, type: .Keyboard)
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
        self.dataController.updateUsageInfo(account, type: .Display)
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
        self.dataController.updateUsageInfo(account, type: .Clipboard)
        showMessage("Password copied to clipboard")
      }
    }
  }
}
