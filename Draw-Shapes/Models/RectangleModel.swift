//
//  RectangleModel.swift
//  Draw-Shapes
//
//  Created by Akshay Naithani on 30/08/23.
//

import Foundation

class RectangleModel: ModelItem {
    
    var pointA: CGPoint = .zero
    var pointB: CGPoint = .zero
    var pointC: CGPoint = .zero
    var pointD: CGPoint = .zero
    
    init(pointA: CGPoint, pointB: CGPoint, pointC: CGPoint, pointD: CGPoint) {
        self.pointA = pointA
        self.pointB = pointB
        self.pointC = pointC
        self.pointD = pointD
    }
}
