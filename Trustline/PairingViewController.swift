//
//  PairingViewController.swift
//  Trustline
//
//  Created by matt on 16/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit

class PairingViewController: UIViewController, ReadKeyMaterialDelegate {
  var bleManager :BleManager2!
  var token :Token2!
  var keyMaterial = KeyMaterial()
  var settings = TrustLineSettings()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    bleManager = BleManager2(managerStateErrorHandler: self.bleManagerStateChange, keyMaterial: keyMaterial)

    if settings.isPaired {
      showMessage("Searching Token...", hideOnTap: false, showAnnimation: true)
      BleManagement.connectToPairedToken(bleManager, pairedDevice: settings.pairedDevice!) { (token, error) in
        if let err = error {
          showError(error: err)
        } else {
          self.token = token!
          showMessage("Connected!", tapAction: {self.performSegueWithIdentifier("showNavigationSegue", sender: self)})
        }
      }
    }
  }
  

  @IBAction func onPairNewPushed(sender: AnyObject) {
    showMessage("Searching Tokens...", hideOnTap: false, showAnnimation: true)
    
    BleManagement.pairWithNewToken(bleManager) { (token, error) in
      if let err = error {
        showError(error: err)
      } else {
        self.token = token!
        showMessage("Token Paired and Ready", tapAction: {self.performSegueWithIdentifier("showQRGenerator", sender: self)})
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
  func keyMaterialRead(controller: ReadQrCodeViewController, readKeyMaterial: KeyMaterial) {
    self.keyMaterial = readKeyMaterial
    controller.stop()
    controller.dismissViewControllerAnimated(true, completion: nil)
    // Todo : find the token around, pair with this keyMaterial.
    // Only show showNavigationSegue when a Token is paired
    showMessage("Yeah!")
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
        accountsNavigationVC.settings = settings
        
      case "showQRGenerator":
        let qrCodeGeneratorVC = segue.destinationViewController as! QrCodeGeneratorViewController
        qrCodeGeneratorVC.keyMaterial = keyMaterial
        qrCodeGeneratorVC.settings = settings
        qrCodeGeneratorVC.token = token
        
      case "showQrReader":
        let readQrVC = segue.destinationViewController as! ReadQrCodeViewController
        readQrVC.delegate = self
        
      default: break;
      }
    }
  }

}
