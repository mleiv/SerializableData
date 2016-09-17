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
        spinnerOverlay.isOpaque = false
        spinnerOverlay.isHidden = true
        parent.view.addSubview(spinnerOverlay)
        
        //size to fit
        spinnerOverlay.translatesAutoresizingMaskIntoConstraints = false
        spinnerOverlay.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor).isActive = true
        spinnerOverlay.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor).isActive = true
        spinnerOverlay.topAnchor.constraint(equalTo: parent.view.topAnchor).isActive = true
        spinnerOverlay.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor).isActive = true
        
        //create spinner
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.color = UIColor.white
        spinner.startAnimating()
        spinnerOverlay?.addSubview(spinner)
        
        //size to fit
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: spinnerOverlay.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: spinnerOverlay.centerYAnchor).isActive = true
        
        //done!
        isSetup = true
    }
    
    func start() {
        if !isSetup {
            setup()
        }
        spinnerOverlay?.isHidden = false
    }
    
    func stop() {
        spinnerOverlay?.isHidden = true
    }
}
