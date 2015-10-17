//
//  Spinner.swift
//  MassEffectTracker
//
//  Created by Emily Ivie on 5/7/15.
//

import UIKit

class Spinner {
    unowned var parent: UIViewController //the view that will be concealed by the spinner and its background overlay
    
    var spinnerOverlay: UIView!
    var isSetup = false
    
    init(parent: UIViewController) {
        self.parent = parent
    }
    
    /**
        Creates a translucent overlay and spinner wheel and sets them to fill the parent view and be centered.
    
        Centering autolayout derived from https://github.com/evgenyneu/center-vfl
    */
    func setup() {
        //create overlay
        spinnerOverlay = UIView()
        spinnerOverlay.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        spinnerOverlay.opaque = false
        spinnerOverlay.hidden = true
        parent.view.addSubview(spinnerOverlay)
        
        //size to fit
        spinnerOverlay.translatesAutoresizingMaskIntoConstraints = false
        spinnerOverlay.leadingAnchor.constraintEqualToAnchor(parent.view.leadingAnchor).active = true
        spinnerOverlay.trailingAnchor.constraintEqualToAnchor(parent.view.trailingAnchor).active = true
        spinnerOverlay.topAnchor.constraintEqualToAnchor(parent.view.topAnchor).active = true
        spinnerOverlay.bottomAnchor.constraintEqualToAnchor(parent.view.bottomAnchor).active = true
        
        //create spinner
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        spinner.color = UIColor.whiteColor()
        spinner.startAnimating()
        spinnerOverlay?.addSubview(spinner)
        
        //size to fit
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraintEqualToAnchor(spinnerOverlay.centerXAnchor).active = true
        spinner.centerYAnchor.constraintEqualToAnchor(spinnerOverlay.centerYAnchor).active = true
        
        //done!
        isSetup = true
    }
    
    func start() {
        if !isSetup {
            setup()
        }
        spinnerOverlay?.hidden = false
    }
    
    func stop() {
        spinnerOverlay?.hidden = true
    }
}