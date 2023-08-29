//
//  FreehandModel.swift
//  Draw-Shapes
//
//  Created by Akshay Naithani on 30/08/23.
//

import Foundation

class FreehandModel: ModelItem {
    
    var pointArray: [CGPoint] = [.zero]
    
    init(pointArray: [CGPoint]) {
        self.pointArray = pointArray
    }
}
