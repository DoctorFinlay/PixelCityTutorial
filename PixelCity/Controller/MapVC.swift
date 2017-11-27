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
import Alamofire
import AlamofireImage


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
    var collectionView: UICollectionView?
    var flowLayout = UICollectionViewFlowLayout() //As we are adding the collection view programmatically, we need a flow layout
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = UIColor.white
        
        pullUpView.addSubview(collectionView!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateProgressLbl), name: NOTIF_UPDATE_PROGRESS_LBL, object: nil)
        
        //Set up sourceRect for 3d touch
        registerForPreviewing(with: self, sourceView: collectionView!)
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
        FlickrApiService.instance.cancelAllSessions()
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
        collectionView?.addSubview(spinner!)
    }
    
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    
    func addProgressLbl() {
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (screenSize.width/2) - 120, y: 175, width: 240, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 18)
        progressLbl?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLbl?.textAlignment = .center
        collectionView?.addSubview(progressLbl!)
    }
    
    
    func removeProgressLbl() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
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
        FlickrApiService.instance.cancelAllSessions()
        removePin()
        removeSpinner()
        removeProgressLbl()
        
        FlickrApiService.instance.emptyArrays()
        
        collectionView?.reloadData()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLbl()
        
        
        //Create a touch point
        let touchPoint = sender.location(in: mapView)  //this creates coordinates for the touch point on the screen , not GPS coordinate!
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView) //This one line converts it to GPS coordinates!
        
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        FlickrApiService.instance.retrieveUrls(forAnnotation: annotation) { (success) in
            if success {
                FlickrApiService.instance.retrieveImages(completion: { (success) in
                    //Hide the spinner
                    self.removeSpinner()
                    //Hide progress label
                    self.removeProgressLbl()
                    //Reload collectionview
                    self.collectionView?.reloadData()
                })
            } else {
                print("Ruh-roh!")
            }
        }
    }
    
    
    @objc func updateProgressLbl() {
        if self.progressLbl != nil {
            self.progressLbl!.text = FlickrApiService.instance.progressLabel
        }
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



extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //We need the number of items in the imageArray
        return FlickrApiService.instance.imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageFromIndex = FlickrApiService.instance.imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return }
        popVC.initData(forImage: FlickrApiService.instance.imageArray[indexPath.row], forTitle: FlickrApiService.instance.titlesArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}


extension MapVC: UIViewControllerPreviewingDelegate {
    //3d touch
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //Pop to next VC
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return nil }
        
        popVC.initData(forImage: FlickrApiService.instance.imageArray[indexPath.row], forTitle: FlickrApiService.instance.titlesArray[indexPath.row])
        previewingContext.sourceRect = cell.contentView.frame
        return popVC
    }
    
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        //Peek
        show(viewControllerToCommit, sender: self)
    }
    
}








