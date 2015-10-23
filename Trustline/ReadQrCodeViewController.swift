//
//  ReadQrCodeViewController.swift
//  Trustline
//
//  Created by matt on 18/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import AVFoundation

protocol ReadKeyMaterialDelegate {
  func onSyncToken(controller: ReadQrCodeViewController, token: Token2?, readKeyMaterial: KeyMaterial?)
}


class ReadQrCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  var delegate :ReadKeyMaterialDelegate!
  
  var captureSession: AVCaptureSession?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  var qrCodeFrameView: UIView?
  
  var bleManager :BleManager2!
  // This one is meant to be found and set in this viewController
  var token :Token2?
  var readKeyMaterial :KeyMaterial?
  
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var infoLabel: UILabel!
  

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    BleManagement.findAndConnectToken(bleManager) { (token, error) -> (Void) in
      if let err = error {  // Cannot find any token
        showError(error: err) { self.delegate.onSyncToken(self, token: nil, readKeyMaterial: nil) }
      } else {
        self.token = token
        showMessage("Scan QrCode") { self.startCapture() }
      }
    }
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  private func startCapture() {
    let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    
    if let input = try? AVCaptureDeviceInput(device: captureDevice) {
      initializeCaptureDevice(input)
    } else {
      let err = createError("Camera error", description: "Cannot initialize camera")
      showError(error: err) {self.delegate.onSyncToken(self, token: nil, readKeyMaterial: nil)}
    }
  }
  
  
  func initializeCaptureDevice(input: AVCaptureDeviceInput) {
    // Initialize captureSession Object
    captureSession = AVCaptureSession()
    
    // Set the input device on the capture session
    captureSession?.addInput(input)
    
    // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session
    let captureMetadataOutput = AVCaptureMetadataOutput()
    captureSession?.addOutput(captureMetadataOutput)
    
    // Set delegate and use the default dispatch queue to execute the call back
    captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
    captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
    
    // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
    videoPreviewLayer?.frame = view.layer.bounds
    view.layer.addSublayer(videoPreviewLayer!)
    
    captureSession?.startRunning()
    view.bringSubviewToFront(cancelButton)
    view.bringSubviewToFront(infoLabel)
    
    // Initialize QR Code Frame to highlight the QR code
    qrCodeFrameView = UIView()
    qrCodeFrameView?.layer.borderColor = UIColor.greenColor().CGColor
    qrCodeFrameView?.layer.borderWidth = 2
    view.addSubview(qrCodeFrameView!)
    view.bringSubviewToFront(qrCodeFrameView!)
  }
  
  
  func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
    if metadataObjects == nil || metadataObjects.count == 0 {
      qrCodeFrameView?.frame = CGRectZero
      infoLabel.text = "No trustline data found"
      return
    }
    
    let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
    
    if metadataObj.type == AVMetadataObjectTypeQRCode {
      let codeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj) as! AVMetadataMachineReadableCodeObject
      qrCodeFrameView?.frame = codeObject.bounds
      
      if let data = metadataObj.stringValue {
        if let keyMaterial = KeyMaterial(fromBase64: data) {
          infoLabel.text = "Trustline secret data found"
          self.readKeyMaterial = keyMaterial
          syncToken(token!, readKeyMaterial: readKeyMaterial!)
          captureSession?.stopRunning()
        }
      }
    }
  }
  
  func stop() {
    captureSession?.stopRunning()
  }
  
  private func syncToken(token: Token2, readKeyMaterial: KeyMaterial) {
    showMessage("Synchronizing...", hideOnTap: false, showAnnimation: true);
    token.resetNewKeys(keyMaterialFromQrCode: readKeyMaterial) { (error) -> (Void) in
      if let err = error {
        showError(error: err) { self.delegate.onSyncToken(self, token: nil, readKeyMaterial: nil) }
      } else {
        print("|||||||||||||||||||||||||||||||||||| readKeyMaterial")
        token.setKeyMaterial(readKeyMaterial)
        print("|||||||||||||||||||||||||||||||||||| endReadKeyMaterial")
        
        token.pair({ (error) -> (Void) in
          self.delegate.onSyncToken(self, token: token, readKeyMaterial: readKeyMaterial)
        })
      }
    }
  }
  
  
  @IBAction func onCancel(sender: AnyObject) {
    captureSession?.stopRunning()
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  
  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
  }
  */
}
