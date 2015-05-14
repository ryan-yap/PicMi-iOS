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
    
    func start_routing(){
        var centre_location = CLLocation(latitude: self.latitude, longitude: self.longitude)
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
            renderer.strokeColor = UIColor(red: 0, green: 0.4901196, blue: 0.631372549, alpha: 1)
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
        self.start_routing()
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
