//
//  MapVC.swift
//  PixelCity
//
//  Created by Iain Coleman on 22/11/2017.
//  Copyright © 2017 Fiendish Corporation. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class MapVC: UIViewController, UIGestureRecognizerDelegate {

    //Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    
    
    //Variables
    var locationManager = CLLocationManager()
    let authorisationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    var screenSize = UIScreen.main.bounds
    
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender: )))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        swipe.delegate = self
        pullUpView.addGestureRecognizer(swipe)
    }
    
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = 300 //Move the view up by 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded() //Redraw everything to show what has changed
        }
    }
    
    @objc func animateViewDown() {
        print("I ran - view should go down")
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded() //Redraw everything to show what has changed
        }
    }

    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
        spinner?.startAnimating()
        pullUpView.addSubview(spinner!)
    }
    
    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
        
        if authorisationStatus == .authorizedAlways || authorisationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
        
    }
    
}


extension MapVC: MKMapViewDelegate {
    
    //This is built in method to MKMapViewDelegate to change the color of pins dropped
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //Make sure we still get our blue current location instead of an orange pin
        if annotation is MKUserLocation {
            return nil
        }
        //Set pin colour to orange and animate it
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9647058824, green: 0.6509803922, blue: 0.137254902, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        //The coordinate region statement below creates a region of 1000m in each direction
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        removePin()
        animateViewUp()
        addSwipe()
        addSpinner()
        
        //Create a touch point
        let touchPoint = sender.location(in: mapView)  //this creates coordinates for the touch point on the screen , not GPS coordinate!
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView) //This one line converts it to GPS coordinates!
        
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
}



extension MapVC: CLLocationManagerDelegate {
    
    func configureLocationServices() {
        if authorisationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}
