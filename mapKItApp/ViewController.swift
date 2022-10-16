//
//  ViewController.swift
//  mapKItApp
//
//  Created by 中島竜太郎 on 2022/10/01.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var subTitleText: UITextField!
    @IBOutlet weak var mapKit: MKMapView!
    @IBOutlet weak var button: UIButton!
    
    var locationManager = CLLocationManager()
    var choosenLatitude = Double()
    var choosenLongtitude = Double()
    
    var selectedLocation = ""
    var selectedId: UUID?
    
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapKit.delegate = self
        
        //overrideUserInterfaceStyle = .light
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(choosenLocation))
        gestureRecognizer.minimumPressDuration = 3
        self.mapKit.addGestureRecognizer(gestureRecognizer)
        
        if selectedLocation != "" {
            button.isHidden = true
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedId!.uuidString
            
            fetchRequest.predicate = NSPredicate(format: "uuid = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            
            do {
                let results =  try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let title = result.value(forKey: "name") as? String {
                            annotationTitle = title
                            if let subTitle =  result.value(forKey: "subTitle") as? String {
                                annotationSubTitle = subTitle
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubTitle
                                        
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        mapKit.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        subTitleText.text = annotationSubTitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapKit.setRegion(region, animated: true)
                                        
                                    }
                                }
                                
                            }
                        }
                    }
                }
            } catch {
                print("error")
            }
            } else {
                nameText.text = ""
                subTitleText.text = ""
                button.isEnabled = true
                button.isHidden = false
            }
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let interFaceColor = traitCollection.userInterfaceStyle
        
        if interFaceColor == .dark {
            button.tintColor = .orange
        } else {
            button.tintColor = .brown
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let interFaceColor = traitCollection.userInterfaceStyle
        
        if interFaceColor == .dark {
            button.tintColor = .orange
        } else {
            button.tintColor = .black
        }
    }
    
    @objc func choosenLocation(gestureRecognizer: UILongPressGestureRecognizer)  {
        if gestureRecognizer.state == .began {
            let touchPoint  = gestureRecognizer.location(in: self.mapKit)
            let touchedLocation = self.mapKit.convert(touchPoint, toCoordinateFrom: self.mapKit)
            choosenLatitude = touchedLocation.latitude
            choosenLongtitude = touchedLocation.longitude
            
            let annotation = MKPointAnnotation()
            
             annotation.coordinate = touchedLocation
             annotation.title = nameText.text
             annotation.subtitle = subTitleText.text
            self.mapKit.addAnnotation(annotation)
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedLocation == "" {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        mapKit.setRegion(region, animated: true)
        } else {
            //
        }
        }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "myAnnotaion"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if annotation is MKUserLocation {
            return nil
        }
        
        
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let buuton = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView  = buuton
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedLocation != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                
                if let placeMark = placemarks {
                    if placeMark.count > 0 {
                        let newPlaceMark = MKPlacemark(placemark: placeMark[0])
                        let newItem = MKMapItem(placemark: newPlaceMark)
                        newItem.name = self.annotationTitle
                        let launchOption = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        newItem.openInMaps(launchOptions: launchOption)
                    }
                }
                
            }
        }
    }
    @IBAction func saveButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "name")
        newPlace.setValue(subTitleText.text, forKey: "subTitle")
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(choosenLongtitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "uuid")
        
        do {
            try context.save()
                print("success")
            } catch {
                print("error")
            }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        }
        
        
    }



