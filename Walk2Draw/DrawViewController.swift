//
//  DrawViewController.swift
//  Walk2Draw
//
//  Created by Monty Boyer on 5/12/20.
//  Copyright © 2020 Monty Boyer. All rights reserved.
//

import UIKit
import LogStore
import CoreLocation

class DrawViewController: UIViewController {
    
    private var locationProvider: LocationProvider? = nil
    private var locations: [CLLocation] = []    // array of reported locations
    private var contentView: DrawView {
        view as! DrawView
    }

    override func loadView() {
        // set the view to be a DrawView. let the size and position be defined by the view controller
        let contentView = DrawView(frame: .zero)
        
        // hook up the startstop button to its handler
        contentView.startStopButton.addTarget(self, action: #selector(startStop(_:)), for: .touchUpInside)
        
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // assign a new Location provider with an update handler in this closure
        locationProvider = LocationProvider(updateHandler: {
            [unowned self] location, error in
            
            guard let location = location else { return }
            
            // for testing log the location
            // printLog("location: \(location))")

            // add this location to the array
            self.locations.append(location)
            
            // add an overlay with the locations to the map
            (self.view as? DrawView)?.addOverlay(with: self.locations)
        })
    }

    @objc func startStop(_ sender: UIButton) {
        // toggle the location updating & the start / stop button text
        if locationProvider?.locationsUpdating ?? false {
            locationProvider?.stop()
            sender.setTitle("Start", for: .normal)
            
        } else {
            locationProvider?.start()
            sender.setTitle("Stop", for: .normal)
        }
    }
    
}
