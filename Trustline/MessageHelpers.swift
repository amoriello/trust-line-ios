//
//  MessageHelpers.swift
//  Trustline
//
//  Created by matt on 11/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import Foundation
import SwiftSpinner


func createError(title: String, description: String, code: Int = 1) -> NSError {
  var userInfo = [NSLocalizedDescriptionKey: description]
  userInfo["Title"] = title
  return NSError(domain: "TrustLine", code: code, userInfo: userInfo)
}


func createError(title: String, description: String, status: Response.Status) -> NSError {
  return createError(title, description: description, code: (Int)(status.rawValue))
}


func delay(seconds seconds: Double, completion:()->()) {
  let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64( Double(NSEC_PER_SEC) * seconds ))
  
  dispatch_after(popTime, dispatch_get_main_queue()) {
    completion()
  }
}

func showError(title: String? = "Wooww!", error: NSError) {
  let printTitle :String!
  if let customTitle = error.userInfo["Title"] {
    printTitle = customTitle as! String
  } else {
    printTitle = title
  }
  
  SwiftSpinner.show(printTitle, animated: false).addTapHandler({SwiftSpinner.hide()}, subtitle: error.localizedDescription)
  print("Error: \(title): \(error.description)")
}


func showMessage(title: String, subtitle: String? = nil, hideOnTap: Bool = true, showAnnimation :Bool = false) {
  SwiftSpinner.show(title, animated: showAnnimation).addTapHandler({ if hideOnTap { SwiftSpinner.hide() } }, subtitle: subtitle)
  print("Message: \(title): \(subtitle)")
}

func showMessage(title: String, subtitle: String? = nil, hideOnTap: Bool = true, showAnnimation :Bool = false, tapAction: ()->(Void)) {
  SwiftSpinner.show(title, animated: showAnnimation).addTapHandler({ if hideOnTap { SwiftSpinner.hide() }; tapAction() }, subtitle: subtitle)
  print("Message: \(title): \(subtitle)")
}

func hideMessage() {
  SwiftSpinner.hide()
}