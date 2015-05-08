//
//  MainViewController.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-03-20.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import MobileCoreServices
import MediaPlayer
import CoreMedia
import Alamofire
import SwiftyJSON

class LocationTableViewCell : UITableViewCell {
    @IBOutlet var Name : UILabel!
    @IBOutlet var Address : UILabel!
    
    func loadItem(#name: String, address: String) {
        self.Name.text = name
        self.Address.text = address
    }
}

class MainPageViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate, UITextViewDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    
    //===========================Constant variables===========================
    let locationManager = CLLocationManager()
    let picker = UIImagePickerController()
    var optionsidebarstatus : String = "off"
    var objecttype : String = "person"
    var places : NSMutableArray = NSMutableArray()
    var route_index: Int = 0
    
    
    
    //===========================IBOUTLETs===========================
    
    @IBOutlet var EditMessageView: UIView!
    @IBOutlet var uploadimageview: UIView!
    @IBOutlet var LocationsTable: UITableView!
    @IBOutlet var LocationTableView: UIView!
    @IBOutlet var loadingview: UIView!
    @IBOutlet var activityindicator: UIActivityIndicatorView!
    @IBOutlet var thinggreenicon: UIImageView!
    @IBOutlet var placegreenicon: UIImageView!
    @IBOutlet var guygreenicon: UIImageView!
    @IBOutlet var thingicon: UIImageView!
    @IBOutlet var placeicon: UIImageView!
    @IBOutlet var personicon: UIImageView!
    @IBOutlet var optionbuttonView: UIView!
    @IBOutlet var WaitingView: UIView!
    @IBOutlet var pin: UIImageView!
    @IBOutlet var camera_pin: UIImageView!
    @IBOutlet var located_pin: UIImageView!
    @IBOutlet var wait_minutes_label: UILabel!
    @IBOutlet var setpicturelocationbutton: UIButton!
    @IBOutlet var picmiimageview: UIImageView!
    @IBOutlet var confirmationimageview: UIImageView!
    @IBOutlet var location_name: UITextField!
    @IBOutlet var addmessagetextfield: UITextView!
    @IBOutlet var map: MKMapView!
    @IBOutlet var camera_en_route: UIImageView!
    @IBOutlet var profile_view: UIView!
    @IBOutlet var choose_objects_view: UIView!
    @IBOutlet var driver_name: UILabel!
    
    @IBOutlet var notification_icon: UIImageView!
    @IBOutlet var notification_num: UILabel!
    
    @IBOutlet var job_noti_bubble: UIImageView!
    @IBOutlet var job_num: UILabel!
    
    @IBOutlet var EditButton: UIButton!
    @IBOutlet var imagecollection: UICollectionView!
    var videoData : NSData = NSData()
    //=========================== IBACTIONs ============================================
    
    @IBAction func hideKeyboard(){
        self.location_name.resignFirstResponder()
    }
    
    @IBAction func search(){
        self.search_location()
    }
    
    @IBAction func switch_job(){
        self.map.removeOverlays(self.map.overlays)
        if(self.route_index == self.map.annotations.count){
            self.route_index = 0
        }
        
        if (self.map.annotations.count != 0){
            var annotation =  self.map.annotations[self.route_index] as! MKAnnotation
            var centre_location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(centre_location, completionHandler: {(placemarks, error)->Void in
                if (error != nil) {
                    println("Reverse geocoder failed with error" + error.localizedDescription)
                    return
                }
                
                if placemarks.count > 0 {
                    let destination_pm = placemarks[0] as! CLPlacemark
                    self.get_source_pm(destination_pm)
                } else {
                    println("Problem with the data received from geocoder")
                }
            })
            self.route_index = route_index + 1
        }
    }
    
    func search_location(){
        var search_request = MKLocalSearchRequest()
        search_request.naturalLanguageQuery = self.location_name.text
        search_request.region = self.map.region
        
        let search = MKLocalSearch(request: search_request)
        search.startWithCompletionHandler { (response, error) in
            let placemark = (response.mapItems[0] as! MKMapItem).placemark
            
            for x in response.mapItems{
                var place = (x as! MKMapItem)
                self.places.addObject(place)
            }
            self.LocationsTable.reloadData()
        }
        self.location_name.resignFirstResponder()
        self.LocationTableView.hidden = false
    }
    
    @IBAction func BackUp(){
        for x in jobs_list{
            let job = (x as! Jobs)
            for y in job.requests_pics_urls{
                let url = (y as! Url)
                println(url.urlpath)
            }
        }
    }
    
    @IBAction func optionButton(){
        if(self.optionsidebarstatus == "off"){
            self.optionbuttonView.hidden = false;
            self.optionsidebarstatus = "on"
        }else{
            self.optionbuttonView.hidden = true;
            self.optionsidebarstatus = "off"
        }
    }
    
    @IBAction func findMyLocation(sender: AnyObject) {
        self.update_location()
    }
    
    @IBAction func set_pickup_location(){
        self.picmiimageview.hidden=true;
        self.confirmationimageview.hidden=false;
        self.setpicturelocationbutton.hidden=true;
        self.choose_objects_view.hidden=true;
        self.show_message_window()
    }
    
    
    func show_message_window(){
        self.EditMessageView.hidden = false
    }
    
    @IBAction func selectperson(){
        self.personicon.hidden = false;
        self.placeicon.hidden = true;
        self.thingicon.hidden = true;
        self.guygreenicon.hidden = false;
        self.placegreenicon.hidden = true;
        self.thinggreenicon.hidden = true;
        self.objecttype = "person"
    }
    
    @IBAction func selectplace(){
        self.personicon.hidden = true;
        self.placeicon.hidden = false;
        self.thingicon.hidden = true;
        self.guygreenicon.hidden = true;
        self.placegreenicon.hidden = false;
        self.thinggreenicon.hidden = true;
        self.objecttype = "place"
    }
    
    @IBAction func selectthing(){
        self.personicon.hidden = true;
        self.placeicon.hidden = true;
        self.thingicon.hidden = false;
        self.guygreenicon.hidden = true;
        self.placegreenicon.hidden = true;
        self.thinggreenicon.hidden = false;
        self.objecttype = "thing"
    }
    
    //=======================Notification Handling==============================================
    
    func OnGetProfileSuccess(notification: NSNotification){
        let data = notification.userInfo as Dictionary!
        var firstname = data["firstname"] as! String!
        var lastname = data["lastname"] as! String!
        self.driver_name.text = "\(firstname) \(lastname)"
    }
    
    func OnGetProfileSuccessFailure(notification: NSNotification){
        self.driver_name.text = " "
    }
    
    func OnRequestConfirmed(notification: NSNotification){
        self.WaitingView.hidden = true
        self.profile_view.hidden = false
    }
    
    
    func OnRequestPicmiDriverSuccess(notification: NSNotification){
        self.camera_en_route.hidden = false
        self.confirmationimageview.hidden = true
        self.profile_view.hidden = false
        self.setpicturelocationbutton.hidden = true
        self.pin.hidden = true
        self.located_pin.hidden = false
        self.camera_pin.hidden = false
        self.wait_minutes_label.hidden = false
        println("Request Driver Success")
        var data = notification.userInfo as Dictionary!
        var distance = data["distance"] as! String!
        var time = distance.toInt()!/833
        self.wait_minutes_label.text = "\(time)"
        self.WaitingView.hidden = false
        self.map.scrollEnabled = false
    }
    
    func OnRequestCancelled(notification: NSNotification){
        self.confirmationimageview.hidden = true
        self.camera_en_route.hidden = true
        self.profile_view.hidden = true
        self.choose_objects_view.hidden = false
        self.setpicturelocationbutton.hidden = false
        self.pin.hidden = false
        self.located_pin.hidden = true
        self.camera_pin.hidden = true
        self.wait_minutes_label.hidden = true
        self.picmiimageview.hidden=false;
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
    
    func OnNewRequest(notification: NSNotification){
        dispatch.reset();
        picture.reset();
        self.map.scrollEnabled = true
        self.picmiimageview.hidden = false;
        self.optionbuttonView.hidden = true;
        self.WaitingView.hidden = true
        self.confirmationimageview.hidden = true
        self.camera_en_route.hidden = true
        self.profile_view.hidden = true
        self.choose_objects_view.hidden = false
        self.setpicturelocationbutton.hidden = false
        self.pin.hidden = false
        self.located_pin.hidden = true
        self.camera_pin.hidden = true
        self.wait_minutes_label.hidden = true
        self.picker.delegate = self
        let pin = CLLocationCoordinate2D(
            //latitude: location.latitude,
            //longitude: location.longitude
            latitude: 49.2868822,
            longitude: -123.1182794
        )
        println("\(pin.latitude) \(pin.longitude)" )
        let span = MKCoordinateSpanMake(0.0025, 0.0025)
        let region = MKCoordinateRegion(center: pin, span: span)
        self.map.setRegion(region, animated: true)
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
    
    func OnPinLocation(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        var annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(
            //latitude: location.latitude,
            //longitude: location.longitude
            latitude: CLLocationDegrees((data["latitude"] as! NSString).doubleValue),
            longitude: CLLocationDegrees((data["longitude"] as! NSString).doubleValue)
        )
        
        annotation.title = data["objecttype"] as! String
        annotation.subtitle = data["message"] as! String
        
        map.addAnnotation(annotation)
    }
    
    func OnRemoveLocation(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        println(data)
        var annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(
            //latitude: location.latitude,
            //longitude: location.longitude
            latitude: CLLocationDegrees((data["latitude"] as! NSString).doubleValue),
            longitude: CLLocationDegrees((data["longitude"] as! NSString).doubleValue)
        )
        annotation.title = data["objecttype"] as! String
        annotation.subtitle = data["message"] as! String
        map.removeAnnotations(map.annotations)
        self.route_index = 0
        for x in jobs_list{
            var temp_annotation = MKPointAnnotation()
            temp_annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(((x as! Jobs).request_dict["latitude"]! as NSString).doubleValue), longitude: CLLocationDegrees(((x as! Jobs).request_dict["longitude"]! as NSString).doubleValue))
            temp_annotation.title = (x as! Jobs).request_dict["objecttype"] as String!
            temp_annotation.title = (x as! Jobs).request_dict["message"] as String!
            
            map.addAnnotation(temp_annotation)
        }
        self.map.removeOverlays(self.map.overlays)
    }
    
    func OnCompletedTransaction(notification: NSNotification){
        self.new_request()
    }
    
    func OnRequestPicmiDriverFailure(notification: NSNotification){
        let alertController = UIAlertController(title: "Driver Not Found" as String!, message: "Please try again later",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            self.new_request()
            if(jobs_list.count == 0){
                self.notification_icon.hidden = true
                self.notification_num.hidden = true
                self.job_noti_bubble.hidden = true
                self.job_num.hidden = true
            }else{
                self.notification_icon.hidden = false
                self.notification_num.hidden = false
                self.notification_num.text = String(jobs_list.count)
                self.job_noti_bubble.hidden = false;
                self.job_num.hidden = false;
                self.job_num.text = String(jobs_list.count)
            }
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnJobCancelled(notification: NSNotification){
        let alertController = UIAlertController(title: "Job Cancelled by user" as String!, message: "This job will be removed from your list",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            self.new_request()
            if(jobs_list.count == 0){
                self.notification_icon.hidden = true
                self.notification_num.hidden = true
                self.job_noti_bubble.hidden = true
                self.job_num.hidden = true
            }else{
                self.notification_icon.hidden = false
                self.notification_num.hidden = false
                self.notification_num.text = String(jobs_list.count)
                self.job_noti_bubble.hidden = false;
                self.job_num.hidden = false;
                self.job_num.text = String(jobs_list.count)
            }
        } ))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnTransactionEnded(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        self.optionbuttonView.hidden = true;
        self.optionsidebarstatus = "off"
        if(jobs_list.count == 0){
            self.notification_icon.hidden = true
            self.notification_num.hidden = true
            self.job_noti_bubble.hidden = true
            self.job_num.hidden = true
        }else{
            self.notification_icon.hidden = false
            self.notification_num.hidden = false
            self.notification_num.text = String(jobs_list.count)
            self.job_noti_bubble.hidden = false;
            self.job_num.hidden = false;
            self.job_num.text = String(jobs_list.count)
        }
        
        let alertController = UIAlertController(title: "Transaction Ended" as String!, message: nil,   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnUpdateLocation(notification: NSNotification){
        let pin = CLLocationCoordinate2D(
            //latitude: location.latitude,
            //longitude: location.longitude
            latitude: location.latitude,
            longitude: location.longitude
        )
        println("\(pin.latitude) \(pin.longitude)" )
        let span = MKCoordinateSpanMake(0.0025, 0.0025)
        let region = MKCoordinateRegion(center: pin, span: span)
        self.map.setRegion(region, animated: true)
    }
    
    //======================= Location Functions ==============================================
    
    func startloadingview(){
        self.loadingview.hidden = false
        self.activityindicator.startAnimating()
        self.activityindicator.hidden = false
    }
    
    func stoploadingview(){
        self.loadingview.hidden = true
        self.activityindicator.stopAnimating();
        self.activityindicator.hidden = true
    }
    func update_location(){
        let pin = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        //self.map.region.center
        
        let span = MKCoordinateSpanMake(0.0025, 0.0025)
        let region = MKCoordinateRegion(center: pin, span: span)
        self.map.setRegion(region, animated: true)
    }
    
    func update_pin_location(placemark: CLPlacemark?){
        if let containsPlacemark = placemark {
            self.location_name.text = containsPlacemark.name
            location.pin_name = containsPlacemark.name
            location.pin_latitude = containsPlacemark.location.coordinate.latitude
            location.pin_longitude = containsPlacemark.location.coordinate.longitude
            dispatch.location_name = containsPlacemark.name
        }
    }
    //======================= Add Message for Driver ==============================================
    
    @IBAction func edit_images(){
        if(self.EditButton.titleLabel?.text == "Delete Mode"){
            self.EditButton.setTitle("Back", forState: .Normal)
        }else{
            self.EditButton.setTitle("Delete Mode", forState: .Normal)
        }
    }
    
    @IBAction func add_message(){
        dispatch.objecttype = self.objecttype
        self.addmessagetextfield.resignFirstResponder()
        dispatch.message = self.addmessagetextfield.text
        self.show_uploadimage_view();
 
    }
    
    @IBAction func skip_adding_message(){
        dispatch.message = ""
        self.addmessagetextfield.resignFirstResponder()
        self.show_uploadimage_view();
    }
    
    func show_uploadimage_view(){
        self.imagecollection.reloadData()
        self.EditMessageView.hidden = true
        self.uploadimageview.hidden = false
    }
    
    //======================= Opening camera to capture photo ==============================================
    
    @IBAction func go_to_photo(){
        println("Go To Photo")
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
            self.picker.sourceType = UIImagePickerControllerSourceType.Camera
            var mediaTypes: Array<AnyObject> = [kUTTypeImage]
            self.picker.mediaTypes = mediaTypes
            dismissViewControllerAnimated(true, completion: nil)
            self.presentViewController(picker, animated: true, completion: nil)
        }
        else{
            NSLog("No Camera.")
        }
    }
    
    @IBAction func go_to_video(button:UIButton){
        println("Go To Video")
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
            self.picker.sourceType = UIImagePickerControllerSourceType.Camera
            var mediaTypes: Array<AnyObject> = [kUTTypeMovie]
            self.picker.mediaTypes = mediaTypes
            dismissViewControllerAnimated(true, completion: nil)
            self.presentViewController(picker, animated: true, completion: nil)
        }
        else{
            NSLog("No Camera.")
        }
    }
    
    //======================= Opening gallery to choose photo ==============================================
    
    @IBAction func upload_picture(){
        self.uploadimageview.hidden = true
        self.show_summary();
    }
    
    @IBAction func go_to_gallery(){
        self.picker.allowsEditing = false;
        self.picker.sourceType = .PhotoLibrary
        println("Go To Gallery")
        dismissViewControllerAnimated(true, completion: nil)
        presentViewController(self.picker, animated: true, completion: nil)//4
    }
    
    func show_summary(){
        self.performSegueWithIdentifier("to_summary_segue", sender: nil)
    }
    
    @IBAction func new_request(){
        dispatch.reset();
        picture.reset();
        self.map.scrollEnabled = true
        self.picmiimageview.hidden = false;
        self.optionbuttonView.hidden = true;
        self.WaitingView.hidden = true
        self.confirmationimageview.hidden = true
        self.camera_en_route.hidden = true
        self.profile_view.hidden = true
        self.choose_objects_view.hidden = false
        self.setpicturelocationbutton.hidden = false
        self.pin.hidden = false
        self.located_pin.hidden = true
        self.camera_pin.hidden = true
        self.wait_minutes_label.hidden = true
        self.picker.delegate = self
        self.EditMessageView.hidden = true
        self.uploadimageview.hidden = true
        let pin = CLLocationCoordinate2D(
            //latitude: location.latitude,
            //longitude: location.longitude
            latitude: 49.2868822,
            longitude: -123.1182794
        )
        println("\(pin.latitude) \(pin.longitude)" )
        let span = MKCoordinateSpanMake(0.0025, 0.0025)
        let region = MKCoordinateRegion(center: pin, span: span)
        self.map.setRegion(region, animated: true)
    }
    
    // ======================= Delegates' Methods ==============================================
    override func viewDidAppear(animated: Bool) {
        self.stoploadingview();
        self.optionbuttonView.hidden = true;
        self.optionsidebarstatus = "off"
        if(jobs_list.count == 0){
            self.notification_icon.hidden = true
            self.notification_num.hidden = true
            self.job_noti_bubble.hidden = true
            self.job_num.hidden = true
        }else{
            self.notification_icon.hidden = false
            self.notification_num.hidden = false
            self.notification_num.text = String(jobs_list.count)
            self.job_noti_bubble.hidden = false;
            self.job_num.hidden = false;
            self.job_num.text = String(jobs_list.count)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestPicmiDriverSuccess:", name: "RequestPicDriverMiSuccess", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestPicmiDriverFailure:", name: "RequestPicMiDriverFailure", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnNewRequest:", name: "NewRequest", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnJobCancelled:", name: "JobCancelled", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnGetProfileSuccess:", name: "GetProfileSuccess", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnGetProfileFailure:", name: "GetProfileFailure", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestCancelled:", name: "RequestCancelled", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoRequest:", name: "PhotoRequest", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoResponse:", name: "PhotoResponse", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnCompletedTransaction:", name: "CompletedTransaction", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestConfirmed:", name: "RequestConfirmed", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "HandleThumbnail:", name: MPMoviePlayerThumbnailImageRequestDidFinishNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPinLocation:", name: "PinLocation", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRemoveLocation:", name: "RemoveLocation", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "ReceivedMessage:", name: "MessageReceiveNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnTransactionEnded:", name: "transactionended", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnUpdateLocation:", name: "updatelocation", object: nil)
        self.LocationTableView.hidden = true
        self.EditMessageView.hidden = true
        self.uploadimageview.hidden = true
        self.imagecollection.backgroundColor = UIColor.clearColor()
        let defaults = NSUserDefaults.standardUserDefaults()
        if let jobs: NSArray = defaults.arrayForKey("jobs_list"){
            println(jobs)
            for x in jobs{
                jobs_list.addObject(x)
            }
        }
        
        if let requests: NSArray = defaults.arrayForKey("requests_list"){
            println(requests)
            for x in requests{
                requests_list.addObject(x)
            }
        }
        self.EditButton.setTitle("Delete Mode", forState: .Normal)
        self.optionbuttonView.hidden = true;
        self.WaitingView.hidden = true
        self.confirmationimageview.hidden = true
        self.camera_en_route.hidden = true
        self.profile_view.hidden = true
        self.choose_objects_view.hidden = false
        self.setpicturelocationbutton.hidden = false
        self.pin.hidden = false
        self.located_pin.hidden = true
        self.camera_pin.hidden = true
        self.wait_minutes_label.hidden = true
        self.picker.delegate = self
        self.selectperson();
        self.stoploadingview();
        let pin = CLLocationCoordinate2D(
            //latitude: location.latitude,
            //longitude: location.longitude
            latitude: 49.2868822,
            longitude: -123.1182794
        )
        println("\(pin.latitude) \(pin.longitude)" )
        let span = MKCoordinateSpanMake(0.0025, 0.0025)
        let region = MKCoordinateRegion(center: pin, span: span)
        self.map.setRegion(region, animated: true)
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        self.location_name.resignFirstResponder()
        self.LocationTableView.hidden = true
        var centre_location = CLLocation(latitude: map.centerCoordinate.latitude, longitude: map.centerCoordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(centre_location, completionHandler: {(placemarks, error)->Void in
            if (error != nil) {
                println("Reverse geocoder failed with error" + error.localizedDescription)
                return
            }
            
            if placemarks.count > 0 {
                let pm = placemarks[0] as! CLPlacemark
                self.update_pin_location(pm)
            } else {
                println("Problem with the data received from geocoder")
            }
        })
    }
    
    func mapView(mapView: MKMapView!, regionWillChangeAnimated animated: Bool) {
        self.location_name.resignFirstResponder()
        self.LocationTableView.hidden = true
        self.optionbuttonView.hidden = true;
        self.optionsidebarstatus = "off"
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        var mediaType : String = info[UIImagePickerControllerMediaType] as! String
        println(mediaType)
        if (mediaType == "public.movie"){
            let tempImage = info[UIImagePickerControllerMediaURL] as! NSURL!
            println(tempImage.path!)
            var data = NSData(contentsOfFile: tempImage.path!)!
            var media = Media(temptype: "video", tempdata: data, tempurl: tempImage)
            dispatch.requests_media_list.addObject(media)
            dismissViewControllerAnimated(true, completion: nil);
            self.imagecollection.reloadData()
            //self.upload_picture()
            //self.performSegueWithIdentifier("ShowVideoSegue", sender: self)
        }else{
            var media = Media(temptype: "image", tempdata: info[UIImagePickerControllerOriginalImage] as! UIImage)
            dispatch.requests_media_list.addObject(media)
            dismissViewControllerAnimated(true, completion: nil);
            self.imagecollection.reloadData()
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        var media = Media(temptype: "image", tempdata: image)
        dispatch.requests_media_list.addObject(media)
        dismissViewControllerAnimated(true, completion: nil);
        self.imagecollection.reloadData()
        return
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil);
        self.imagecollection.reloadData()
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        var search_request = MKLocalSearchRequest()
        search_request.naturalLanguageQuery = self.location_name.text
        search_request.region = self.map.region
        
        let search = MKLocalSearch(request: search_request)
        search.startWithCompletionHandler { (response, error) in
            if (error == nil){
                let placemark = (response.mapItems[0] as! MKMapItem).placemark
                
                for x in response.mapItems{
                    var place = (x as! MKMapItem)
                    self.places.addObject(place)
                }
                self.LocationsTable.reloadData()
            }
        }
        self.location_name.resignFirstResponder()
        self.LocationTableView.hidden = false
        return true
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.LocationTableView.hidden = true
        println("Selected")
        if let place = self.places[indexPath.row] as? MKMapItem {
            if let containsPlacemark = place.placemark {
                let pin = CLLocationCoordinate2D(
                    latitude: containsPlacemark.location.coordinate.latitude,
                    longitude: containsPlacemark.location.coordinate.longitude
                )
                
                let span = MKCoordinateSpanMake(0.0025, 0.0025)
                let region = MKCoordinateRegion(center: pin, span: span)
                self.map.setRegion(region, animated: true)
            }
        }
        self.places.removeAllObjects()
    }
    
    func tableView(tableView: UITableView,numberOfRowsInSection section:    Int) -> Int {
        return self.places.count;
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        self.map.removeOverlays(self.map.overlays)
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        var centre_location = CLLocation(latitude: view.annotation.coordinate.latitude, longitude: view.annotation.coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(centre_location, completionHandler: {(placemarks, error)->Void in
            if (error != nil) {
                println("Reverse geocoder failed with error" + error.localizedDescription)
                return
            }
            
            if placemarks.count > 0 {
                let destination_pm = placemarks[0] as! CLPlacemark
                self.get_source_pm(destination_pm)
            } else {
                println("Problem with the data received from geocoder")
            }
        })
    }
    
    func get_source_pm(destination_pm: CLPlacemark?){
        
        println(location.latitude)
        println(location.longitude)
        var centre_location = CLLocation(latitude: location.latitude, longitude: location.longitude)
        CLGeocoder().reverseGeocodeLocation(centre_location, completionHandler: {(placemarks, error)->Void in
            if (error != nil) {
                println("Reverse geocoder failed with error" + error.localizedDescription)
                return
            }
            
            if placemarks.count > 0 {
                let source_pm = placemarks[0] as! CLPlacemark
                self.route_user(destination: destination_pm, source: source_pm)
            } else {
                println("Problem with the data received from geocoder")
            }
        })
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if (overlay.isKindOfClass(MKPolyline)){
            var renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.blueColor()
            renderer.lineWidth = 5.0
            return renderer
        }
        
        return nil
    }
    
    func route_user(#destination: CLPlacemark?, source :CLPlacemark?){
        var direction_request = MKDirectionsRequest()
        var source_pm = MKPlacemark(coordinate: source!.location.coordinate, addressDictionary: source?.addressDictionary)
        var destination_pm = MKPlacemark(coordinate: destination!.location.coordinate, addressDictionary: destination?.addressDictionary)
        
        direction_request.setSource(MKMapItem(placemark: source_pm))
        direction_request.setDestination(MKMapItem(placemark: destination_pm))
        direction_request.transportType = MKDirectionsTransportType.Automobile
        var direction = MKDirections(request: direction_request)
        direction.calculateDirectionsWithCompletionHandler ({
            (response: MKDirectionsResponse?, error: NSError?) in
            if (error != nil){
                return
            }else{
                for x in response!.routes{
                    let route = x as! MKRoute
                    self.map.addOverlay(route.polyline, level: MKOverlayLevel.AboveRoads)
                }
            }
        })
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("LocationTableViewCell") as! LocationTableViewCell
        var tempname : String = ""
        var tempaddress : String = ""
        if (self.places.count != 0){
            if let place = self.places[indexPath.row] as? MKMapItem {
                tempname = place.name!
                if (place.placemark.subThoroughfare != nil){
                    tempaddress = tempaddress + place.placemark.subThoroughfare
                }
                
                if(place.placemark.subLocality != nil){
                    if (tempaddress == ""){
                        tempaddress = tempaddress + place.placemark.subLocality
                    }else{
                        tempaddress = tempaddress + " " + place.placemark.subLocality
                    }
                }
                
                if (place.placemark.subAdministrativeArea != nil){
                    if (tempaddress == ""){
                        tempaddress = tempaddress + place.placemark.subAdministrativeArea
                    }else{
                        tempaddress = tempaddress + " " + place.placemark.subAdministrativeArea
                    }
                }
            }
            cell.loadItem(name: tempname, address: tempaddress)
            return cell
        }
        
        return UITableViewCell()
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if(self.EditButton.titleLabel?.text == "Back"){
            dispatch.requests_media_list.removeObjectAtIndex(indexPath.row)
            var indexPaths : NSMutableArray = NSMutableArray()
            indexPaths.addObject(indexPath)
            collectionView.deleteItemsAtIndexPaths(indexPaths as [AnyObject])
            self.imagecollection.cellForItemAtIndexPath(indexPath)
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //if Doneloading{
        return dispatch.requests_media_list.count
        //}
        //   return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UploadedImageCell",forIndexPath: indexPath)as! UploadedImagesViewCell
        var (tempimage) = dispatch.requests_media_list[indexPath.row] as? Media
        
        cell.loadItem(image: tempimage!)
        
        return cell
    }
}
