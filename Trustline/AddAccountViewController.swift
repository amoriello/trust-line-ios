//
//  AddAccountViewController.swift
//  Trustline
//
//  Created by matt on 07/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit
import SwiftSpinner


protocol AddAccountDelegate {
  func accoundAdded(controller: AddAccountViewController, newAccount: Account)
}

class AddAccountViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
  @IBOutlet weak var picker: UIPickerView!
  @IBOutlet weak var accountName: UITextField!
  @IBOutlet weak var login: UITextField!

  var delegate: AddAccountDelegate?
  
  var settings: CDSettings!
  var token: Token2!
  var strengths: [CDStrength]!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    strengths = Array(settings.strengths)
    strengths.sortInPlace { $0.nbChars < $1.nbChars }
    
    // Do any additional setup after loading the view.
    picker.selectRow(1, inComponent: 0, animated: false)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  
  // MARK - UIPickerDatasource and Delegate
  func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return strengths.count
  }
  
  func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    let strength = strengths[row]
    return strength.pickerDescription
  }
  
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  
  @IBAction func onGenerate(sender: AnyObject) {
    let accountTitle = accountName.text!;
    let accountLogin = login.text
    let row = picker.selectedRowInComponent(0);
    let strength = strengths[row]

    if token == nil {
      showMessage("No token connected")
      return
    }

    showMessage("Creating a password", subtitle: "This could take some time...", hideOnTap: false, showAnnimation: true)
    
    token.createPassword(UInt8(strength.nbChars)) { (data, error) -> (Void) in
      if let err = error {
        showError("Wowww", error: err)
      } else {
        hideMessage()
        print("############ Password Data: ")
        print(data)
        print(data.count)
        print("############################")
        let newAccount = Account(title: accountTitle, password: data, login: accountLogin)
        if self.delegate != nil {
          self.delegate?.accoundAdded(self, newAccount: newAccount)
        }
        
      }
    }
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
