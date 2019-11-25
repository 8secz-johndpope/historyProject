//
//  LocationManager.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 22/9/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private var locationManager: CLLocationManager?
    private var latestLocation: CLLocation?
    
    private static let instance = LocationManager()
    
    static func sharedInstance() -> LocationManager {
        return instance
    }
    
    private override init() {
        super.init()
    }
    
    func start() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            
            if let locationManager = locationManager, CLLocationManager.authorizationStatus() == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
            
            locationManager?.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.startUpdatingLocation()
        }
    }
    
    func getCurrentLocation() -> CLLocation? {
        return latestLocation
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            latestLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager?.startUpdatingLocation()
        }
    }

}
