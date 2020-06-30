//
//  UIView+Layout.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/22/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation
import UIKit

protocol Anchorable {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: Anchorable {
    
}

extension UILayoutGuide: Anchorable {
    
}

extension UIView {
    
    func setHeight(to constant: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: constant).isActive = true
    }
    
    func setWidth(to constant: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalToConstant: constant).isActive = true
    }
    
    func setAspectRatio(to ratio: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: ratio, constant: 0).isActive = true
    }
    
    func pinHeight(toHeightOf view: UIView, multiplier: CGFloat = 1, constant: CGFloat = 0) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: multiplier, constant: constant).isActive = true
    }
    
    func pinHeight(toMaxHeightOf views: [UIView]) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        for view in views {
            self.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, multiplier: 1.0).isActive = true
        }
        
        let constraint = self.heightAnchor.constraint(equalToConstant: 0.0)
        constraint.priority = .defaultLow
        constraint.isActive = true
    }

    func pinWidth(toWidthOf view: UIView, multiplier: CGFloat = 1, constant: CGFloat = 0) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: multiplier, constant: constant).isActive = true
    }
    
    func centerHorizontally(in view: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
    }
    
    func centerVertically(in view: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0).isActive = true
    }
    
    func pin(to anchorable: Anchorable, with insets: UIEdgeInsets = UIEdgeInsets()) {
        pinX(to: anchorable, leading: insets.left, trailing: insets.right)
        pinY(to: anchorable, top: insets.top, bottom: insets.bottom)
    }
    
    func pinX(to anchorable: Anchorable, leading: CGFloat = 0, trailing: CGFloat = 0) {
        pin(edge: .leading, to: .leading, of: anchorable, with: leading)
        pin(edge: .trailing, to: .trailing, of: anchorable, with: trailing)
    }

    func pinY(to anchorable: Anchorable, top: CGFloat = 0, bottom: CGFloat = 0) {
        pin(edge: .top, to: .top, of: anchorable, with: top)
        pin(edge: .bottom, to: .bottom, of: anchorable, with: bottom)
    }
    
    func pin(edge: NSDirectionalRectEdge, to toEdge: NSDirectionalRectEdge, of anchorable: Anchorable, with constant: CGFloat = 0) {
        if self.translatesAutoresizingMaskIntoConstraints {
            self.translatesAutoresizingMaskIntoConstraints = false
        }
        
        switch (edge, toEdge) {
            case (.leading, .leading):
                self.leadingAnchor.constraint(equalTo: anchorable.leadingAnchor, constant: constant).isActive = true
                break
                
            case (.leading, .trailing):
                self.leadingAnchor.constraint(equalTo: anchorable.trailingAnchor, constant: constant).isActive = true
                break
                
            case (.trailing, .trailing):
                self.trailingAnchor.constraint(equalTo: anchorable.trailingAnchor, constant: constant).isActive = true
                break
                
            case (.trailing, .leading):
                self.trailingAnchor.constraint(equalTo: anchorable.leadingAnchor, constant: constant).isActive = true
                break
            
            case (.top, .top):
                self.topAnchor.constraint(equalTo: anchorable.topAnchor, constant: constant).isActive = true
                break
            
            case (.top, .bottom):
                self.topAnchor.constraint(equalTo: anchorable.bottomAnchor, constant: constant).isActive = true
                break
            
            case (.bottom, .bottom):
                self.bottomAnchor.constraint(equalTo: anchorable.bottomAnchor, constant: constant).isActive = true
                break
            
            case (.bottom, .top):
                self.bottomAnchor.constraint(equalTo: anchorable.topAnchor, constant: constant).isActive = true
                break
                
            default:
                return
        }
    }
}
