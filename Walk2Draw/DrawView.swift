//
//  DrawView.swift
//  Walk2Draw
//
//  Created by Monty Boyer on 5/12/20.
//  Copyright © 2020 Monty Boyer. All rights reserved.
//

import UIKit
import MapKit

class DrawView: UIView {
    
    let mapView: MKMapView
    let clearButton: UIButton
    let startStopButton: UIButton
    let shareButton: UIButton
    
    override init(frame: CGRect) {
        
        mapView = MKMapView()
        
        // activate the blue circle to show the device location on the map
        mapView.showsUserLocation = true
        
        // init the buttons
        clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        
        startStopButton = UIButton(type: .system)
        startStopButton.setTitle("Start", for: .normal)
        
        shareButton = UIButton(type: .system)
        shareButton.setTitle("Share", for: .normal)
        
        super.init(frame: frame)
        
        // set background to a nice, opaque color
        backgroundColor = UIColor.white
        
        // set up to draw an overlay of locations
        mapView.delegate = self
        
        // create a horizontal stack (default) for the three buttons
        let buttonStackView = UIStackView(arrangedSubviews: [clearButton, startStopButton, shareButton])
        buttonStackView.distribution = .fillEqually
        
        // create a vertical stack for the map and the button stack
        let stackView = UIStackView(arrangedSubviews: [mapView, buttonStackView])
        stackView.axis = .vertical
        
        addSubview(stackView)
        
        // Tell UIKit that we want to activate the needed constraints ourselves,
        // rather than use the auto resizing mask of the stack view.
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // set the stack edges to the view edges, except for the bottom which has to
        // leave room for the home indicator on recent iPhones.
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addOverlay(with locations: [CLLocation], segmentsCount: Int) {
        // map the locations to an array of CLLocation coordinates
        let coordinates = locations.map { $0.coordinate }
        
        // create a polyline overlay from the coordinates then add it to the map
        let overlay = MKPolyline(coordinates: coordinates,
                                 count: coordinates.count)
        mapView.addOverlay(overlay)
        
        // add annotation for start location
        if coordinates.count == 1 {
            let annot = MKPointAnnotation()
            annot.coordinate = coordinates[0]
            annot.title = "Start"       // used to identify this annotation in delegate
            annot.subtitle = "Segment \(segmentsCount)"
            mapView.addAnnotation(annot)
        }
        
        // set a region on the map to include at least most of the locations
        if let lastLocation = locations.last {
            // find the max distance of all locations from the last location
            let maxDistance = locations.reduce(100) {
                result, next -> Double in
                
                let distance = next.distance(from: lastLocation)
                return max(result, distance)
            }
            
            // create and set a region based on max distance and the last location
            let region = MKCoordinateRegion(center: lastLocation.coordinate,
                                            latitudinalMeters: maxDistance,
                                            longitudinalMeters: maxDistance)
            mapView.setRegion(region, animated: true)
        }
    }
    
}

// MARK: - Delegates

extension DrawView : MKMapViewDelegate {
    
    /* Provide a customized renderer for the polyline that was created from locations */
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 3
            return renderer
            
        } else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    /* Display the start & stop annotations for the segment */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let id = MKMapViewDefaultAnnotationViewReuseIdentifier
        if let v = mapView.dequeueReusableAnnotationView(withIdentifier: id, for: annotation) as? MKMarkerAnnotationView {
            if let t = annotation.title {
                if t == "Start" {
                    v.titleVisibility = .hidden
                    v.markerTintColor = .green
                    return v
                    
                } else if t == "Stop" {
                    v.titleVisibility = .hidden
                    v.markerTintColor = .red
                    return v
                }
            }
        }
        return nil
    }
}
