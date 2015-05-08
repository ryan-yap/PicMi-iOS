//
//  MapViewController.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-05-07.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController,MKMapViewDelegate {

    @IBOutlet var map: MKMapView!
    
    @IBOutlet var thingicon: UIImageView!
    @IBOutlet var placeicon: UIImageView!
    @IBOutlet var guyicon: UIImageView!
    
    var longitude : Double = Double()
    var latitude : Double = Double()
    var type : String = ""
    var location_name : String = ""
    
    @IBOutlet var locationLabel: UILabel!
    
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
    
    @IBAction func back(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch (self.type){
        case("place"):
            self.showplaceicon()
        case("thing"):
            self.showthingicon()
        default:
            self.showguyicon()
        }
        self.map.removeAnnotations(map.annotations)
        let pin = CLLocationCoordinate2D(
            //latitude: location.latitude,
            //longitude: location.longitude
            latitude: self.latitude,
            longitude: self.longitude
        )
        let span = MKCoordinateSpanMake(0.0025, 0.0025)
        let region = MKCoordinateRegion(center: pin, span: span)
        self.map.setRegion(region, animated: true)
        var annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(
            //latitude: location.latitude,
            //longitude: location.longitude
            latitude: self.latitude,
            longitude: self.longitude
        )
        
        map.addAnnotation(annotation)
        // Do any additional setup after loading the view.
        
        self.locationLabel.text = self.location_name
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
