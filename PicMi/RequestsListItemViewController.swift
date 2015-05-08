//
//  SummaryViewController.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-07.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreLocation

class RequestsListItemImagesViewCell : UICollectionViewCell {
    @IBOutlet var Picture : UIImageView!
    func loadItem(#image: Media) {
        if (image.type == "image"){
            Picture.image = image.image;
        }else if(image.type == "video"){
            Picture.image = UIImage(named : "video.png")
        }
        Picture.frame = CGRectMake(15,10,80,80);
    }
}

class RequestsListItemViewController: UIViewController,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet var request_message: UITextView!
    @IBOutlet var uploaded_images: UICollectionView!
    @IBOutlet var thingicon: UIImageView!
    @IBOutlet var placeicon: UIImageView!
    @IBOutlet var guyicon: UIImageView!
    var IndexPath : NSIndexPath = NSIndexPath()
    let picker = UIImagePickerController()
    
    @IBAction func hide_keyboard(){
        request_message.resignFirstResponder();
    }
    
    func showguyicon(){
        self.thingicon.hidden = true;
        self.placeicon.hidden = true;
        self.guyicon.hidden = false;
    }
    
    func showthingicon(){
        self.thingicon.hidden = false;
        self.placeicon.hidden = true;
        self.guyicon.hidden = true;
    }
    
    func showplaceicon(){
        self.thingicon.hidden = true;
        self.placeicon.hidden = false;
        self.guyicon.hidden = true;
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
    
    func OnJobCancelled(notification: NSNotification){
        let alertController = UIAlertController(title: "Job Cancelled by user" as String!, message: "This job will be removed from your list",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil ))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnRequestPicmiDriverFailure(notification: NSNotification){
        let alertController = UIAlertController(title: "Driver Not Found" as String!, message: "Please try again later",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
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
        println(self.IndexPath.row)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoRequest:", name: "PhotoRequest", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoResponse:", name: "PhotoResponse", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestPicmiDriverFailure:", name: "RequestPicMiDriverFailure", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnJobCancelled:", name: "JobCancelled", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "ReceivedMessage:", name: "MessageReceiveNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnTransactionEnded:", name: "transactionended", object: nil)
        if let request = requests_list[self.IndexPath.row] as? Requests {
            if(request.request_dict["message"] != nil){
                self.request_message.text = (request.request_dict["message"])!
            }else{
                self.request_message.text = ""
            }
            
            switch (request.request_dict["objecttype"]!){
            case("place"):
                self.showplaceicon()
            case("thing"):
                self.showthingicon()
            default:
                self.showguyicon()
            }
        }
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel_request(){
        if let request = requests_list[IndexPath.row] as? Requests{
            println(request.request_dict)
            var driver_id = request.request_dict["key"]!
            var jobID = request.request_dict["jobID"]!
            var requester_id = request.request_dict["requester_id"]!
            var message = "\(driver_id):!$)$@)!$:\(requester_id):!$)$@)!$:\(jobID)"
            dispatch_socket.emit("cancelrequest", message)
            requests_list.removeObjectAtIndex(IndexPath.row)
            dismissViewControllerAnimated(true, completion: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("NewRequest", object: nil)
        }
    }
    
    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func showMap(){
        if let request = requests_list[IndexPath.row] as? Requests{
            let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController
            vc.longitude = CLLocationDegrees((request.request_dict["longitude"] as NSString!).doubleValue)
            vc.latitude = CLLocationDegrees((request.request_dict["latitude"] as NSString!).doubleValue)
            vc.location_name = request.request_dict["location_name"] as String!
            vc.type = request.request_dict["objecttype"] as String!
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count : Int = 0
        if let request = requests_list[self.IndexPath.row] as? Requests {
            count = request.requests_pics_urls.count
        }
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("RequestsListItemImageCell",forIndexPath: indexPath)as! RequestsListItemImagesViewCell
        var tempimage : Media = Media()
        if let request = requests_list[self.IndexPath.row] as? Requests {
            tempimage = (request.requests_pics_urls[indexPath.row] as! Media)
        }
        cell.loadItem(image: tempimage)
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if let request = requests_list[self.IndexPath.row] as? Requests {
            if (segue.identifier == "FromRequestItemToMessageSegue"){
                println("Segueing")
                (segue.destinationViewController as! MessagingViewController).type = "request"
                (segue.destinationViewController as! MessagingViewController).IndexPath = self.IndexPath
            }
        }
    }
}
