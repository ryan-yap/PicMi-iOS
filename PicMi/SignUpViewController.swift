//
//  SignUpViewController.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-13.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet var postalcode: UITextField!
    @IBOutlet var expirationyear: UITextField!
    @IBOutlet var expirationmonth: UITextField!
    @IBOutlet var cvv: UITextField!
    @IBOutlet var creditcardnumber: UITextField!
    @IBOutlet var mobilenumber: UITextField!
    @IBOutlet var lastname: UITextField!
    @IBOutlet var firstname: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var email: UITextField!
    
    @IBAction func back(){
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func OnSignupFailure(notification: NSNotification){
        let alertController = UIAlertController(title: "Email Already Registered" as String!, message: "Please use a different email address",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil ))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnSignupSuccess(notification: NSNotification){
        NSNotificationCenter.defaultCenter().postNotificationName("LoginSuccess", object: nil)
        performSegueWithIdentifier("SignUpToLoaderSegue", sender: nil)
    }
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnSignupFailure:", name: "SignupFailure", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnSignupSuccess:", name: "SignupSuccess", object: nil)
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func hide_keyboard(){
        postalcode.resignFirstResponder();
        expirationmonth.resignFirstResponder();
        expirationyear.resignFirstResponder();
        cvv.resignFirstResponder();
        creditcardnumber.resignFirstResponder();
        mobilenumber.resignFirstResponder();
        lastname.resignFirstResponder();
        firstname.resignFirstResponder();
        password.resignFirstResponder();
        email.resignFirstResponder();
    }
    
    @IBAction func signup(){
        app_user.signup(self.email.text, password: self.password.text, firstname: self.firstname.text, lastname: self.lastname.text, mobile_number: self.mobilenumber.text, card_number: self.creditcardnumber.text, cvv: self.cvv.text, exp_date: "\(self.expirationmonth.text)\(self.expirationyear.text)", postal_code: self.postalcode.text, isUser: true, isDriver: true)
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
