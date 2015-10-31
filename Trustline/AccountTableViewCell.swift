//
//  AccountTableViewCell.swift
//  Trustline
//
//  Created by matt on 11/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import DRCellSlideGestureRecognizer

class AccountTableViewCell: UITableViewCell {
  typealias CellActionTriggeredHandler = (Account) -> (Void)
  
  @IBOutlet weak var accountName: UILabel!
  @IBOutlet weak var login: UILabel!
  @IBOutlet weak var lastUse: UILabel!

  
  var keyboardTriggeredHandler: CellActionTriggeredHandler?
  var keyboardEnterTriggeredHandler: CellActionTriggeredHandler?
  var showPasswordTriggeredHandler: CellActionTriggeredHandler?
  var clipboardTriggeredHandler: CellActionTriggeredHandler?
  
  var account: Account! {
    didSet {
      updateAccountViewCell()
    }
  }
  
  let greenColor = UIColor(red: 91/255.0, green: 220/255.0, blue: 88/255.0, alpha: 1)
  let blueColor  = UIColor(red: 24/255.0, green: 182/255.0, blue: 222/255.0, alpha: 1)
  let yellowColor  = UIColor(red: 254/255.0, green: 217/255.0, blue: 56/255.0, alpha: 1)

  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    addAnimationToCell()
  }

  override func setSelected(selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }
  
  
  private func updateAccountViewCell() {
    accountName.text = account.title
    
    if let loginText = account.login {
      login.text = loginText
    } else {
      login.text = ""
    }
    
    if let lastUseInfo = account.usageInfos.last {
      let dateFormater = NSDateFormatter()
      dateFormater.dateFormat = "MMM, d 'at' HH:mm"
      lastUse.text = dateFormater.stringFromDate(lastUseInfo.date)
    } else {
      lastUse.text = "Nerver used"
    }
  }


  private func addAnimationToCell() {
    let slideGestureRecognizer = DRCellSlideGestureRecognizer();
    
    let sendKeystrokesAction = DRCellSlideAction(forFraction: 0.35)
    sendKeystrokesAction.elasticity = 10
    sendKeystrokesAction.icon = UIImage(named: "keyboard")
    sendKeystrokesAction.activeBackgroundColor = greenColor
    sendKeystrokesAction.didTriggerBlock = {(tableview, indexPath) in
      print("send Keyboard")
      if let handler = self.keyboardTriggeredHandler {
        handler(self.account)
      }
    }
    
    let sendKeystrokesEnterAction = DRCellSlideAction(forFraction: 0.55)
    sendKeystrokesEnterAction.elasticity = 10
    sendKeystrokesEnterAction.icon = UIImage(named: "keyboard")
    sendKeystrokesEnterAction.activeBackgroundColor = yellowColor
    sendKeystrokesEnterAction.didTriggerBlock = {(tableView, indexPath) in
      print("send Keyboard + Enter")
      if let handler = self.keyboardEnterTriggeredHandler {
        handler(self.account)
      }
    }
    
    
    let showPasswordAction = DRCellSlideAction(forFraction: -0.35)
    showPasswordAction.activeBackgroundColor = blueColor
    showPasswordAction.icon = UIImage(named: "visible")
    showPasswordAction.elasticity = 10
    showPasswordAction.didTriggerBlock = {(tableView, indexPath) in
      print("Show password")
      if let handler = self.showPasswordTriggeredHandler {
        handler(self.account)
      }
    }
    
    
    let copyToClipboardAction = DRCellSlideAction(forFraction: -0.55)
    copyToClipboardAction.activeBackgroundColor = blueColor
    copyToClipboardAction.icon = UIImage(named: "clipboard")
    copyToClipboardAction.elasticity = 10
    copyToClipboardAction.didTriggerBlock = {(tableView, indexPath) in
      print("Copy Clipboard")
      if let handler = self.clipboardTriggeredHandler {
        handler(self.account)
      }
    }
    
    slideGestureRecognizer.addActions(sendKeystrokesAction)
    slideGestureRecognizer.addActions(sendKeystrokesEnterAction)
    slideGestureRecognizer.addActions(showPasswordAction)
    slideGestureRecognizer.addActions(copyToClipboardAction)
    
    self.addGestureRecognizer(slideGestureRecognizer)
  }
  

}
