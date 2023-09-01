//
//  ShapeDrawingView.swift
//  Draw-Shapes
//
//  Created by Akshay Naithani on 30/08/23.
//

import UIKit

class ShapeDrawingView: UIView {
    private weak var context:CGContext!
    
    var line: Line?
    var rectangle: Rectangle?
    var freehand: Freehand?

    var lines: [Line] = []
    var rectangles: [Rectangle] = []
    var freehands: [Freehand] = []
    
    private let whiteSelectedCGColor = UIColor.white.cgColor
    private let yellowSelectedCGColor = UIColor.yellow.cgColor

    private let normalAlphaValue: CGFloat = 1
    private let selectedAlphaValue: CGFloat = 1
    
    override func draw(_ rect: CGRect) {
        
        context = nil
        context = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(whiteSelectedCGColor)
        context.setLineWidth(2)
        
        if let line {
            drawLine(pointA: line.startPoint,
                     pointB: line.endPoint,
                     isSelected: true,
                     width: line.strength)
        }
        
        if let rectangle {
            drawRect(pointA: rectangle.pointA,
                     pointB: rectangle.pointB,
                     pointC: rectangle.pointC,
                     pointD: rectangle.pointD,
                     isSelected: true,
                     width: rectangle.strength)
        }
        
        if let freehand {
            drawFreehand(points: freehand.pointArray,
                         isSelected: true,
                         width: freehand.strength)
        }
        
        for line in lines {
            drawLine(pointA: line.startPoint,
                     pointB: line.endPoint,
                     isSelected: line.isSelected,
                     width: line.strength)
        }
        
        for rectangle in rectangles {
            drawRect(pointA: rectangle.pointA,
                     pointB: rectangle.pointB,
                     pointC: rectangle.pointC,
                     pointD: rectangle.pointD,
                     isSelected: rectangle.isSelected,
                     width: rectangle.strength)
        }
        for freehand in freehands {
            drawFreehand(points: freehand.pointArray,
                         isSelected: freehand.isSelected,
                         width: freehand.strength)
        }
        context.drawPath(using: .stroke)
        
    }
    private func drawLine(pointA: CGPoint, pointB: CGPoint, isSelected: Bool, width: CGFloat){
        if isSelected{
            createCircleOnSelectedShape(points: [pointA,pointB])
            drawSelectedPathWithContext(pointA: pointA, pointB: pointB, width: width)
        }
        let widthValue = isSelected ? 2*width : width
        drawUnselectedPathWithContext(pointA: pointA, pointB: pointB, width: widthValue)
    }
    private func drawRect(pointA: CGPoint, pointB: CGPoint, pointC: CGPoint, pointD: CGPoint, isSelected: Bool, width: CGFloat){
        context.beginPath()
        if isSelected{
            createCircleOnSelectedShape(points: [pointA, pointB, pointD, pointC])
            drawSelectedPathWithContext(pointA: pointA, pointB: pointB, width: width)
            drawSelectedPathWithContext(pointA: pointB, pointB: pointD, width: width)
            drawSelectedPathWithContext(pointA: pointD, pointB: pointC, width: width)
            drawSelectedPathWithContext(pointA: pointC, pointB: pointA, width: width)
            drawArc(start: pointA, center: pointB, end: pointD, width: width/2)
            drawArc(start: pointB, center: pointD, end: pointC, width: width/2)
            drawArc(start: pointD, center: pointC, end: pointA, width: width/2)
            drawArc(start: pointC, center: pointA, end: pointB, width: width/2)
        }
        let widthValue = isSelected ? 2*width : width
        drawUnselectedPathWithContext(pointA: pointA, pointB: pointB, width: widthValue)
        drawUnselectedPathWithContext(pointA: pointB, pointB: pointD, width: widthValue)
        drawUnselectedPathWithContext(pointA: pointD, pointB: pointC, width: widthValue)
        drawUnselectedPathWithContext(pointA: pointC, pointB: pointA, width: widthValue)
        drawArc(start: pointA, center: pointB, end: pointD, width: width/2)
        drawArc(start: pointB, center: pointD, end: pointC, width: width/2)
        drawArc(start: pointD, center: pointC, end: pointA, width: width/2)
        drawArc(start: pointC, center: pointA, end: pointB, width: width/2)
    }
    private func drawFreehand(points: [CGPoint],isSelected: Bool,width: CGFloat){
        var prevPoint:CGPoint = .zero
        if isSelected {
            createCircleOnSelectedShape(points: [points.first!,points.last!])
        }
        for (i,point) in points.enumerated(){
            if i != 0 {
                if isSelected{
                    drawSelectedPathWithContext(pointA: prevPoint, pointB: point, width: width, isFreehandShape: true)
                }
            }
            prevPoint = point
        }
        let widthValue = isSelected ? 2*width : width
        for (i,point) in points.enumerated(){
            if i != 0 {
                drawUnselectedPathWithContext(pointA: prevPoint, pointB: point, width: widthValue, isFreehandShape: true)
            }
            prevPoint = point
        }
    }
    
    private func selectedLineWidth(width: CGFloat) -> CGFloat {
        return width * 3
    }
    private func drawArc(start: CGPoint,center: CGPoint,end: CGPoint,width: CGFloat) {
        let tempRadius = CGFloat(CGVector.arcRadius(start, pt2: center, pt3: end))
        if tempRadius < 50 {
            return
        }
        let radius: CGFloat = 50
        let startAngle: CGFloat = .init(CGVector.init(from: start, to: center).angle)
        let endAngle: CGFloat = .init(CGVector.init(from: center, to: end).angle)
        context.beginPath()
        context.addArc(center: center, radius: radius, startAngle: startAngle + .pi, endAngle: endAngle, clockwise: true)
        context.drawPath(using: .stroke)
        context.setFillColor(yellowSelectedCGColor)
        context.strokePath()
    }
    private func drawSelectedPathWithContext(pointA:CGPoint,pointB:CGPoint,width:CGFloat,isFreehandShape:Bool = false){
            drawLinePath(pointA: pointA,
                         pointB: pointB,
                         strokeColor: whiteSelectedCGColor,
                         widthValue: selectedLineWidth(width: width),
                         alpha: selectedAlphaValue)
    }
    
    private func drawUnselectedPathWithContext(pointA:CGPoint,pointB:CGPoint,width:CGFloat,isFreehandShape:Bool = false){
        drawLinePath(pointA: pointA,
                     pointB: pointB,
                     strokeColor: yellowSelectedCGColor,
                     widthValue: width,
                     alpha: normalAlphaValue)
    }
    
    private func drawLinePath(pointA:CGPoint,pointB:CGPoint,strokeColor:CGColor,widthValue:CGFloat,alpha: CGFloat) {
        context.beginPath()
        context.setAlpha(alpha)
        context.setLineWidth(widthValue)
        context.setStrokeColor(strokeColor)
        context.setLineCap(.round)
        context.move(to: pointA)
        context.addLine(to: pointB)
        context.strokePath()
        context.closePath()
    }
    
    private func createCircleOnSelectedShape(points: [CGPoint]){
        let radius:CGFloat = 20.0
        for point in points{
            context.setFillColor(UIColor.white.cgColor)
            context.setStrokeColor(UIColor.darkGray.cgColor)
            context.setAlpha(0.5)
            context.setLineWidth(1)
            
            let rectangle = CGRect(x: point.x - radius, y: point.y - radius, width: 2 * radius, height: 2 * radius)
            context.addEllipse(in: rectangle)
            context.drawPath(using: .fillStroke)
        }
    }
 
}
