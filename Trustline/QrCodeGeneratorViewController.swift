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
  
  var settings: TrustLineSettings!
  var keyMaterial: KeyMaterial!
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
    

  func generateQrCode(keyMaterial: KeyMaterial) -> UIImage {
    // generate qrcode image
    let qrFilter = CIFilter(name: "CIQRCodeGenerator")!
    qrFilter.setDefaults()
    let keyMaterialData = keyMaterial.rawData()
    let data = NSData(bytes: keyMaterialData, length: keyMaterialData.count)
    qrFilter.setValue(data, forKey: "inputMessage")
    
    
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
        accountsNavigationVC.settings = settings

      default: break;
      }
    }
  }
}
