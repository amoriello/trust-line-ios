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
  typealias CellActionTriggeredHandler = (CDAccount) -> (Void)
  
  @IBOutlet weak var accountName: UILabel!
  @IBOutlet weak var login: UILabel!
  @IBOutlet weak var lastUse: UILabel!

  
  var keyboardTriggeredHandler: CellActionTriggeredHandler?
  var showPasswordTriggeredHandler: CellActionTriggeredHandler?
  var clipboardTriggeredHandler: CellActionTriggeredHandler?
  
  var account: CDAccount! {
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
    
    if let _ = account.login {
      login.text = "replace_this@gmail.com"
    } else {
      login.text = ""
    }
    
    let usages = Array(account.usages).sort {
      $0.date.timeIntervalSinceReferenceDate < $1.date.timeIntervalSinceReferenceDate
    }
    
    
    if usages.count > 0 {
      let dateFormater = NSDateFormatter()
      dateFormater.dateFormat = "MMM, d 'at' HH:mm"
      lastUse.text = dateFormater.stringFromDate(usages.last!.date)
    } else {
      lastUse.text = "Nerver used"
    }
  }


  private func addAnimationToCell() {
    let slideGestureRecognizer = DRCellSlideGestureRecognizer();
    
    let sendKeystrokesAction = DRCellSlideAction(forFraction: 0.45)
    sendKeystrokesAction.elasticity = 10
    sendKeystrokesAction.icon = UIImage(named: "keyboard")
    sendKeystrokesAction.activeBackgroundColor = greenColor
    sendKeystrokesAction.didTriggerBlock = {(tableview, indexPath) in
      if let handler = self.keyboardTriggeredHandler {
        handler(self.account)
      }
    }
    
    let showPasswordAction = DRCellSlideAction(forFraction: -0.35)
    showPasswordAction.activeBackgroundColor = blueColor
    showPasswordAction.icon = UIImage(named: "visible")
    showPasswordAction.elasticity = 10
    showPasswordAction.didTriggerBlock = {(tableView, indexPath) in
      if let handler = self.showPasswordTriggeredHandler {
        handler(self.account)
      }
    }
    
    
    let copyToClipboardAction = DRCellSlideAction(forFraction: -0.55)
    copyToClipboardAction.activeBackgroundColor = yellowColor
    copyToClipboardAction.icon = UIImage(named: "clipboard")
    copyToClipboardAction.elasticity = 10
    copyToClipboardAction.didTriggerBlock = {(tableView, indexPath) in
      if let handler = self.clipboardTriggeredHandler {
        handler(self.account)
      }
    }
    
    slideGestureRecognizer.addActions(sendKeystrokesAction)
    slideGestureRecognizer.addActions(showPasswordAction)
    slideGestureRecognizer.addActions(copyToClipboardAction)
    
    self.addGestureRecognizer(slideGestureRecognizer)
  }
  

}
