//
//  Extensions.swift
//  Draw-Shapes
//
//  Created by Akshay Naithani on 30/08/23.
//

import Foundation

extension CGPoint {
    
    func minus(point: CGPoint) -> CGPoint {
        CGPoint(x: x - point.x, y: y - point.y)
    }
    
    func add(point: CGPoint) -> CGPoint {
        CGPoint(x: x + point.x, y: y + point.y)
    }
    
    func distance(point: CGPoint) -> CGFloat {
        let resPoint = minus(point: point)
        return sqrt(resPoint.x * resPoint.x + resPoint.y * resPoint.y)
    }
}
extension CGVector {
    
    init(from pt1: CGPoint, to pt2: CGPoint) {
        self =  CGVector(dx: pt2.x - pt1.x, dy: pt2.y - pt1.y)
    }
    
    public var length : Double {
        get {
            sqrt((Double(self.dx) * Double(self.dx)) + (Double(self.dy) * Double(self.dy)))
        }
    }
    
    public var angle : Float {
        get {
            let alpha = acosf(Float(Double(self.dx) / self.length))
            return (self.dy < 0) ? -alpha : alpha
        }
    }
    
    static public func arcRadius (_ pt1: CGPoint, pt2: CGPoint, pt3: CGPoint) -> Double {
        let startVector = CGVector.init(from: pt1, to: pt2)
        let endVector = CGVector.init(from: pt2, to: pt3)
        return min(startVector.length,endVector.length)/2
    }
    
}
