//
//  ViewController.swift
//  Draw-Shapes
//
//  Created by Akshay Naithani on 30/08/23.
//

import UIKit

enum SelectedShape {
    case line(value: Line)
    case rectangle(value: Rectangle)
    case freehand(value: Freehand)
    case none
}

class CanvasViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var canvasView: ShapeDrawingView!
    @IBOutlet private weak var shapesOptionStackView: UIStackView!
    @IBOutlet private weak var addPhotoButton: UIButton!
    @IBOutlet private weak var bottomViewConstraint: NSLayoutConstraint!
    
    private let imagePicker = UIImagePickerController()

    private var shapeType: ShapeType = .line
    private var rectType: RectType = .moveShape
    private var selectedRectType: SelectedSide = .none
    private var pointState: PointState = .none

    private var panGestureRecognizer: UIPanGestureRecognizer?

    private var selectedShape: SelectedShape = .none
    private var startPoint: CGPoint = .zero
    private var prevPoint: CGPoint = .zero

    private var line: Line?
    private var rect: Rectangle?
    private var freehand: Freehand?

    private var lines: [Line] = []
    private var rectangles: [Rectangle] = []
    private var freehands: [Freehand] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        canvasView.isUserInteractionEnabled = true
        hideBottomView(isHidden: true)
        addGestures()
    }
   
    func hideBottomView(isHidden: Bool) {
        bottomViewConstraint.constant = isHidden ? -bottomView.bounds.height : 0
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFill
            imageView.image = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func addPhoto(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction private func dismissSheet(_ sender: UIButton) {
        hideBottomView(isHidden: true)
    }
    
    @IBAction private func deleteShape(_ sender: UIButton) {
        switch selectedShape {
        case .line(let value):
            
            lines = lines.filter { $0.uuid != value.uuid }
            canvasView.lines = lines
            line = nil
            canvasView.line = line
            
        case .rectangle(let value):
            
            rectangles = rectangles.filter { $0.uuid != value.uuid }
            canvasView.rectangles = rectangles
            rect = nil
            canvasView.rectangle = rect
            
        case .freehand(let value):
            
            freehands = freehands.filter { $0.uuid != value.uuid }
            canvasView.freehands = freehands
            freehand = nil
            canvasView.freehand = freehand
            
        case .none:
            return
        }
        canvasView.setNeedsDisplay()
        hideBottomView(isHidden: true)
    }
}

//MARK:-Button Action
extension CanvasViewController: UIGestureRecognizerDelegate {
    @IBAction func setDrawingType(btn: UIButton) {
        if btn.tag == 0 {
            
            shapeType = .line
            
        } else if btn.tag == 1 {
            
            shapeType = .rect
            rectType = .moveShape
            
        } else if btn.tag == 2 {
            
            shapeType = .rect
            rectType = .moveArm
            
        } else if btn.tag == 3 {
            
            shapeType = .freehand
            
        }
        hideBottomView(isHidden: true)
    }
    
    func addGestures() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGestureRecognizer.delegate = self
        canvasView.addGestureRecognizer(tapGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGestureRecognizer.delegate = self
        canvasView.addGestureRecognizer(panGestureRecognizer)
        self.panGestureRecognizer = panGestureRecognizer
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: view)
        if location != .zero {
            startPoint = location
        }
    }
    private func addPoints(points: [CGPoint])->CGPoint {
        points.reduce(CGPoint.zero) { .init(x: $0.x + $1.x, y: $0.y + $1.y) }
    }

    func hideOption(isHidden: Bool) {
        shapesOptionStackView.isHidden = isHidden
        addPhotoButton.isHidden = isHidden
    }
    
    private func createRect(rect: Rectangle,to point: CGPoint) -> Rectangle {
        rect.pointD = point
        rect.pointC = CGPoint(x: point.x, y:  rect.pointA.y)
        rect.pointB = CGPoint(x: rect.pointA.x, y: point.y)
        return rect
    }
    
    private func deselectAllShapes(){
        lines.forEach { $0.isSelected = false }
        rectangles.forEach { $0.isSelected = false }
        freehands.forEach { $0.isSelected = false }
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        
        deselectAllShapes()
        selectedShape = .none
        guard let presentPoint = panGestureRecognizer?.translation(in: imageView) else {
            return
        }
        var isBottomViewHidden = true
        let currentPoint = addPoints(points: [startPoint,presentPoint])
        switch shapeType {
        case .line:
            if let lineValue = closeToShape(tapPoint: currentPoint) as? Line {
                lineValue.isSelected = true
                selectedShape = .line(value: lineValue)
                isBottomViewHidden = false
            }
        case .rect:
            if let rectValue = closeToShape(tapPoint: currentPoint) as? Rectangle {
                rectValue.isSelected = true
                selectedShape = .rectangle(value: rectValue)
                isBottomViewHidden = false
            }

        case .freehand:
            if let freehandValue = closeToShape(tapPoint: currentPoint) as? Freehand {
                freehandValue.isSelected = true
                selectedShape = .freehand(value: freehandValue)
                isBottomViewHidden = false
            }
        }
        hideBottomView(isHidden: isBottomViewHidden)
        canvasView.setNeedsDisplay()
    }
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        
        deselectAllShapes()
        guard let presentPoint = panGestureRecognizer?.translation(in: imageView) else {
            return
        }
        let currentPoint = addPoints(points: [startPoint, presentPoint])
        var showImage = false
        let deviation = currentPoint.minus(point: prevPoint)
        
        switch shapeType {
        case .line:
            switch sender.state {
            case .began:
                hideOption(isHidden: true)
                if let lineValue = closeToShapePoint(tapPoint: currentPoint) as? Line {
                    lineValue.newShape = false
                    line = lineValue
                    prevPoint = currentPoint
                } else if let lineValue = closeToShape(tapPoint: currentPoint) as? Line {
                    lineValue.newShape = false
                    line = lineValue
                    prevPoint = currentPoint
                } else {
                    line = Line(startPoint: currentPoint, endPoint: .zero)
                }
            case .changed:
                showImage = true
                guard let line else {
                    return
                }
                line.isSelected = true
                if line.newShape {
                    line.endPoint = currentPoint
                } else {
                    updateLine(line: line, deviation: deviation)
                    prevPoint = currentPoint
                }
                canvasView.line = line
            case .ended:
                hideOption(isHidden: false)
                showImage = true
                guard let line else {
                    return
                }
                line.isSelected = true
                if line.newShape {
                    line.endPoint = currentPoint
                    lines.append(line)
                } else {
                    updateLine(line: line, deviation: deviation)
                }
                self.line = nil
                canvasView.line = self.line
                canvasView.lines = lines
            default:
                break
            }
        case .rect:
            switch sender.state {
            case .began:
                hideOption(isHidden: true)
                if let rectValue = closeToShapePoint(tapPoint: currentPoint) as? Rectangle {
                    rectValue.newShape = false
                    rect = rectValue
                    prevPoint = currentPoint
                } else if let rectValue = closeToShape(tapPoint: currentPoint) as? Rectangle {
                    rectValue.newShape = false
                    rect = rectValue
                    prevPoint = currentPoint
                } else {
                    rect = Rectangle(pointA: currentPoint, pointB: .zero, pointC: .zero, pointD: .zero)
                }
            case .changed:
                showImage = true
                guard let rect else {
                    return
                }
                rect.isSelected = true
                if rect.newShape {
                    canvasView.rectangle = createRect(rect: rect, to: currentPoint)
                } else {
                    updateRect(rect: rect, deviation: deviation)
                    prevPoint = currentPoint
                }
                canvasView.rectangle = rect

            case .ended:
                hideOption(isHidden: false)
                showImage = true
                guard let rect else {
                    return
                }
                rect.isSelected = true
                if rect.newShape {
                    rectangles.append(createRect(rect: rect, to: currentPoint))
                } else {
                    updateRect(rect: rect, deviation: deviation)
                }
                self.rect = nil
                canvasView.rectangle = self.rect
                canvasView.rectangles = rectangles
            default:
                break
            }
        case .freehand:
            
            switch sender.state {
            case .began:
                hideOption(isHidden: true)
                if let freehandValue = closeToShapePoint(tapPoint: currentPoint) as? Freehand {
                    freehandValue.newShape = false
                    freehand = freehandValue
                    prevPoint = currentPoint
                } else if let freehandValue = closeToShape(tapPoint: currentPoint) as? Freehand {
                    freehandValue.newShape = false
                    freehand = freehandValue
                    prevPoint = currentPoint
                } else {
                    freehand = Freehand(pointArray: [currentPoint])
                }
            case .changed:
                showImage = true
                guard let freehand else {
                    return
                }
                freehand.isSelected = true
                if freehand.newShape {
                    freehand.pointArray.append(currentPoint)
                } else {
                    updateFreehand(freehand: freehand, deviation: deviation)
                    prevPoint = currentPoint
                }
                canvasView.freehand = freehand
            case .ended:
                hideOption(isHidden: false)
                showImage = true
                guard let freehand else {
                    return
                }
                freehand.isSelected = true
                if freehand.newShape {
                    freehand.pointArray.append(currentPoint)
                    freehands.append(freehand)
                } else {
                    updateFreehand(freehand: freehand, deviation: deviation)
                }
                self.freehand = nil
                canvasView.freehand = self.freehand
                canvasView.freehands = freehands
            default:
                break
            }
        }
        
        if showImage {
            canvasView.setNeedsDisplay()
        }
    }
 
}

extension CanvasViewController {
    //MARK:- Updating shapes values
    private func updateFreehand(freehand: Freehand, deviation: CGPoint) {
        freehand.pointArray = freehand.pointArray.map { item in
            CGPoint(x: item.x + deviation.x, y: item.y + deviation.y)
        }
    }
    
    private func updateLine(line: Line, deviation: CGPoint){
        if pointState == .none {
            line.startPoint = line.startPoint.add(point: deviation)
            line.endPoint = line.endPoint.add(point: deviation)
        } else if pointState == .startPoint {
            line.startPoint = line.startPoint.add(point: deviation)
        } else if pointState == .endPoint {
            line.endPoint = line.endPoint.add(point: deviation)
        }
    }
    
    
    private func updateRect(rect: Rectangle,deviation: CGPoint){
        if pointState == .none {
            if rectType == .moveArm {
                if selectedRectType == .ab {
                    rect.pointA = rect.pointA.add(point: deviation)
                    rect.pointB = rect.pointB.add(point: deviation)
                } else if selectedRectType == .bd {
                    rect.pointB = rect.pointB.add(point: deviation)
                    rect.pointD = rect.pointD.add(point: deviation)
                } else if selectedRectType == .dc {
                    rect.pointD = rect.pointD.add(point: deviation)
                    rect.pointC = rect.pointC.add(point: deviation)
                } else if selectedRectType == .ca {
                    rect.pointC = rect.pointC.add(point: deviation)
                    rect.pointA = rect.pointA.add(point: deviation)
                }
            } else {
                rect.pointA = rect.pointA.add(point: deviation)
                rect.pointD = rect.pointD.add(point: deviation)
                rect.pointB = rect.pointB.add(point: deviation)
                rect.pointC = rect.pointC.add(point: deviation)
            }
        } else if pointState == .pointA {
            rect.pointA = rect.pointA.add(point: deviation)
        } else if pointState == .pointB {
            rect.pointB = rect.pointB.add(point: deviation)
        } else if pointState == .pointC {
            rect.pointC = rect.pointC.add(point: deviation)
        } else if pointState == .pointD {
            rect.pointD = rect.pointD.add(point: deviation)
        }
    }

    private func isLineSideClose(pointA: CGPoint,pointB: CGPoint,tapPoint: CGPoint) -> Bool {
        abs(pointA.distance(point: tapPoint) + pointB.distance(point: tapPoint) - pointA.distance(point: pointB)) < 5
    }
    
    private func isCloseLine(line: Line,tapPoint: CGPoint) -> Line? {
        isLineSideClose(pointA: line.startPoint, pointB: line.endPoint, tapPoint: tapPoint) ? line : nil
    }
    
    private func isCloseRectBody(rect: Rectangle, tapPoint: CGPoint) -> Rectangle? {
        if isLineSideClose(pointA: rect.pointA, pointB: rect.pointB, tapPoint: tapPoint)
            || isLineSideClose(pointA: rect.pointB, pointB: rect.pointD, tapPoint: tapPoint)
            || isLineSideClose(pointA: rect.pointD, pointB: rect.pointC, tapPoint: tapPoint)
            || isLineSideClose(pointA: rect.pointC, pointB: rect.pointA, tapPoint: tapPoint) {
            return rect
        }
        return nil
    }
    
    private func isCloseFreehand(freehand: Freehand, tapPoint: CGPoint) -> Freehand? {
        for freehandPoint in freehand.pointArray {
            if freehandPoint.distance(point: tapPoint) < 25 {
                return freehand
            }
        }
        return nil
    }
    
    private func closeToShape(tapPoint: CGPoint) -> Any? {
        switch shapeType {
        case .line:
            for line in lines {
                if let closeLine = isCloseLine(line: line, tapPoint: tapPoint) {
                    return closeLine
                }
            }

        case .rect:
            switch rectType {
            case .moveShape:
                for rect in rectangles {
                    if let closeRect = isCloseRectBody(rect: rect, tapPoint: tapPoint) {
                        return closeRect
                    }
                }

            case .moveArm:
                return closeToRectSide(tapPoint: tapPoint)
            }
            
        case .freehand:
            for freehand in freehands {
                if let closeFreeHand = isCloseFreehand(freehand: freehand, tapPoint: tapPoint) {
                    return closeFreeHand
                }
            }

        }
        return nil
    }
    
    private func closeToShapePoint(tapPoint: CGPoint) -> Any? {
        
        let proximity: CGFloat = 20
        switch shapeType {
        case .line:
            var isSelected = true
            for line in lines {
                if line.startPoint.distance(point: tapPoint) < proximity {
                    pointState = .startPoint
                } else if line.endPoint.distance(point: tapPoint) < proximity {
                    pointState = .endPoint
                } else {
                    isSelected = false
                }
                if isSelected {
                    return line
                }
            }
            
        case .rect:
            var isSelected = true
            for rect in rectangles {
                if rect.pointA.distance(point: tapPoint) < proximity {
                    pointState = .pointA
                } else if rect.pointB.distance(point: tapPoint) < proximity {
                    pointState = .pointB
                } else if rect.pointC.distance(point: tapPoint) < proximity {
                    pointState = .pointC
                } else if rect.pointD.distance(point: tapPoint) < proximity {
                    pointState = .pointD
                } else {
                    isSelected = false
                }
                if isSelected {
                    return rect
                }
            }
            
        case .freehand:
            break
        }
        pointState = .none
        return nil
    }
    
    private func closeToRectSide(tapPoint: CGPoint) -> Rectangle? {
        for rect in rectangles {
            if isLineSideClose(pointA: rect.pointA, pointB: rect.pointB, tapPoint: tapPoint) {
                selectedRectType = .ab
            } else if isLineSideClose(pointA: rect.pointB, pointB: rect.pointD, tapPoint: tapPoint) {
                selectedRectType = .bd
            } else if isLineSideClose(pointA: rect.pointD, pointB: rect.pointC, tapPoint: tapPoint) {
                selectedRectType = .dc
            } else if isLineSideClose(pointA: rect.pointC, pointB: rect.pointA, tapPoint: tapPoint) {
                selectedRectType = .ca
            } else {
                selectedRectType = .none
            }
            if selectedRectType != .none {
                return rect
            }
        }
        return nil
    }
}
