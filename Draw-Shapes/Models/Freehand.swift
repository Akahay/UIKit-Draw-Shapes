//
//  Freehand.swift
//  Draw-Shapes
//
//  Created by Akshay Naithani on 30/08/23.
//

import Foundation

class Freehand: Model {
    
    var pointArray: [CGPoint] = []
    
    init(pointArray: [CGPoint]) {
        self.pointArray = pointArray
    }
}
