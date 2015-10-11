//
//  AddAccountViewController.swift
//  Trustline
//
//  Created by matt on 07/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit


protocol AddAccountDelegate {
  func accoundAdded(controller: AddAccountViewController, newAccount: Account)
}

class AddAccountViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
  @IBOutlet weak var picker: UIPickerView!
  @IBOutlet weak var accountName: UITextField!
  @IBOutlet weak var login: UITextField!

  var delegate: AddAccountDelegate?
  
  var settings :TrustLineSettings!
  var token: Token2!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
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
    return settings.strengths.count;
  }
  
  func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    let strength = settings.strengths[row];
    return strength.description;
  }
  
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  
  @IBAction func onGenerate(sender: AnyObject) {
    let accountTitle = accountName.text!;
    let accountLogin = login.text
    let row = picker.selectedRowInComponent(0);
    let strengthValue = settings.strengths[row].nbCharacters

    if token == nil {
      print("No token connected");
      return
    }
    
    token.createPassword(strengthValue) { (data, error) -> (Void) in
      if let err = error {
        print("Error Creating password: \(err.description)")
      } else {
        print("Password succesfully created: \(data)")
        let newAccount = Account(title: accountTitle, password: data, login: accountLogin)
        
        if let _ = self.delegate {
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
