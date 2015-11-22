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
  
  // MARK: Attributes
  var dataController: DataController!
  var bleManager :BleManager!
  var token :Token!
  var settings2 : CDSettings!
  var profile : CDProfile!
  var isPaired = false;

  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Getting dataController from "global" AppDelegate
    // Passing dataController has dependency injection from now
    self.dataController = (UIApplication.sharedApplication().delegate as! AppDelegate).dataController
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    if let profiles : [CDProfile] = loadCDObjects(dataController.managedObjectContext) {
      if profiles.count > 0 {
        self.profile = profiles[0]
      } else {
        print("No default profile found, creating one...")
        self.profile = Default.Profile(dataController.managedObjectContext)
      }
    } else {
      print("Error getting profile")
      return
    }
    
    
    bleManager = BleManager(managerStateErrorHandler: self.bleManagerStateChange, keyMaterial: profile.keyMaterial)

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
  
  
  func createPairedToken(fromToken token: Token) -> CDPairedToken {
    let pairedToken : CDPairedToken = createCDObject(dataController.managedObjectContext)
    
    pairedToken.creation = NSDate()
    pairedToken.identifier = token.identifier
    return pairedToken
  }
  

  @IBAction func onPairNewPushed(sender: AnyObject) {
    showMessage("Searching Token...", hideOnTap: false, showAnnimation: true)
    
    if profile.pairedTokens.count > 0 {
      connectWithExistingToken()
    } else {
      pairWithNewToken()
    }
  }

  
  func connectWithExistingToken() {
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
  
  
  func pairWithNewToken() {
    BleManagement.pairWithNewToken(bleManager) { (token, error) in
      if let err = error {
        showError(error: err)
      } else {
        self.token = token!
        let pairedToken = self.createPairedToken(fromToken: self.token)
        self.profile.keyMaterial = self.token.keyMaterial!
        self.profile.pairedTokens = [pairedToken]
        
        // Saving profile, settings, associated token and  keys
        self.dataController.save()
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
  func onSyncToken(controller: ReadQrCodeViewController, token: Token?) {
    if token != nil {
      self.token = token!
      let pairedToken = createPairedToken(fromToken: self.token)
      profile.pairedTokens.insert(pairedToken)
      
      // Saving profile, settings, associated token and  keys
      self.dataController.save()
      
      controller.stop()
      controller.dismissViewControllerAnimated(true, completion: nil)
      showMessage("Token synchronization success!") { self.performSegueWithIdentifier("showNavigationSegue", sender: self) }
      return
    }

    controller.stop()
    controller.dismissViewControllerAnimated(true, completion: nil)
  }
  

  // MARK: - Navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let identifier = segue.identifier {
      switch identifier {
      case "showNavigationSegue":
        let navigationVC = segue.destinationViewController as! UINavigationController
        let accountsNavigationVC = navigationVC.childViewControllers[0] as! AccountsTableViewController
        accountsNavigationVC.dataController = dataController
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
