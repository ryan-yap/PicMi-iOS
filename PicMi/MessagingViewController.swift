//
//  MessagingViewController.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-03-31.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit
import Socket_IO_Client_Swift

class OwnMessageCell : UITableViewCell {
    @IBOutlet var cellmesssage : UILabel!
    @IBOutlet var cellbubble: UIImageView!
    
    func loadItem(#message: String) {
        self.cellmesssage.text = message
        self.cellmesssage.numberOfLines = 0
        self.cellmesssage.lineBreakMode = NSLineBreakMode.ByWordWrapping
        //self.cellmesssage.sizeToFit()
        //self.frame.size.height = self.cellmesssage.frame.size.height + 20
        //self.cellbubble.frame.size.height = self.cellmesssage.frame.size.height + 20
        //self.sizeToFit()
    }
}

class TargetMessageCell : UITableViewCell {
    @IBOutlet var cellmesssage : UILabel!
    
    @IBOutlet var cellbubble: UIImageView!
    func loadItem(#message: String) {
        self.cellmesssage.text = message
        self.cellmesssage.numberOfLines = 0
        self.cellmesssage.lineBreakMode = NSLineBreakMode.ByWordWrapping
        //self.cellmesssage.sizeToFit()
        //self.frame.size.height = self.cellmesssage.frame.size.height + 20
        //self.cellbubble.frame.size.height = self.cellmesssage.frame.size.height + 20
        //self.sizeToFit()
    }
}

class MessagingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate{
    
    @IBOutlet var messagelog: UITableView!
    @IBOutlet var messagetextfield: UITextField!
    @IBOutlet var username: UILabel!
    @IBOutlet var typebarview: UIView!
    var type : String = ""
    var IndexPath : NSIndexPath = NSIndexPath()
    var didcancel : Bool = false
    var JobID : String = ""
    @IBAction func back(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func ReceivedMessage(notification: NSNotification){
        println("Message Notification")
        self.messagelog.reloadData()
    }
    
    @IBAction func send_message(){
        if(self.messagetextfield.text != ""){
            self.messagetextfield.text.isEmpty
            var dict : Dictionary = Dictionary<String, String>()
            if(self.type == "job"){
                dict["target_id"] = (jobs_list[IndexPath.row] as! Jobs).request_dict["requester_id"]
                dict["jobID"] = (jobs_list[IndexPath.row] as! Jobs).request_dict["jobID"]
                dict["type"] = "request"
                dict["message"] = "\(self.messagetextfield.text)"
                
                var target_id = dict["target_id"]!
                var jobID = dict["jobID"]!
                var type = dict["type"]!
                var message = dict["message"]!
                
                (jobs_list[IndexPath.row] as! Jobs).message.addObject(dict)
                dispatch_socket.emit("send", "\(target_id):!$)$@)!$:\(jobID):!$)$@)!$:\(type):!$)$@)!$:\(app_user.username):!$)$@)!$:\(message)" )
                self.messagelog.reloadData()
            }else if (self.type == "request"){
                dict["target_id"] = (requests_list[IndexPath.row] as! Requests).request_dict["key"]
                dict["jobID"] = (requests_list[IndexPath.row] as! Requests).request_dict["jobID"]
                dict["type"] = "job"
                dict["message"] = "\(self.messagetextfield.text)"
                
                var target_id = dict["target_id"]!
                var jobID = dict["jobID"]!
                var type = dict["type"]!
                var message = dict["message"]!
                
                (requests_list[IndexPath.row] as! Requests).message.addObject(dict)
                dispatch_socket.emit("send", "\(target_id):!$)$@)!$:\(jobID):!$)$@)!$:\(type):!$)$@)!$:\(app_user.username):!$)$@)!$:\(message)" )
                println("\(target_id):!$)$@)!$:\(jobID):!$)$@)!$:\(type):!$)$@)!$:\(message)")
                self.messagelog.reloadData()
            }
            self.messagetextfield.text = ""
            if (self.type == "job"){
                self.messagelog.scrollToRowAtIndexPath(NSIndexPath(forRow: (jobs_list[IndexPath.row] as! Jobs).message.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }else if(self.type == "request"){
                self.messagelog.scrollToRowAtIndexPath(NSIndexPath(forRow: (requests_list[IndexPath.row] as! Requests).message.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        }
    }
    
    func ShowKeyboard(notification: NSNotification) {
        let info  = notification.userInfo!
        let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]!
        
        let rawFrame = value.CGRectValue()
        let keyboardFrame = view.convertRect(rawFrame, fromView: nil)
        if (self.type == "job"){
            if((jobs_list[IndexPath.row] as! Jobs).message.count != 0){
                self.messagelog.scrollToRowAtIndexPath(NSIndexPath(forRow: (jobs_list[IndexPath.row] as! Jobs).message.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        }else if(self.type == "request"){
            if((requests_list[IndexPath.row] as! Requests).message.count != 0){
                self.messagelog.scrollToRowAtIndexPath(NSIndexPath(forRow: (requests_list[IndexPath.row] as! Requests).message.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
            
        }
        
    }
    
    func HideKeyboard(notification: NSNotification) {
        let info  = notification.userInfo!
        let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]!
        
        let rawFrame = value.CGRectValue()
        let keyboardFrame = view.convertRect(rawFrame, fromView: nil)
        
        if (self.type == "job"){
            if((jobs_list[IndexPath.row] as! Jobs).message.count != 0){
                self.messagelog.scrollToRowAtIndexPath(NSIndexPath(forRow: (jobs_list[IndexPath.row] as! Jobs).message.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        }else if(self.type == "request"){
            if((requests_list[IndexPath.row] as! Requests).message.count != 0){
                self.messagelog.scrollToRowAtIndexPath(NSIndexPath(forRow: (requests_list[IndexPath.row] as! Requests).message.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        
        }
        
    }
    
    func OnPhotoRequest(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        var index = data["index"] as! Int
        let alertController = UIAlertController(title: "You Just Received A Photo Request!" as String!, message: nil,   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "View it", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            let vc = self.storyboard!.instantiateViewControllerWithIdentifier("DriverSummary") as! DriverSummaryViewController
            vc.request_index = index
            self.presentViewController(vc, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Decline", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            var request = ((dispatch.jobs_buff[index]) as! Jobs).request_dict
            var driver_id = request["driver_id"]!
            var jobID = request["jobID"]!
            var requester_id = request["requester_id"]!
            var message = "\(requester_id):!$)$@)!$:\(driver_id):!$)$@)!$:\(jobID)"
            dispatch_socket.emit("declinerequest", message)
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnPhotoResponse(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        var index = data["index"] as! Int
        let alertController = UIAlertController(title: "You have just received a response" as String!, message: nil,   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "View it", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MediaReview") as! MediaReviewViewController
            vc.response_index = index
            self.presentViewController(vc, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Later", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnRequestPicmiDriverFailure(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        println(data)
        var jobID : String = data["jobID"] as! String
        
        if (self.JobID == jobID){
            self.didcancel = true
            self.dismissViewControllerAnimated(true, completion: nil)
            return
        }
    
        let alertController = UIAlertController(title: "Driver Not Found" as String!, message: "Please try again later",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    
    func OnJobCancelled(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        var jobID : String = data["jobID"] as! String
        println(data)

        if (self.JobID == jobID){
            self.didcancel = true
            self.dismissViewControllerAnimated(true, completion: nil)
            return
        }

        let alertController = UIAlertController(title: "Job Cancelled by user" as String!, message: "This job will be removed from your list",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil ))
        self.presentViewController(alertController, animated: true, completion: nil)
     
    }
    
    func OnTransactionEnded(notification: NSNotification){
        self.messagelog.reloadData()
    }
    
    override func viewDidLoad() {
        println("View DID LOAD")
        self.didcancel = false
        self.messagelog.separatorColor = UIColor.clearColor()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "ReceivedMessage:", name: "MessageReceiveNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestPicmiDriverFailure:", name: "RequestPicMiDriverFailure", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnJobCancelled:", name: "JobCancelled", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "ShowKeyboard:", name: UIKeyboardWillShowNotification, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "HideKeyboard:", name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoRequest:", name: "PhotoRequest", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoResponse:", name: "PhotoResponse", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnTransactionEnded:", name: "transactionended", object: nil)
        self.messagelog.rowHeight = UITableViewAutomaticDimension
        if (self.type == "job"){
            self.JobID = (jobs_list[IndexPath.row] as! Jobs).request_dict["jobID"]! as String
        }else if(self.type == "request"){
            self.JobID = (requests_list[IndexPath.row] as! Requests).request_dict["jobID"]! as String
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        if (self.didcancel == false){
            if (self.type == "job"){
                (jobs_list[IndexPath.row] as! Jobs).unread = false
                (jobs_list[IndexPath.row] as! Jobs).isNotified = false
            }else if(self.type == "request"){
                (requests_list[IndexPath.row] as! Requests).unread = false
                (requests_list[IndexPath.row] as! Requests).isNotified = false
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if (self.type == "job"){
            (jobs_list[IndexPath.row] as! Jobs).unread = false
            (jobs_list[IndexPath.row] as! Jobs).isNotified = false
        }else if(self.type == "request"){
            (requests_list[IndexPath.row] as! Requests).unread = false
            (requests_list[IndexPath.row] as! Requests).isNotified = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView,numberOfRowsInSection section:    Int) -> Int {
        
        if (self.type == "job"){
            return (jobs_list[IndexPath.row] as! Jobs).message.count
        }else if(self.type == "request"){
            return (requests_list[IndexPath.row] as! Requests).message.count
        }
        return 0
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.messagetextfield.resignFirstResponder()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var stringcount : Int = 0
        var message : String = ""
        
        if (self.type == "job"){
            
            if (((jobs_list[IndexPath.row] as! Jobs).message[indexPath.row] as! Dictionary<String, String>)["type"] == "completetransaction"){
                return 89
            }
            
            if (((jobs_list[IndexPath.row] as! Jobs).message[indexPath.row] as! Dictionary<String, String>)["target_id"] != app_user.ID){
                message = ((jobs_list[IndexPath.row] as! Jobs).message[indexPath.row] as! Dictionary<String, String>)["message"]! as String
            }else{
                
                message = ((jobs_list[IndexPath.row] as! Jobs).message[indexPath.row] as! Dictionary<String, String>)["message"]! as String
            }
        }else if(self.type == "request"){
            
            if (((requests_list[IndexPath.row] as! Requests).message[indexPath.row] as! Dictionary<String, String>)["type"] == "completetransaction"){
                return 89
            }
            
            if (((requests_list[IndexPath.row] as! Requests).message[indexPath.row] as! Dictionary<String, String>)["target_id"] != app_user.ID){
                message = ((requests_list[IndexPath.row] as! Requests).message[indexPath.row] as! Dictionary<String, String>)["message"]! as String
            }else{
                message = ((requests_list[IndexPath.row] as! Requests).message[indexPath.row] as! Dictionary<String, String>)["message"]! as String
            }
        }
        
        stringcount = count(message)
        var height = CGFloat((17 * (stringcount/20)) + 89)
        println(height)
        return height
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        println("load")
        
        if (self.type == "job"){
            if (((jobs_list[IndexPath.row] as! Jobs).message[indexPath.row] as! Dictionary<String, String>)["type"] == "completetransaction"){
                var cell = tableView.dequeueReusableCellWithIdentifier("transactioncompletecell") as! UITableViewCell
                return cell
            }
            
            if (((jobs_list[IndexPath.row] as! Jobs).message[indexPath.row] as! Dictionary<String, String>)["target_id"] != app_user.ID){
                var cell = tableView.dequeueReusableCellWithIdentifier("OwnMessageReusableCell") as! (OwnMessageCell)
                cell.loadItem(message: ((jobs_list[IndexPath.row] as! Jobs).message[indexPath.row] as! Dictionary<String, String>)["message"]!)
                return cell
            }else{
                var cell = tableView.dequeueReusableCellWithIdentifier("TargetMessageReusableCell") as! (TargetMessageCell)
                cell.loadItem(message: ((jobs_list[IndexPath.row] as! Jobs).message[indexPath.row] as! Dictionary<String, String>)["message"]!)
                return cell
            }
        }else if(self.type == "request"){
            
            if (((requests_list[IndexPath.row] as! Requests).message[indexPath.row] as! Dictionary<String, String>)["type"] == "completetransaction"){
                var cell = tableView.dequeueReusableCellWithIdentifier("transactioncompletecell") as! UITableViewCell
                return cell
            }
            
            if (((requests_list[IndexPath.row] as! Requests).message[indexPath.row] as! Dictionary<String, String>)["target_id"] != app_user.ID){
                var cell = tableView.dequeueReusableCellWithIdentifier("OwnMessageReusableCell") as! (OwnMessageCell)
                cell.loadItem(message: ((requests_list[IndexPath.row] as! Requests).message[indexPath.row] as! Dictionary<String, String>)["message"]!)
                return cell
            }else{
                var cell = tableView.dequeueReusableCellWithIdentifier("TargetMessageReusableCell") as! (TargetMessageCell)
                cell.loadItem(message: ((requests_list[IndexPath.row] as! Requests).message[indexPath.row] as! Dictionary<String, String>)["message"]!)
                return cell
            }
        }
        var cell = UITableViewCell()
        return cell
    }
}
