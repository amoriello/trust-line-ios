//
//  QrCodeGeneratorViewController.swift
//  Trustline
//
//  Created by matt on 18/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit

class QrCodeGeneratorViewController: UIViewController {
  
  @IBOutlet weak var codeImageView: UIImageView!
  
  var profile: CDProfile!
  var keyMaterial: CDKeyMaterial!
  var token: Token2!

  override func viewDidLoad() {
    super.viewDidLoad()
    let qrCodeImage = generateQrCode(keyMaterial)
    codeImageView.image = qrCodeImage
    // Do any additional setup after loading the view.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }

  func generateQrCode(keyMaterial: CDKeyMaterial) -> UIImage {
    // generate qrcode image
    let qrFilter = CIFilter(name: "CIQRCodeGenerator")!
    qrFilter.setDefaults()
    let base64keyMaterial = keyMaterial.base64Data()
    qrFilter.setValue(base64keyMaterial, forKey: "inputMessage")
    // High correction control level
    qrFilter.setValue("H", forKey: "inputCorrectionLevel")
    
    
    let transform = CGAffineTransformMakeScale(10, 10)
    let transformedImage = qrFilter.outputImage!.imageByApplyingTransform(transform)
    
    let image = UIImage(CIImage: transformedImage)
    return image
  }
  
  
  // MARK: - Navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let identifier = segue.identifier {
      switch identifier {
      case "startUsingTrustline":
        let navigationVC = segue.destinationViewController as! UINavigationController
        let accountsNavigationVC = navigationVC.childViewControllers[0] as! AccountsTableViewController
        accountsNavigationVC.token = token
        accountsNavigationVC.profile = profile

      default: break;
      }
    }
  }
}
