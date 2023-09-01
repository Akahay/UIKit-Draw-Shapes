//
//  LineModel.swift
//  Draw-Shapes
//
//  Created by Akshay Naithani on 30/08/23.
//

import Foundation

class Line: Model {
    
    var startPoint: CGPoint = .zero
    var endPoint: CGPoint = .zero
    
    init(startPoint: CGPoint,endPoint: CGPoint) {
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
}
