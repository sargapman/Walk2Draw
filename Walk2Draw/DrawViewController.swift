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
import MapKit

class DrawViewController: UIViewController {
    
    private var locationProvider: LocationProvider? = nil
    private var locations: [CLLocation] = []    // array of reported locations
    private var contentView: DrawView {
        view as! DrawView
    }

    override func loadView() {
        // set the view to be a DrawView. let the size and position be defined by the view controller
        let contentView = DrawView(frame: .zero)
        
        // hook up the buttons to their handlers
        contentView.startStopButton.addTarget(self, action: #selector(startStop(_:)), for: .touchUpInside)

        contentView.clearButton.addTarget(self, action: #selector(clear(_:)), for: .touchUpInside)
        
        contentView.shareButton.addTarget(self, action: #selector(share(_:)), for: .touchUpInside)

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
    
    // MARK: UI action handlers

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
    
    @objc func clear(_ sender: UIButton) {
        // clear the locations array
        locations.removeAll()
        
        // clear the map overlays
        contentView.addOverlay(with: locations)
    }
    
    @objc func share(_ sender: UIButton) {
        // anything to see here?
        if locations.isEmpty { return }
        
        let options = MKMapSnapshotter.Options()
        options.region = contentView.mapView.region
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        snapshotter.start {
            snapshot, error in
            
            guard let snapshot = snapshot else { return }
            
            let image = self.imageByAddingPath(with: self.locations, to: snapshot)
            
            let activity = UIActivityViewController(activityItems: [image, "#walk2draw"], applicationActivities: nil)
            self.present(activity, animated: true, completion: nil)
        }
    }
    
    func imageByAddingPath(with locations: [CLLocation],
                           to snapshot: MKMapSnapshotter.Snapshot) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(snapshot.image.size, true, 0.0)
        
        snapshot.image.draw(at: CGPoint(x: 0, y: 0))
        
        let bezierPath = UIBezierPath()
        guard let firstCoordinate = locations.first?.coordinate else { fatalError() }
        
        let firstPoint = snapshot.point(for: firstCoordinate)
        bezierPath.move(to: firstPoint)
        
        for location in locations.dropFirst() {
            let point = snapshot.point(for: location.coordinate)
            bezierPath.addLine(to: point)
        }
        
        UIColor.red.setStroke()
        bezierPath.lineWidth = 2
        bezierPath.stroke()
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { fatalError() }
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
}
