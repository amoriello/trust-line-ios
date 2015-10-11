//
//  PasswordsTableViewController.swift
//  Trustline
//
//  Created by matt on 05/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import DRCellSlideGestureRecognizer

class AccountsTableViewController: UITableViewController {
  lazy var accountDict: AccountInfos.AccountDict = {
    var accountInfos = AccountInfos.getAccountInfo();
    return accountInfos.accountDict;
  }()
  
  let greenColor = UIColor(red: 91/255.0, green: 220/255.0, blue: 88/255.0, alpha: 1)
  let blueColor  = UIColor(red: 24/255.0, green: 182/255.0, blue: 222/255.0, alpha: 1)
  
  var bleManager :BleManager2!
  var token :Token2!
  var settings = TrustLineSettings()
  var keyMaterial = KeyMaterial()
  
  var accountSectionTitles = [String]()
  
  let accountIndexTitles = ["A", "B", "C", "D", "E", "F", "G",
                            "H", "I", "J", "K", "L", "M", "N",
                            "O", "P", "Q", "R", "S", "T", "U",
                            "V", "W", "X", "Y", "Z"]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    bleManager = BleManager2(managerStateErrorHandler: self.bleManagerStateChange, keyMaterial: keyMaterial)


    bleManager.discoverTokens { (tokens, error) -> (Void) in
      if let err = error {
        print(err.description)
        return
      }
      
      if (tokens.count != 1) {
        print("tokens count: \(tokens.count)")
        return
      }
      
      self.token = tokens[0]
      
      self.token.connect({ (error) -> (Void) in
        if let err = error {
          print("Cannot connect to token: \(err.description)")
        } else {
          print("token connected!")
        }
        
      })
      
    }
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    accountSectionTitles = Array(accountDict.keys);
    accountSectionTitles.sortInPlace();
  }
  
  func bleManagerStateChange(error: NSError?) {
    if let err = error {
      print(err.description)
    }
  }
  
  
  override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
    return accountSectionTitles
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: - Table view data source

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return accountSectionTitles.count
  }

  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return accountSectionTitles[section];
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionTitle = accountSectionTitles[section];
    return accountDict[sectionTitle]!.count;
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("AccountCell", forIndexPath: indexPath) as UITableViewCell;

    let account = accountAtIndexPath(indexPath)
    
    cell.textLabel?.text = account.title;
    cell.detailTextLabel?.text = account.login;
    
    
    let slideGestureRecognizer = DRCellSlideGestureRecognizer();
    
    let sendKeystrokesAction = DRCellSlideAction(forFraction: 0.35)
    sendKeystrokesAction.elasticity = 40
    sendKeystrokesAction.icon = UIImage(named: "keyboard")
    sendKeystrokesAction.activeBackgroundColor = greenColor
    
    sendKeystrokesAction.didTriggerBlock = {(tableview, indexPath) in
      print("left yeah")
    }
    
    let copyToClipboardAction = DRCellSlideAction(forFraction: -0.35)
    copyToClipboardAction.activeBackgroundColor = blueColor
    copyToClipboardAction.icon = UIImage(named: "clipboard")
    copyToClipboardAction.elasticity = 40
    copyToClipboardAction.didTriggerBlock = {(tableView, indexPath) in
      print("Rigth Yeah")
    }
    
    slideGestureRecognizer.addActions(sendKeystrokesAction)
    slideGestureRecognizer.addActions(copyToClipboardAction)
    
    cell.addGestureRecognizer(slideGestureRecognizer)
    
    return cell;
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      let indexTitle = accountSectionTitles[indexPath.section]
      accountDict[indexTitle]!.removeAtIndex(indexPath.row)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
      
      if accountDict[indexTitle]!.isEmpty {
        accountDict.removeValueForKey(indexTitle)
        accountSectionTitles.removeAtIndex(indexPath.section)
        tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
      }
    }
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
        default: break;
      }
    }
  }
  
  
  
  // MARK: - Helper Methods
  func accountAtIndexPath(indexPath: NSIndexPath) -> Account {
    let sectionTitle = accountSectionTitles[indexPath.section]
    let accounts = accountDict[sectionTitle]!
    let account = accounts[indexPath.row]
    return account
  }
  
  
}
