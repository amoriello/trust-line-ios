//
//  PairingViewController.swift
//  Trustline
//
//  Created by matt on 16/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import CoreData

class PairingViewController: UIViewController, ReadKeyMaterialDelegate {
  var bleManager :BleManager2!
  var token :Token2!
  
  var settings2 : CDSettings!
  var profile : CDProfile!
  var isPaired = false;
  
  let managedObjectCtx = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    if let profiles : [CDProfile] = loadCDObjects(managedObjectCtx) {
      if profiles.count > 0 {
        self.profile = profiles[0]
      } else {
        print("No default profile found, creating one...")
        self.profile = Default.Profile(managedObjectCtx)
      }
    } else {
      print("Error getting profile")
      return
    }
    
    
    bleManager = BleManager2(managerStateErrorHandler: self.bleManagerStateChange, keyMaterial: profile.keyMaterial)

    if profile.pairedTokens.count != 0 {
      showMessage("Searching Token...", hideOnTap: false, showAnnimation: true)
      
      BleManagement.connectToPairedToken(bleManager, pairedTokens: profile.pairedTokens) { (token, error) in
        if let err = error {
          showError(error: err)
        } else {
          hideMessage()
          self.token = token!
          self.performSegueWithIdentifier("showNavigationSegue", sender: self)
        }
      }
    }
  }
  
  
  func createPairedToken(fromToken token: Token2) -> CDPairedToken {
    let pairedToken : CDPairedToken = createCDObject(managedObjectCtx)
    
    pairedToken.creation = NSDate()
    pairedToken.identifier = token.identifier
    return pairedToken
  }
  

  @IBAction func onPairNewPushed(sender: AnyObject) {
    showMessage("Searching Token...", hideOnTap: false, showAnnimation: true)
    
    BleManagement.pairWithNewToken(bleManager) { (token, error) in
      if let err = error {
        showError(error: err)
      } else {
        self.token = token!
        let pairedToken = self.createPairedToken(fromToken: self.token)
        self.profile.keyMaterial = self.token.keyMaterial!
        self.profile.pairedTokens = [pairedToken]
        
        // Saving profile, settings, associated token and  keys
        if let result = try? self.managedObjectCtx.save() {
          print("save has results: \(result)")
        } else {
          print("save has no results")
        }
        
        showMessage("Token Paired and Ready") {self.performSegueWithIdentifier("showQRGenerator", sender: self) }
      }
    }
  }

  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
    

  func bleManagerStateChange(error: NSError?) {
    if let err = error {
      showError("Connection Error", error: err)
      print(err.description)
      token = nil
    }
  }
  
  
  // MARK: - ReadKeyMaterialDelegate
  func onSyncToken(controller: ReadQrCodeViewController, token: Token2?) {
    if token != nil {
      self.token = token!
      let pairedToken = createPairedToken(fromToken: self.token)
      profile.pairedTokens.insert(pairedToken)
      
      // Saving profile, settings, associated token and  keys
      if let result = try? self.managedObjectCtx.save() {
        print("save has results: \(result)")
      } else {
        print("save has no results")
      }
      
      controller.stop()
      controller.dismissViewControllerAnimated(true, completion: nil)
      showMessage("Token synchronization success!") { self.performSegueWithIdentifier("showNavigationSegue", sender: self) }
      return
    }

    controller.stop()
    controller.dismissViewControllerAnimated(true, completion: nil)
  }
  

  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let identifier = segue.identifier {
      switch identifier {
      case "showNavigationSegue":
        let navigationVC = segue.destinationViewController as! UINavigationController
        let accountsNavigationVC = navigationVC.childViewControllers[0] as! AccountsTableViewController
        accountsNavigationVC.token = token
        accountsNavigationVC.profile = profile
        
      case "showQRGenerator":
        let qrCodeGeneratorVC = segue.destinationViewController as! QrCodeGeneratorViewController
        qrCodeGeneratorVC.keyMaterial = profile.keyMaterial
        qrCodeGeneratorVC.profile = profile
        qrCodeGeneratorVC.token = token
        
      case "showQrReader":
        let readQrVC = segue.destinationViewController as! ReadQrCodeViewController
        readQrVC.delegate = self
        readQrVC.bleManager = self.bleManager
        readQrVC.keyMaterial = self.profile.keyMaterial
        
      default: break;
      }
    }
  }

}
