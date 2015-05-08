
//
//  JobsListViewController.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-14.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit

class RequestsListTableViewCell : UITableViewCell {
    @IBOutlet var cellpicture : UIImageView!
    @IBOutlet var cellmesssage : UILabel!
    @IBOutlet var subjecttype: UIImageView!
    @IBOutlet var messageicon: UIImageView!
    
    func loadItem(#picture: UIImage, message: String, type : String, unread : Bool) {
        if (picture != ""){
            cellpicture.image = picture
        }else{
            cellpicture.image = UIImage(named: "picmi_icon.png")
        }
        
        switch (type){
        case("place"):
            self.subjecttype.image = UIImage(named: "placegreenicon.png")
        case("thing"):
            self.subjecttype.image = UIImage(named: "thinggreenicon.png")
        case("person"):
            self.subjecttype.image = UIImage(named: "guygreenicon.png")
        default:
            self.subjecttype.image = UIImage(named: "placegreenicon.png")
        }
        
        if (unread){
            self.messageicon.hidden = false
        }else{
            self.messageicon.hidden = true
        }
        
        cellmesssage.text = message
        
    }
}

class RequestsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    
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
        let alertController = UIAlertController(title: "Driver Not Found" as String!, message: "Please try again later",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            self.tableView.reloadData()
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnJobCancelled(notification: NSNotification){
        self.tableView.reloadData()
        let alertController = UIAlertController(title: "Job Cancelled by user" as String!, message: "This job will be removed from your list",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil ))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func ReceivedMessage(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        println(data)
        var index = (data["index"] as! String).toInt()
        var type = data["type"] as! String
        var username = data["username"] as! String
        var message = data["message"] as! String
        if (type == "job"){
            if((jobs_list[index!] as! Jobs).isNotified == false && self.presentedViewController == nil){
                (jobs_list[index!] as! Jobs).isNotified = true
                let alertController = UIAlertController(title: username, message: message,   preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Reply", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
                    let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MessagingController") as! MessagingViewController
                    vc.type = "job"
                    vc.IndexPath = NSIndexPath(forRow: index!, inSection: 0)
                    self.presentViewController(vc, animated: true, completion: nil)
                }))
                alertController.addAction(UIAlertAction(title: "Later", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }else if(type == "request"){
            if((requests_list[index!] as! Requests).isNotified == false && self.presentedViewController == nil){
                println(self.presentedViewController)
                (requests_list[index!] as! Requests).isNotified = true
                let alertController = UIAlertController(title: username, message: message,   preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Reply", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
                    let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MessagingController") as! MessagingViewController
                    vc.type = "request"
                    vc.IndexPath = NSIndexPath(forRow: index!, inSection: 0)
                    self.presentViewController(vc, animated: true, completion: nil)
                }))
                alertController.addAction(UIAlertAction(title: "Later", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func OnTransactionEnded(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        let alertController = UIAlertController(title: "Transaction Ended" as String!, message: nil,   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoRequest:", name: "PhotoRequest", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestPicmiDriverFailure:", name: "RequestPicMiDriverFailure", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnJobCancelled:", name: "JobCancelled", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoResponse:", name: "PhotoResponse", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "ReceivedMessage:", name: "MessageReceiveNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnTransactionEnded:", name: "transactionended", object: nil)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func back(){
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView,numberOfRowsInSection section:    Int) -> Int {
        println(requests_list.count)
        return requests_list.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("Requestslisttableviewcellidentifier") as! RequestsListTableViewCell
        var tempimage : UIImage = UIImage()
        var tempmessage : String = ""
        var temptype : String = ""
        var tempunread : Bool = false
        println(requests_list)
        if let request = requests_list[indexPath.row] as? Requests {
            println(request)
            if (request.requests_pics_urls.count != 0){
                if ((request.requests_pics_urls[0] as! Media).type == "image"){
                    tempimage = (request.requests_pics_urls[0] as! Media).image
                }else if((request.requests_pics_urls[0] as! Media).type == "video"){
                    tempimage = UIImage(named: "video.png")!
                }
            }else{
                tempimage = UIImage(named: "picmi_icon.png")!
            }
            
            if(request.request_dict["message"] != nil){
                tempmessage = (request.request_dict["message"])!
            }else{
                tempmessage = ""
            }
            
            if(request.request_dict["objecttype"] != nil){
                temptype = (request.request_dict["objecttype"])!
            }else{
                temptype = ""
            }
            
            tempunread = request.unread
        }
        cell.loadItem(picture: tempimage, message: tempmessage, type: temptype, unread : tempunread)
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if let request = requests_list[indexPath.row] as? Requests{
                var driver_id = request.request_dict["key"]!
                var jobID = request.request_dict["jobID"]!
                var requester_id = request.request_dict["requester_id"]!
                var message = "\(driver_id):!$)$@)!$:\(requester_id):!$)$@)!$:\(jobID)"
                if (request.isCompleted == false){
                    dispatch_socket.emit("cancelrequest", message)
                }
                requests_list.removeObjectAtIndex(indexPath.row)
                NSNotificationCenter.defaultCenter().postNotificationName("NewRequest", object: nil)
            }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        println("To requestitem summary")
        println(segue.identifier)
        if (segue.identifier == "RequestsListItemSegue"){
            let index = tableView.indexPathForCell(sender as! RequestsListTableViewCell)!
            println(index.row)
            (segue.destinationViewController as! RequestsListItemViewController).IndexPath = index
        }
    }
    
}
