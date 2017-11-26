//
//  DroppablePin.swift
//  PixelCity
//
//  Created by Iain Coleman on 26/11/2017.
//  Copyright © 2017 Fiendish Corporation. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    
    dynamic var coordinate: CLLocationCoordinate2D
    var identifier: String
    
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
    
}
