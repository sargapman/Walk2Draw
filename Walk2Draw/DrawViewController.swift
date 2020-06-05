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
    private var locations: [CLLocation] = []    // array of reported locations in a segment
    private var segments: [[CLLocation]] = []   // array of segments comprising a journey
    // private var currentSegment = 0
    
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
        
        /*
        let redPinImage = UIImage(systemName: "mappin")?.withTintColor(.red)
        let greenPinImage = UIImage(systemName: "mappin")?.withTintColor(.green)
        contentView.shareButton.setImage(greenPinImage, for: .normal)
        contentView.clearButton.setImage(redPinImage, for: .normal)
         */

        
        // assign a new Location provider with an update handler in this closure
        locationProvider = LocationProvider(updateHandler: {
            [unowned self] location, error in
            
            guard let location = location else { return }
            
            // for testing log the location
            // printLog("location: \(location))")

            // add this location to the array of the current segment
            self.segments[(self.segments.count-1)].append(location)
            
            // add an overlay with the locations in each segment of the journey
            for segment in self.segments {
                (self.view as? DrawView)?.addOverlay(with: segment, segmentsCount: self.segments.count)
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        printLog("viewDidAppear")

        if locationProvider?.locationPermissionDenied ?? false {
            requestLocationPermission()
        }
    }
    
    // MARK: UI action handlers

    @objc func startStop(_ sender: UIButton) {
        // toggle the location updating & the start / stop button text
        if locationProvider?.locationsUpdating ?? false {
            // Stop was tapped

            // add annotation for stop location
            let currentSegment = segments.count - 1
            if segments[currentSegment].count > 0 {
                let lastLocation = segments[currentSegment].last

                let annot = MKPointAnnotation()
                annot.coordinate = lastLocation!.coordinate
                annot.title = "Stop"       // used to identify this annotation in delegate
                annot.subtitle = "Segment \(segments.count)"
                contentView.mapView.addAnnotation(annot)
            }
            
            locationProvider?.stop()
            
            // set the button title
            sender.setTitle("Start", for: .normal)
            
            // enable the Clear button
            contentView.clearButton.isEnabled = true

        } else {
            // Start was tapped

            // does the app have permission to get locations?
            if locationProvider?.locationPermissionDenied ?? false {
                requestLocationPermission()
                
            } else {
                // add a new segment to the journey
                locations.removeAll()
                segments.append(locations)

                locationProvider?.start()

                // add annotation for start location when the first one arrives
                
                // set the button title
                sender.setTitle("Stop", for: .normal)
                
                // disable the Clear button
                contentView.clearButton.isEnabled = false
            }
        }
    }
    
    @objc func clear(_ sender: UIButton) {
        // clear the segments & locations array
        locations.removeAll()
        segments.removeAll()
        
        // remove all existing overlays on the map
        contentView.mapView.removeOverlays(contentView.mapView.overlays)
        
        // remove all existing annotations on the map
        contentView.mapView.removeAnnotations(contentView.mapView.annotations)

        // clear the map overlays
        contentView.addOverlay(with: locations, segmentsCount: 0)
    }
    
    @objc func share(_ sender: UIButton) {
        // anything to see here?
        if segments.count == 0 && locations.isEmpty { return }
        
        let options = MKMapSnapshotter.Options()
        options.region = contentView.mapView.region
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        snapshotter.start {
            snapshot, error in
            
            guard let snapshot = snapshot else { return }
            
            let image = self.imageByAddingSegments(with: self.segments, to: snapshot)

            let activity = UIActivityViewController(activityItems: [image, "#walk2draw"], applicationActivities: nil)
            // let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)

            // ensure this works properly on iPad
            activity.popoverPresentationController?.sourceView = sender
            
            self.present(activity, animated: true, completion: nil)
        }
    }
    
    func imageByAddingSegments(with segments: [[CLLocation]],
                               to snapshot: MKMapSnapshotter.Snapshot) -> UIImage {
        
        // create a new image context that will be filled with bezier paths
        UIGraphicsBeginImageContextWithOptions(snapshot.image.size, true, 0.0)
        
        snapshot.image.draw(at: CGPoint(x: 0, y: 0))
        let bezierPath = UIBezierPath()

        // for each collection of points in each segment
        for locations in segments {
            // get the start point of the path
            guard let firstCoordinate = locations.first?.coordinate else { fatalError() }
            
            
            // begin the path at that point
            let firstPoint = snapshot.point(for: firstCoordinate)
            bezierPath.move(to: firstPoint)
            
            // for each remaining location draw a line from the prior location
            for location in locations.dropFirst() {
                let point = snapshot.point(for: location.coordinate)
                bezierPath.addLine(to: point)
            }
        }
        
        // set some attributes for the path
        UIColor.red.setStroke()
        bezierPath.lineWidth = 2
        
        // draw the path
        bezierPath.stroke()

        // get an image from the path
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { fatalError() }
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /*
     Once the user has denied access to the location, the app can’t ask again
     and the location manager always delivers the status denied. In this case the
     app shows an alert that it cannot function properly and asks if the user
     would like to change the permission in the Settings app.
    */
    public func requestLocationPermission() {
        
        // create & present alert with a message, Cancel and GoToSettings buttons
        let infoMsg = "Location tracking is not enabled for this app so it can not do much for you.\nWould you like to allow this app to know where you are?"
        let alertController = UIAlertController(title: "Location tracking permission denied", message: infoMsg, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Yes", style: .default, handler: {_ in
            printLog("OK tapped")

            // present the Settings app
            let settingsURL = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(settingsURL)
        })
        alertController.addAction(okAction)

        let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: {_ in
            printLog("Cancel tapped")
        })
        alertController.addAction(cancelAction)
        
        // display the alert
        present(alertController, animated: true, completion: nil)
    }
    
}
