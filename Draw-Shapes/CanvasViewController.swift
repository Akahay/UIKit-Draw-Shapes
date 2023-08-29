//
//  ViewController.swift
//  Draw-Shapes
//
//  Created by Akshay Naithani on 30/08/23.
//

import UIKit

enum SelectedShape {
    case line(value: LineModel)
    case rectangle(value: RectangleModel)
    case freehand(value: FreehandModel)
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

    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var panGestureRecognizer: UIPanGestureRecognizer?

    private var selectedShape: SelectedShape = .none
    private var startPoint: CGPoint = .zero
    private var prevPoint: CGPoint = .zero

    private var newLine: LineModel?
    private var newRect: RectangleModel?
    private var newFreehand: FreehandModel?

    private var lineArray: [LineModel] = []
    private var rectArray: [RectangleModel] = []
    private var freehandArray: [FreehandModel] = []
    
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
            lineArray = lineArray.filter { $0.uuid != value.uuid }
            newLine = nil
        case .rectangle(let value):
            rectArray = rectArray.filter { $0.uuid != value.uuid }
            newRect = nil
        case .freehand(let value):
            freehandArray = freehandArray.filter { $0.uuid != value.uuid }
            newFreehand = nil
        case .none:
            return
        }
        
        emptyIndivisualShape()
        assignToCanvasIndivisualShape()
        assignToCanvasShapeArray()
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
        self.tapGestureRecognizer = tapGestureRecognizer
        
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
    private func addPoints(points: [CGPoint])->CGPoint{
        var resultPoint: CGPoint = .zero
        for point in points{
            resultPoint.x = resultPoint.x + point.x
            resultPoint.y = resultPoint.y + point.y
        }
        return resultPoint
    }
    private func assignToCanvasIndivisualShape(){
        canvasView.lineModel = newLine
        canvasView.rectModel = newRect
        canvasView.freehandModel = newFreehand
    }
    private func emptyIndivisualShape(){
        newLine = nil
        newRect = nil
        newFreehand = nil
    }
    private func assignToCanvasShapeArray(){
        canvasView.drawFreehands = freehandArray
        canvasView.drawLines = lineArray
        canvasView.drawRects = rectArray
    }

    func hideOption(isHidden: Bool){
        shapesOptionStackView.isHidden = isHidden
        addPhotoButton.isHidden = isHidden
    }
    
    private func createRect(rect: RectangleModel,to point: CGPoint) -> RectangleModel{
        rect.pointD = point
        rect.pointC = CGPoint(x: point.x, y:  rect.pointA.y)
        rect.pointB = CGPoint(x: rect.pointA.x, y: point.y)
        return rect
    }
    
    private func deselectAllShapes(){
        for line in lineArray {
            line.isSelected = false
        }
        for rect in rectArray {
            rect.isSelected = false
        }
        for freehand in freehandArray {
            freehand.isSelected = false
        }
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
            if let lineValue = closeToShape(tapPoint: currentPoint) as? LineModel {
                lineValue.isSelected = true
                selectedShape = .line(value: lineValue)
                isBottomViewHidden = false
            }
        case .rect:
            if let rectValue = closeToShape(tapPoint: currentPoint) as? RectangleModel {
                rectValue.isSelected = true
                selectedShape = .rectangle(value: rectValue)
                isBottomViewHidden = false
            }

        case .freehand:
            if let freehandValue = closeToShape(tapPoint: currentPoint) as? FreehandModel {
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
        switch sender.state {
        case .began:
            hideOption(isHidden: true)
            switch shapeType {
            case .line:
                if let lineValue = closeToShapePoint(tapPoint: currentPoint) as? LineModel {
                    lineValue.newShape = false
                    newLine = lineValue
                    prevPoint = currentPoint
                } else if let lineValue = closeToShape(tapPoint: currentPoint) as? LineModel {
                    lineValue.newShape = false
                    newLine = lineValue
                    prevPoint = currentPoint
                } else {
                    newLine = LineModel(startPoint: currentPoint, endPoint: .zero)
                }
                
            case .rect:
                if let rectValue = closeToShapePoint(tapPoint: currentPoint) as? RectangleModel {
                    rectValue.newShape = false
                    newRect = rectValue
                    prevPoint = currentPoint
                } else if let rectValue = closeToShape(tapPoint: currentPoint) as? RectangleModel {
                    rectValue.newShape = false
                    newRect = rectValue
                    prevPoint = currentPoint
                } else {
                    newRect = RectangleModel(pointA: currentPoint, pointB: .zero, pointC: .zero, pointD: .zero)
                }
                
            case .freehand:
                if let freehandValue = closeToShapePoint(tapPoint: currentPoint) as? FreehandModel {
                    freehandValue.newShape = false
                    newFreehand = freehandValue
                    prevPoint = currentPoint
                } else if let freehandValue = closeToShape(tapPoint: currentPoint) as? FreehandModel {
                    freehandValue.newShape = false
                    newFreehand = freehandValue
                    prevPoint = currentPoint
                } else {
                    newFreehand = FreehandModel(pointArray: [currentPoint])
                }
            }
            
        case .changed:
            showImage = true
            switch shapeType {
            case .line:
                guard let newLine else {
                    return
                }
                newLine.isSelected = true
                if newLine.newShape {
                    newLine.endPoint = currentPoint
                } else {
                    updateLine(line: newLine, deviation: deviation)
                    prevPoint = currentPoint
                }
                
            case .rect:
                guard let newRect else {
                    return
                }
                newRect.isSelected = true
                if newRect.newShape {
                    canvasView.rectModel = createRect(rect: newRect, to: currentPoint)
                } else {
                    updateRect(rect: newRect, deviation: deviation)
                    prevPoint = currentPoint
                }
                
            case .freehand:
                guard let newFreehand else {
                    return
                }
                newFreehand.isSelected = true
                if newFreehand.newShape {
                    newFreehand.pointArray.append(currentPoint)
                } else {
                    updateFreehand(freehand: newFreehand, deviation: deviation)
                    prevPoint = currentPoint
                }
            }
            assignToCanvasIndivisualShape()
            
        case .ended:
            hideOption(isHidden: false)
            showImage = true
            switch shapeType {
            case .line:
                guard let newLine else {
                    return
                }
                newLine.isSelected = true
                if newLine.newShape {
                    newLine.endPoint = currentPoint
                    lineArray.append(newLine)
                } else {
                    updateLine(line: newLine, deviation: deviation)
                }
                
            case .rect:
                guard let newRect else {
                    return
                }
                newRect.isSelected = true
                if newRect.newShape {
                    let rect = createRect(rect: newRect, to: currentPoint)
                    rectArray.append(rect)
                } else {
                    updateRect(rect: newRect, deviation: deviation)
                }
                
            case .freehand:
                guard let newFreehand else {
                    return
                }
                newFreehand.isSelected = true
                if newFreehand.newShape {
                    newFreehand.pointArray.append(currentPoint)
                    freehandArray.append(newFreehand)
                } else {
                    updateFreehand(freehand: newFreehand, deviation: deviation)
                }
                
            }
            emptyIndivisualShape()
            assignToCanvasIndivisualShape()
            assignToCanvasShapeArray()
            
        default:
            break
        }
        if showImage{
            canvasView.setNeedsDisplay()
        }
        
    }
    private func printLines(){
        print("Lines:")
        for line in lineArray{
            print("\(line) startPoint:\(line.startPoint) endPoint:\(line.endPoint)")
        }
    }
    private func printRects(){
        print("Rectangles:")
        for rect in rectArray{
            print("\(rect) pointA:\(rect.pointA) pointB:\(rect.pointB) pointC:\(rect.pointC) pointD:\(rect.pointD)")
        }
    }
    func printAllShapes(){
        printLines()
        printRects()
    }
 
}

extension CanvasViewController {
    //MARK:- Updating shapes values
    private func updateFreehand(freehand: FreehandModel,deviation: CGPoint) {
        freehand.pointArray = freehand.pointArray.map { item in
            CGPoint(x: item.x + deviation.x, y: item.y + deviation.y)
        }
    }
    
    private func updateLine(line: LineModel,deviation: CGPoint){
        if pointState == .none {
            line.startPoint = line.startPoint.add(point: deviation)
            line.endPoint = line.endPoint.add(point: deviation)
        } else if pointState == .startPoint {
            line.startPoint = line.startPoint.add(point: deviation)
        } else if pointState == .endPoint {
            line.endPoint = line.endPoint.add(point: deviation)
        }
        
    }
    
    
    private func updateRect(rect: RectangleModel,deviation: CGPoint){
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
    
    private func isCloseLine(line: LineModel,tapPoint: CGPoint) -> LineModel? {
        isLineSideClose(pointA: line.startPoint, pointB: line.endPoint, tapPoint: tapPoint) ? line : nil
    }
    
    private func isCloseRectBody(rect: RectangleModel, tapPoint: CGPoint) -> RectangleModel? {
        if isLineSideClose(pointA: rect.pointA, pointB: rect.pointB, tapPoint: tapPoint)
            || isLineSideClose(pointA: rect.pointB, pointB: rect.pointD, tapPoint: tapPoint)
            || isLineSideClose(pointA: rect.pointD, pointB: rect.pointC, tapPoint: tapPoint)
            || isLineSideClose(pointA: rect.pointC, pointB: rect.pointA, tapPoint: tapPoint) {
            return rect
        }
        return nil
    }
    
    private func isCloseFreehand(freehand: FreehandModel,tapPoint: CGPoint)->FreehandModel? {
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
            for line in lineArray {
                if let closeLine = isCloseLine(line: line, tapPoint: tapPoint) {
                    return closeLine
                }
            }

        case .rect:
            switch rectType {
            case .moveShape:
                for rect in rectArray {
                    if let closeRect = isCloseRectBody(rect: rect, tapPoint: tapPoint) {
                        return closeRect
                    }
                }

            case .moveArm:
                return closeToRectSide(tapPoint: tapPoint)
            }
            
        case .freehand:
            for freehand in freehandArray {
                if let closeFreeHand = isCloseFreehand(freehand: freehand, tapPoint: tapPoint) {
                    return closeFreeHand
                }
            }

        }
        return nil
    }
    
    private func closeToShapePoint(tapPoint: CGPoint) -> Any? {
        var isSelected = false
        let proximity: CGFloat = 20
        switch shapeType {
        case .line:
            for line in lineArray {
                if line.startPoint.distance(point: tapPoint) < proximity {
                    isSelected = true
                    pointState = .startPoint
                } else if line.endPoint.distance(point: tapPoint) < proximity {
                    isSelected = true
                    pointState = .endPoint
                }
                if isSelected {
                    return line
                }
            }
            
        case .rect:
            for rect in rectArray {
                if rect.pointA.distance(point: tapPoint) < proximity {
                    isSelected = true
                    pointState = .pointA
                } else if rect.pointB.distance(point: tapPoint) < proximity {
                    isSelected = true
                    pointState = .pointB
                } else if rect.pointC.distance(point: tapPoint) < proximity {
                    isSelected = true
                    pointState = .pointC
                } else if rect.pointD.distance(point: tapPoint) < proximity {
                    isSelected = true
                    pointState = .pointD
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
    
    private func closeToRectSide(tapPoint: CGPoint) -> RectangleModel? {
        for rect in rectArray {
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
