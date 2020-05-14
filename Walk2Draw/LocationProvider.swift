//
//  LocationProvider.swift
//  Walk2Draw
//
//  Created by Monty Boyer on 5/12/20.
//  Copyright © 2020 Monty Boyer. All rights reserved.
//

import UIKit
import CoreLocation
import LogStore

class LocationProvider: NSObject,  CLLocationManagerDelegate {
    
    private let locationManager: CLLocationManager
    private let updateHandler: (CLLocation?, Error?) -> Void
    
    var locationsUpdating = false    // track state of getting location updates
    
    init(updateHandler: @escaping (CLLocation?, Error?) -> Void) {
        // assign a new instance for this class property
        locationManager = CLLocationManager()
        
        // capture the passed in update handler
        self.updateHandler = updateHandler
        
        // invoke super to make locationManager available via self
        super.init()
        
        // this class is the delegate
        locationManager.delegate = self
        locationManager.distanceFilter = 1      // get notified when the device has moved 1 meter
        
        // ask for permission to get the device location
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: Delegates
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            printLog("authorization success")
        case .denied:
            printLog("authorization denied!")
            /*
             Once the user has denied access to the location, the app can’t ask again
             and the location manager always delivers the status denied. In this case the
             app could show an alert that it cannot function properly and ask if the user
             would like to change the permission in the settings of the app. We can even
             redirect the users to the settings with the following code:
                    let settingsURL = URL(string: UIApplication.openSettingsURLString)!
                    UIApplication.shared.open(settingsURL)
            */
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // for testing just log the locations
        // printLog("locations: \(locations)")
        
        // get the most recent location
        guard let location = locations.last else { return }
        
        // pass it to the update handler
        updateHandler(location, nil)
    }
    
    // MARK: UI action handlers
    
    func start() {
        // start tracking the device location
        locationManager.startUpdatingLocation()
        locationsUpdating = true
        locationManager.allowsBackgroundLocationUpdates = true
    }

    func stop() {
        // stop tracking the device location
        locationManager.stopUpdatingLocation()
        locationsUpdating = false
        locationManager.allowsBackgroundLocationUpdates = false
    }

}
