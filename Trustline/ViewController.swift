//
//  ViewController.swift
//  Trustline
//
//  Created by matt on 04/10/2015.
//  Copyright © 2015 amoriello.hutti. All rights reserved.
//

import UIKit


class ViewController: UIViewController, UITableViewDataSource {

  // MARK: - IBOutlet
  
  @IBOutlet weak var tableView: UITableView!
  
  
  // MARK: - Variables
  var token :Token!;

  
  // Model for the tableView
  var items = [String]()
  
  
  
  // MARK: - VC Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    // Set the title for the tableView
    title = "Trustline"
    
    // Register the UITableViewCell class with the tableView. Dequeue a cell with
    // the reuse identifier
    tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell");
    
    
    /*
    token = Token(handler: self.OnConnectedStateUpdate, connected: { (state, message) -> (Void) in
      self.token.PairWithDevice { (error) -> (Void) in
        var message = "";
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil);
        
        if let err = error {
          message = err.description;
         
        } else {
          message = "Device paired succesfuly"
        }
        
        print(message)
        
        let alert = UIAlertController(title: "Device Link Info", message: message, preferredStyle: .Alert)
        alert.addAction(action);

        self.presentViewController(alert, animated: true, completion: nil)
      }
    })
    */

  }
  
  
  func OnConnectedStateUpdate(state: Token.ConnectedState, message: String?) {
    print("Token connected state changed");
  }
  

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  
  // MARK: - UITableViewDataSource
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell")! as UITableViewCell
    
    cell.textLabel!.text = items[indexPath.row]
    return cell;
  }
  
  
  // MARK: - IBAction
  
  
  func addItemDisplayAlert(cipheredPassword: [UInt8]) {
    // Create an alertView
    let alert = UIAlertController(title: "Add Password", message: "Add a new password", preferredStyle: .Alert);
    
    // Create a save action
    let saveAction = UIAlertAction(title: "Save", style: .Default) { (action) -> Void in
      // Add the item from the first textField in alertView to the self.items container
      let textField = alert.textFields![0] as UITextField
      self.items.append(textField.text!)
      self.tableView.reloadData()
    }
    
    // Create a cancel action
    let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil);
    
    
    // Add the textField and two above actions
    alert.addTextFieldWithConfigurationHandler(nil)
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    // present the alertView
    presentViewController(alert, animated: true, completion: nil)
  }
  
  
  func onPasswordCreated(cipheredPassword: [UInt8], error: NSError?) {
    if let _ = error {
      return;
    }
    
    addItemDisplayAlert(cipheredPassword);
  }
  
  
  @IBAction func addItem(sender: AnyObject) {
    token.CreatePassword(15, handler: self.onPasswordCreated)
  }

}

