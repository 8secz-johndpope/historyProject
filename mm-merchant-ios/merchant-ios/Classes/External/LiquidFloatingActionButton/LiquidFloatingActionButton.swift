//
//  LiquidFloatingActionButton.swift
//  Pods
//
//  Created by Takuma Yoshida on 2015/08/25.
//
//

import Foundation
import QuartzCore

// LiquidFloatingButton DataSource methods
@objc public protocol LiquidFloatingActionButtonDataSource {
    func numberOfCells(_ liquidFloatingActionButton: LiquidFloatingActionButton) -> Int
    func cellForIndex(_ index: Int) -> LiquidFloatingCell
}

@objc public protocol LiquidFloatingActionButtonDelegate {
    // selected method
    @objc optional func liquidFloatingActionButton(_ liquidFloatingActionButton: LiquidFloatingActionButton, didSelectItemAtIndex index: Int)
}

public enum LiquidFloatingActionButtonAnimateStyle : Int {
    case up
    case right
    case left
    case down
}

@IBDesignable
open class LiquidFloatingActionButton : UIView, CAAnimationDelegate {

    private let internalRadiusRatio: CGFloat = 20.0 / 56.0
    open var cellRadiusRatio: CGFloat      = 0.38
    open var animateStyle: LiquidFloatingActionButtonAnimateStyle = .up {
        didSet {
            baseView.animateStyle = animateStyle
        }
    }
    open var enableShadow = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    open weak var delegate:   LiquidFloatingActionButtonDelegate?
    open weak var dataSource: LiquidFloatingActionButtonDataSource?

    open var responsible = true
    open var isOpening: Bool  {
        get {
            return !baseView.openingCells.isEmpty
        }
    }
    open var isClosed: Bool {
        get {
            return plusRotation == 0
        }
    }

    @IBInspectable open var color: UIColor = UIColor.primary1() {
        didSet {
            baseView.color = color
        }
    }

    private let plusLayer   = CAShapeLayer()
    private let circleLayer = CAShapeLayer()

    private var touching = false
    private var plusRotation: CGFloat = 0

    private var baseView = CircleLiquidBaseView()
    private let liquidView = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func insertCell(_ cell: LiquidFloatingCell) {
        cell.color  = self.color
        cell.radius = self.frame.width * cellRadiusRatio
        cell.center = self.center.minus(self.frame.origin)
        cell.actionButton = self
        insertSubview(cell, aboveSubview: baseView)
    }
    
    private func cellArray() -> [LiquidFloatingCell] {
        var result: [LiquidFloatingCell] = []
        if let source = dataSource {
            for i in 0..<source.numberOfCells(self) {
                result.append(source.cellForIndex(i))
            }
        }
        return result
    }

    // open all cells
    open func open() {
        // rotate plus icon
        self.plusLayer.add(plusKeyframe(true), forKey: "plusRot")
        self.plusRotation = CGFloat.pi * 0.25 // 45 degree

        let cells = cellArray()
        for cell in cells {
            insertCell(cell)
        }

        self.baseView.open(cells)
        setNeedsDisplay()
    }

    // close all cells
    open func close() {
        // rotate plus icon
        self.plusLayer.add(plusKeyframe(false), forKey: "plusRot")
        self.plusRotation = 0
    
        self.baseView.close(cellArray())
        setNeedsDisplay()
    }

    // MARK: draw icon
    open override func draw(_ rect: CGRect) {
        drawCircle()
        drawShadow()
        drawPlus(plusRotation)
    }
    
    private func drawCircle() {
        self.circleLayer.frame = CGRect(origin: CGPoint.zero, size: self.frame.size)
        self.circleLayer.cornerRadius = self.frame.width * 0.5
        self.circleLayer.masksToBounds = true
        if touching && responsible {
            self.circleLayer.backgroundColor = self.color.white(0.5).cgColor
        } else {
            self.circleLayer.backgroundColor = self.color.cgColor
        }
    }
    
    private func drawPlus(_ rotation: CGFloat) {
        plusLayer.frame = CGRect(origin: CGPoint.zero, size: self.frame.size)
        plusLayer.lineCap = kCALineCapRound
        plusLayer.strokeColor = UIColor.white.cgColor // TODO: customizable
        plusLayer.lineWidth = 3.0

        plusLayer.path = pathPlus(rotation).cgPath
    }
    
    private func drawShadow() {
        if enableShadow {
            circleLayer.appendShadow()
        }
    }
    
    // draw button plus or close face
    private func pathPlus(_ rotation: CGFloat) -> UIBezierPath {
        let radius = self.frame.width * internalRadiusRatio * 0.5
        let center = self.center.minus(self.frame.origin)
        let points = [
            CGMath.circlePoint(center, radius: radius, rad: rotation),
            CGMath.circlePoint(center, radius: radius, rad: CGFloat.pi + rotation),
            CGMath.circlePoint(center, radius: radius, rad:  CGFloat.pi * 2 + rotation),
            CGMath.circlePoint(center, radius: radius, rad:  CGFloat.pi * 3 + rotation)
        ]
        let path = UIBezierPath()
        path.move(to: points[0])
        path.addLine(to: points[2])
        path.move(to: points[1])
        path.addLine(to: points[3])
        return path
    }
    
    private func plusKeyframe(_ closed: Bool) -> CAKeyframeAnimation {
        let paths = closed ? [
                pathPlus(CGFloat.pi * 0),
                pathPlus(CGFloat.pi * 0.125),
                pathPlus(CGFloat.pi * 0.25),
        ] : [
                pathPlus(CGFloat.pi * 0.25),
                pathPlus(CGFloat.pi * 0.125),
                pathPlus(CGFloat.pi * 0),
        ]
        let anim = CAKeyframeAnimation(keyPath: "path")
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        anim.values = paths.map { $0.cgPath }
        anim.duration = 0.5
        anim.isRemovedOnCompletion = true
        anim.fillMode = kCAFillModeForwards
        anim.delegate = self
        return anim
    }

    // MARK: Events
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touching = true
        setNeedsDisplay()
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touching = false
        setNeedsDisplay()
        didTapped()
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        self.touching = false
        setNeedsDisplay()
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for cell in cellArray() {
            let pointForTargetView = cell.convert(point, from: self)
            
            if (cell.bounds.contains(pointForTargetView)) {
                if cell.isUserInteractionEnabled {
                    return cell.hitTest(pointForTargetView, with: event)
                }
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    // MARK: private methods
    private func setup() {
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = false

        baseView.setup(self)
        addSubview(baseView)
        
        liquidView.frame = baseView.frame
        liquidView.isUserInteractionEnabled = false
        addSubview(liquidView)
        
        liquidView.layer.addSublayer(circleLayer)
        circleLayer.addSublayer(plusLayer)
    }

    private func didTapped() {
        if isClosed {
            open()
        } else {
            close()
        }
    }
    
    open func didTappedCell(_ target: LiquidFloatingCell) {
        if let _ = dataSource {
            let cells = cellArray()
            for i in 0..<cells.count {
                let cell = cells[i]
                if target === cell {
                    delegate?.liquidFloatingActionButton?(self, didSelectItemAtIndex: i)
                }
            }
        }
    }

}

class ActionBarBaseView : UIView {
    var opening = false
    func setup(_ actionButton: LiquidFloatingActionButton) {
    }
    
    func translateY(_ layer: CALayer, duration: CFTimeInterval, f: (CABasicAnimation) -> ()) {
        let translate = CABasicAnimation(keyPath: "transform.translation.y")
        f(translate)
        translate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        translate.isRemovedOnCompletion = false
        translate.fillMode = kCAFillModeForwards
        translate.duration = duration
        layer.add(translate, forKey: "transYAnim")
    }
}

class CircleLiquidBaseView : ActionBarBaseView {

    let openDuration: CGFloat  = 0.6
    let closeDuration: CGFloat = 0.2
    let viscosity: CGFloat     = 0.65
    var animateStyle: LiquidFloatingActionButtonAnimateStyle = .up
    var color: UIColor = UIColor.primary1() {
        didSet {
            engine?.color = color
            bigEngine?.color = color
        }
    }

    var baseLiquid: LiquittableCircle?
    var engine:     SimpleCircleLiquidEngine?
    var bigEngine:  SimpleCircleLiquidEngine?
    var enableShadow = true

    var openingCells: [LiquidFloatingCell] = []
    private var keyDuration: CGFloat = 0
    private var displayLink: CADisplayLink?

    override func setup(_ actionButton: LiquidFloatingActionButton) {
        self.frame = actionButton.frame
        self.center = actionButton.center.minus(actionButton.frame.origin)
        self.animateStyle = actionButton.animateStyle
        let radius = min(self.frame.width, self.frame.height) * 0.5
        self.engine = SimpleCircleLiquidEngine(radiusThresh: radius * 0.73, angleThresh: 0.45)
        engine?.viscosity = viscosity
        self.bigEngine = SimpleCircleLiquidEngine(radiusThresh: radius, angleThresh: 0.55)
        bigEngine?.viscosity = viscosity
        self.engine?.color = actionButton.color
        self.bigEngine?.color = actionButton.color

        baseLiquid = LiquittableCircle(center: self.center.minus(self.frame.origin), radius: radius, color: actionButton.color)
        baseLiquid?.clipsToBounds = false
        baseLiquid?.layer.masksToBounds = false
        
        clipsToBounds = false
        layer.masksToBounds = false
        addSubview(baseLiquid!)
    }

    func open(_ cells: [LiquidFloatingCell]) {
        stop()
        displayLink = CADisplayLink(target: self, selector: #selector(CircleLiquidBaseView.didDisplayRefresh))
        displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        opening = true
        for cell in cells {
            cell.layer.removeAllAnimations()
            cell.layer.eraseShadow()
            openingCells.append(cell)
        }
    }
    
    func close(_ cells: [LiquidFloatingCell]) {
        stop()
        opening = false
        displayLink = CADisplayLink(target: self, selector: #selector(CircleLiquidBaseView.didDisplayRefresh))
        displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        for cell in cells {
            cell.layer.removeAllAnimations()
            cell.layer.eraseShadow()
            openingCells.append(cell)
            cell.isUserInteractionEnabled = false
        }
    }

    func didFinishUpdate() {
        if opening {
            for cell in openingCells {
                cell.isUserInteractionEnabled = true
            }
        } else {
            for cell in openingCells {
                cell.removeFromSuperview()
            }
        }
        displayLink?.invalidate()
    }

    func update(_ delay: CGFloat, duration: CGFloat, f: (LiquidFloatingCell, Int, CGFloat) -> ()) {
        if openingCells.isEmpty {
            return
        }

        let maxDuration = duration + CGFloat(openingCells.count) * CGFloat(delay)
        let t = keyDuration
        let allRatio = easeInEaseOut(t / maxDuration)

        if allRatio >= 1.0 {
            didFinishUpdate()
            stop()
            return
        }

        engine?.clear()
        bigEngine?.clear()
        for i in 0..<openingCells.count {
            let liquidCell = openingCells[i]
            let cellDelay = CGFloat(delay) * CGFloat(i)
            let ratio = easeInEaseOut((t - cellDelay) / duration)
            f(liquidCell, i, ratio)
        }

        if let firstCell = openingCells.first {
            bigEngine?.push(baseLiquid!, other: firstCell)
        }
        for i in 1..<openingCells.count {
            let prev = openingCells[i - 1]
            let cell = openingCells[i]
            engine?.push(prev, other: cell)
        }
        engine?.draw(baseLiquid!)
        bigEngine?.draw(baseLiquid!)
    }
    
    func updateOpen() {
        update(0.1, duration: openDuration) { cell, i, ratio in
            let posRatio = ratio > CGFloat(i) / CGFloat(self.openingCells.count) ? ratio : 0
            let distance = (cell.frame.height * 0.5 + CGFloat(i + 1) * cell.frame.height * 1.5) * posRatio
            cell.center = self.center.plus(self.differencePoint(distance))
            cell.update(ratio, open: true)
        }
    }
    
    func updateClose() {
        update(0, duration: closeDuration) { cell, i, ratio in
            let distance = (cell.frame.height * 0.5 + CGFloat(i + 1) * cell.frame.height * 1.5) * (1 - ratio)
            cell.center = self.center.plus(self.differencePoint(distance))
            cell.update(ratio, open: false)
        }
    }
    
    func differencePoint(_ distance: CGFloat) -> CGPoint {
        switch animateStyle {
        case .up:
            return CGPoint(x: 0, y: -distance)
        case .right:
            return CGPoint(x: distance, y: 0)
        case .left:
            return CGPoint(x: -distance, y: 0)
        case .down:
            return CGPoint(x: 0, y: distance)
        }
    }
    
    func stop() {
        for cell in openingCells {
            if enableShadow {
                cell.layer.appendShadow()
            }
        }
        openingCells = []
        keyDuration = 0
        displayLink?.invalidate()
    }
    
    func easeInEaseOut(_ t: CGFloat) -> CGFloat {
        if t >= 1.0 {
            return 1.0
        }
        if t < 0 {
            return 0
        }
        return -1 * t * (t - 2)
    }
    
    @objc func didDisplayRefresh(_ displayLink: CADisplayLink) {
        if opening {
            keyDuration += CGFloat(displayLink.duration)
            updateOpen()
        } else {
            keyDuration += CGFloat(displayLink.duration)
            updateClose()
        }
    }

}

open class LiquidFloatingCell : LiquittableCircle {
    
    let internalRatio: CGFloat = 0.75

    open var responsible = true
    open var imageView = UIImageView()
    weak var actionButton: LiquidFloatingActionButton?

    // for implement responsible color
    private var originalColor: UIColor
    
    open override var frame: CGRect {
        didSet {
            resizeSubviews()
        }
    }

    init(center: CGPoint, radius: CGFloat, color: UIColor, icon: UIImage) {
        self.originalColor = color
        super.init(center: center, radius: radius, color: color)
        setup(icon)
    }

    init(center: CGPoint, radius: CGFloat, color: UIColor, view: UIView) {
        self.originalColor = color
        super.init(center: center, radius: radius, color: color)
        setupView(view)
    }
    
    public init(icon: UIImage) {
        self.originalColor = UIColor.clear
        super.init()
        setup(icon)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(_ image: UIImage, tintColor: UIColor = UIColor.white) {
        imageView.image = image.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        imageView.tintColor = tintColor
        setupView(imageView)
    }
    
    open func setupView(_ view: UIView) {
        isUserInteractionEnabled = false
        addSubview(view)
        resizeSubviews()
    }
    
    private func resizeSubviews() {
        let size = CGSize(width: frame.width * 0.5, height: frame.height * 0.5)
        imageView.frame = CGRect(x: frame.width - frame.width * internalRatio, y: frame.height - frame.height * internalRatio, width: size.width, height: size.height)
    }
    
    func update(_ key: CGFloat, open: Bool) {
        for subview in self.subviews {
            let ratio = max(2 * (key * key - 0.5), 0)
            subview.alpha = open ? ratio : -ratio
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if responsible {
            originalColor = color
            color = originalColor.white(0.5)
            setNeedsDisplay()
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        if responsible {
            color = originalColor
            setNeedsDisplay()
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        color = originalColor
        actionButton?.didTappedCell(self)
    }

}
