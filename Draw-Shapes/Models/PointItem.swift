//
//  PointItem.swift
//  Draw-Shapes
//
//  Created by Akshay Naithani on 30/08/23.
//

import Foundation

struct PointItem {
    
    let uuid: UUID
    var point: CGPoint
    
    init(point: CGPoint) {
        self.uuid = UUID()
        self.point = point
    }
}
