//
//  FTPopOverMenu.swift
//  FTPopOverMenu
//
//  Created by liufengting on 16/11/2016.
//  Copyright © 2016 LiuFengting (https://github.com/liufengting) . All rights reserved.
//

import UIKit

public extension FTPopOverMenu {
    class func showForSender(sender: UIView, with menuArray: [FTMenuObject], menuImageArray: [Imageable]? = nil, popOverPosition: FTPopOverPosition = .automatic, config: FTConfiguration? = nil, done: ((NSInteger) -> Void)?, cancel: (() -> Void)? = nil) {
        FTPopOverMenu.shared.showForSender(sender: sender, or: nil, with: menuArray, menuImageArray: menuImageArray, popOverPosition: popOverPosition, config: config, done: done, cancel: cancel)
    }

    class func showForEvent(event: UIEvent, with menuArray: [FTMenuObject], menuImageArray: [Imageable]? = nil, popOverPosition: FTPopOverPosition = .automatic, config: FTConfiguration? = nil, done: ((NSInteger) -> Void)?, cancel: (() -> Void)? = nil) {
        FTPopOverMenu.shared.showForSender(sender: event.allTouches?.first?.view!, or: nil, with: menuArray, menuImageArray: menuImageArray, popOverPosition: popOverPosition, config: config, done: done, cancel: cancel)
    }

    class func showFromSenderFrame(senderFrame: CGRect, with menuArray: [FTMenuObject], menuImageArray: [Imageable]? = nil, popOverPosition: FTPopOverPosition = .automatic, config: FTConfiguration? = nil, done: ((NSInteger) -> Void)?, cancel: (() -> Void)? = nil) {
        FTPopOverMenu.shared.showForSender(sender: nil, or: senderFrame, with: menuArray, menuImageArray: menuImageArray, popOverPosition: popOverPosition, config: config, done: done, cancel: cancel)
    }
}

private enum FTPopOverMenuArrowDirection {
    case up
    case down
}

public enum FTPopOverPosition {
    case automatic
    case alwaysAboveSender
    case alwaysUnderSender
}

public class FTPopOverMenu: NSObject, FTPopOverMenuViewDelegate {
    var sender: UIView?
    var senderFrame: CGRect?
    var menuNameArray: [FTMenuObject]!
    var menuImageArray: [Imageable]!
    var done: ((Int) -> Void)?
    var cancel: (() -> Void)?
    var configuration = FTConfiguration()
    var popOverPosition: FTPopOverPosition = .automatic

    fileprivate lazy var backgroundView: UIView = {
        let view = UIView(frame: UIScreen.main.bounds)
        if let adapter = self.configuration.globalShadowAdapter {
            adapter(view)
        } else {
            if self.configuration.globalShadow {
                view.backgroundColor = UIColor.black.withAlphaComponent(self.configuration.shadowAlpha)
            }
        }
        view.addGestureRecognizer(self.tapGesture)
        return view
    }()

    fileprivate lazy var popOverMenuView: FTPopOverMenuView = {
        let menu = FTPopOverMenuView(frame: CGRect.zero)
        menu.alpha = 0
        self.backgroundView.addSubview(menu)
        return menu
    }()

    fileprivate var isOnScreen: Bool = false {
        didSet {
            if isOnScreen {
                addOrientationChangeNotification()
            } else {
                removeOrientationChangeNotification()
            }
        }
    }

    fileprivate lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onBackgroudViewTapped(gesture:)))
        gesture.delegate = self
        return gesture
    }()

    class var shared: FTPopOverMenu {
        struct Manager {
            static let instance = FTPopOverMenu()
        }
        return Manager.instance
    }

    public func showForSender(sender: UIView?, or senderFrame: CGRect?, with menuNameArray: [FTMenuObject]!, menuImageArray: [Imageable]? = nil, popOverPosition: FTPopOverPosition = .automatic, config: FTConfiguration? = nil, done: ((Int) -> Void)?, cancel: (() -> Void)? = nil) {
        if sender == nil, senderFrame == nil {
            return
        }
        if menuNameArray.count == 0 {
            return
        }

        self.sender = sender
        self.senderFrame = senderFrame
        self.menuNameArray = menuNameArray
        self.menuImageArray = menuImageArray
        self.popOverPosition = popOverPosition
        configuration = config ?? FTConfiguration()
        self.done = done
        self.cancel = cancel

        UIApplication.shared.keyWindow?.addSubview(backgroundView)
        adjustPostionForPopOverMenu()
    }

    public func dismiss() {
        doneActionWithSelectedIndex(selectedIndex: -1)
    }

    fileprivate func adjustPostionForPopOverMenu() {
        backgroundView.frame = CGRect(x: 0, y: 0, width: UIScreen.ft_width(), height: UIScreen.ft_height())

        setupPopOverMenu()

        showIfNeeded()
    }

    fileprivate func setupPopOverMenu() {
        popOverMenuView.delegate = self
        popOverMenuView.transform = CGAffineTransform(scaleX: 1, y: 1)

        configurePopMenuFrame()

        popOverMenuView.showWithAnglePoint(point: menuArrowPoint,
                                           frame: popMenuFrame,
                                           menuNameArray: menuNameArray,
                                           menuImageArray: menuImageArray,
                                           config: configuration,
                                           arrowDirection: arrowDirection,
                                           delegate: self)

        popOverMenuView.setAnchorPoint(anchorPoint: getAnchorPointForPopMenu())
    }

    fileprivate func getAnchorPointForPopMenu() -> CGPoint {
        var anchorPoint = CGPoint(x: menuArrowPoint.x / popMenuFrame.size.width, y: 0)
        if arrowDirection == .down {
            anchorPoint = CGPoint(x: menuArrowPoint.x / popMenuFrame.size.width, y: 1)
        }
        return anchorPoint
    }

    fileprivate var senderRect: CGRect = CGRect.zero
    fileprivate var popMenuOriginX: CGFloat = 0
    fileprivate var popMenuFrame: CGRect = CGRect.zero
    fileprivate var menuArrowPoint: CGPoint = CGPoint.zero
    fileprivate var arrowDirection: FTPopOverMenuArrowDirection = .up
    fileprivate var popMenuHeight: CGFloat {
        return configuration.menuRowHeight * CGFloat(menuNameArray.count) + FT.DefaultMenuArrowHeight
    }

    fileprivate func configureSenderRect() {
        if let sender = sender {
            if let superView = sender.superview {
                senderRect = superView.convert(sender.frame, to: backgroundView)
            }
        } else if let frame = senderFrame {
            senderRect = frame
        }
        senderRect.origin.y = min(UIScreen.ft_height(), senderRect.origin.y)

        if popOverPosition == .alwaysAboveSender {
            arrowDirection = .down
        } else if popOverPosition == .alwaysUnderSender {
            arrowDirection = .up
        } else {
            if senderRect.origin.y + senderRect.size.height / 2 < UIScreen.ft_height() / 2 {
                arrowDirection = .up
            } else {
                arrowDirection = .down
            }
        }
    }

    fileprivate func configurePopMenuOriginX() {
        var senderXCenter: CGPoint = CGPoint(x: senderRect.origin.x + (senderRect.size.width) / 2, y: 0)
        let menuCenterX: CGFloat = configuration.menuWidth / 2 + FT.DefaultMargin
        var menuX: CGFloat = 0
        if senderXCenter.x + menuCenterX > UIScreen.ft_width() {
            senderXCenter.x = min(senderXCenter.x - (UIScreen.ft_width() - configuration.menuWidth - FT.DefaultMargin), configuration.menuWidth - FT.DefaultMenuArrowWidth - FT.DefaultMargin)
            menuX = UIScreen.ft_width() - configuration.menuWidth - FT.DefaultMargin
        } else if senderXCenter.x - menuCenterX < 0 {
            senderXCenter.x = max(FT.DefaultMenuCornerRadius + FT.DefaultMenuArrowWidth, senderXCenter.x - FT.DefaultMargin)
            menuX = FT.DefaultMargin
        } else {
            senderXCenter.x = configuration.menuWidth / 2
            menuX = senderRect.origin.x + (senderRect.size.width) / 2 - configuration.menuWidth / 2
        }
        popMenuOriginX = menuX
    }

    fileprivate func configurePopMenuFrame() {
        configureSenderRect()
        configureMenuArrowPoint()
        configurePopMenuOriginX()

        var safeAreaInset = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            safeAreaInset = UIApplication.shared.keyWindow?.safeAreaInsets ?? UIEdgeInsets.zero
        }

        if arrowDirection == .up {
            popMenuFrame = CGRect(x: popMenuOriginX, y: senderRect.origin.y + senderRect.size.height, width: configuration.menuWidth, height: popMenuHeight)
            if popMenuFrame.origin.y + popMenuFrame.size.height > UIScreen.ft_height() - safeAreaInset.bottom {
                popMenuFrame = CGRect(x: popMenuOriginX, y: senderRect.origin.y + senderRect.size.height, width: configuration.menuWidth, height: UIScreen.ft_height() - popMenuFrame.origin.y - FT.DefaultMargin - safeAreaInset.bottom)
            }
        } else {
            popMenuFrame = CGRect(x: popMenuOriginX, y: senderRect.origin.y - popMenuHeight, width: configuration.menuWidth, height: popMenuHeight)
            if popMenuFrame.origin.y < safeAreaInset.top {
                popMenuFrame = CGRect(x: popMenuOriginX, y: FT.DefaultMargin + safeAreaInset.top, width: configuration.menuWidth, height: senderRect.origin.y - FT.DefaultMargin - safeAreaInset.top)
            }
        }
    }

    fileprivate func configureMenuArrowPoint() {
        var point: CGPoint = CGPoint(x: senderRect.origin.x + (senderRect.size.width) / 2, y: 0)
        let menuCenterX: CGFloat = configuration.menuWidth / 2 + FT.DefaultMargin
        if senderRect.origin.y + senderRect.size.height / 2 < UIScreen.ft_height() / 2 {
            point.y = 0
        } else {
            point.y = popMenuHeight
        }
        if point.x + menuCenterX > UIScreen.ft_width() {
            point.x = min(point.x - (UIScreen.ft_width() - configuration.menuWidth - FT.DefaultMargin), configuration.menuWidth - FT.DefaultMenuArrowWidth - FT.DefaultMargin)
        } else if point.x - menuCenterX < 0 {
            point.x = max(FT.DefaultMenuCornerRadius + FT.DefaultMenuArrowWidth, point.x - FT.DefaultMargin)
        } else {
            point.x = configuration.menuWidth / 2
        }
        menuArrowPoint = point
    }

    @objc fileprivate func onBackgroudViewTapped(gesture: UIGestureRecognizer) {
        dismiss()
    }

    fileprivate func showIfNeeded() {
        if isOnScreen == false {
            isOnScreen = true
            backgroundView.alpha = 0
            popOverMenuView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: FT.DefaultAnimationDuration, animations: {
                self.popOverMenuView.alpha = 1
                self.popOverMenuView.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.backgroundView.alpha = 1
            })
        }
    }

    fileprivate func doneActionWithSelectedIndex(selectedIndex: NSInteger) {
        isOnScreen = false
        UIView.animate(withDuration: FT.DefaultAnimationDuration) {
            self.popOverMenuView.alpha = 0
            self.backgroundView.alpha = 0
            self.popOverMenuView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        } completion: { [unowned self] _ in
            self.backgroundView.removeFromSuperview()
            if selectedIndex < 0 {
                self.cancel?()
                self.cancel = nil
            } else {
                self.done?(selectedIndex)
                self.done = nil
            }
        }
    }

    // MARK: - FTPopOverMenuViewDelegate -

    func ftPopOverMenuView(didSelect index: Int) {
        doneActionWithSelectedIndex(selectedIndex: index)
    }
}

private extension FTPopOverMenu {
    func addOrientationChangeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(onChangeStatusBarOrientationNotification(notification:)),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }

    func removeOrientationChangeNotification() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func onChangeStatusBarOrientationNotification(notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.adjustPostionForPopOverMenu()
        }
    }
}

extension FTPopOverMenu: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: backgroundView)
        let touchClass: String = NSStringFromClass((touch.view?.classForCoder)!) as String
        if touchClass == "UITableViewCellContentView" {
            return false
        } else if CGRect(x: 0, y: 0, width: configuration.menuWidth, height: configuration.menuRowHeight).contains(touchPoint) {
            // when showed at the navgation-bar-button-item, there is a chance of not respond around the top arrow, so :
            doneActionWithSelectedIndex(selectedIndex: 0)
            return false
        }
        return true
    }
}

private protocol FTPopOverMenuViewDelegate: NSObjectProtocol {
    func ftPopOverMenuView(didSelect index: Int)
}

private class FTPopOverMenuView: UIControl {
    fileprivate var menuNameArray: [FTMenuObject]!
    fileprivate var menuImageArray: [Imageable]?
    fileprivate var arrowDirection: FTPopOverMenuArrowDirection = .up
    fileprivate weak var delegate: FTPopOverMenuViewDelegate?
    fileprivate var configuration = FTConfiguration()

    lazy var menuTableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: UITableView.Style.plain)
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = self.configuration.menuSeparatorColor
        tableView.layer.cornerRadius = self.configuration.cornerRadius
        tableView.clipsToBounds = true
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        return tableView
    }()

    fileprivate func showWithAnglePoint(point: CGPoint, frame: CGRect, menuNameArray: [FTMenuObject]!, menuImageArray: [Imageable]?, config: FTConfiguration? = nil, arrowDirection: FTPopOverMenuArrowDirection, delegate: FTPopOverMenuViewDelegate?) {
        self.frame = frame

        self.menuNameArray = menuNameArray
        self.menuImageArray = menuImageArray
        configuration = config ?? FTConfiguration()
        self.arrowDirection = arrowDirection
        self.delegate = delegate

        repositionMenuTableView()

        drawBackgroundLayerWithArrowPoint(arrowPoint: point)
    }

    fileprivate func repositionMenuTableView() {
        var menuRect: CGRect = CGRect(x: 0, y: FT.DefaultMenuArrowHeight, width: frame.size.width, height: frame.size.height - FT.DefaultMenuArrowHeight)
        if arrowDirection == .down {
            menuRect = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height - FT.DefaultMenuArrowHeight)
        }
        menuTableView.frame = menuRect
        menuTableView.reloadData()
        if menuTableView.frame.height < configuration.menuRowHeight * CGFloat(menuNameArray.count) {
            menuTableView.isScrollEnabled = true
        } else {
            menuTableView.isScrollEnabled = false
        }
        addSubview(menuTableView)
    }

    fileprivate lazy var backgroundLayer: CAShapeLayer = {
        let layer: CAShapeLayer = CAShapeLayer()
        return layer
    }()

    fileprivate func drawBackgroundLayerWithArrowPoint(arrowPoint: CGPoint) {
        if backgroundLayer.superlayer != nil {
            backgroundLayer.removeFromSuperlayer()
        }

        backgroundLayer.path = getBackgroundPath(arrowPoint: arrowPoint).cgPath
        backgroundLayer.fillColor = configuration.backgoundTintColor.cgColor
        backgroundLayer.strokeColor = configuration.borderColor.cgColor
        backgroundLayer.lineWidth = configuration.borderWidth

        if let adpater = configuration.localShadowAdapter {
            adpater(backgroundLayer)
        } else {
            if configuration.localShadow {
                backgroundLayer.shadowColor = UIColor.black.cgColor
                backgroundLayer.shadowOffset = CGSize(width: 0.0, height: 2.0)
                backgroundLayer.shadowRadius = 24.0
                backgroundLayer.shadowOpacity = 0.9
                backgroundLayer.masksToBounds = false
                backgroundLayer.shouldRasterize = true
                backgroundLayer.rasterizationScale = UIScreen.main.scale
            }
        }
        layer.insertSublayer(backgroundLayer, at: 0)
        //        backgroundLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: CGFloat(M_PI))) //CATransform3DMakeRotation(CGFloat(M_PI), 1, 1, 0)
    }

    func getBackgroundPath(arrowPoint: CGPoint) -> UIBezierPath {
        let viewWidth = bounds.size.width
        let viewHeight = bounds.size.height

        let radius: CGFloat = configuration.cornerRadius

        let path: UIBezierPath = UIBezierPath()
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        
        if arrowDirection == .up {
            path.move(to: CGPoint(x: arrowPoint.x - FT.DefaultMenuArrowWidth, y: FT.DefaultMenuArrowHeight))
            
            let aDealta = FT.DefaultArrowCornerRadius * FT.DefaultMenuArrowHeight / sqrt(pow(FT.DefaultMenuArrowHeight, 2) + pow(FT.DefaultMenuArrowWidth, 2))
            let ax = arrowPoint.x - aDealta
            let ay = FT.DefaultMenuArrowHeight * aDealta / FT.DefaultMenuArrowWidth
            path.addLine(to: CGPoint(x: ax, y: ay))
            
            let degree = .pi - 2 * atan(FT.DefaultMenuArrowWidth / FT.DefaultMenuArrowHeight)
            let degreeDelta = (.pi - degree) / 2
            let startAngle = -.pi + degreeDelta
            let endAngle = startAngle + degree
            path.addArc(withCenter: CGPoint(x: arrowPoint.x, y: ay + pow(aDealta, 2) / ay),
                        radius: FT.DefaultArrowCornerRadius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: true)
            
            path.addLine(to: CGPoint(x: arrowPoint.x + FT.DefaultMenuArrowWidth, y: FT.DefaultMenuArrowHeight))
            path.addLine(to: CGPoint(x: viewWidth - radius, y: FT.DefaultMenuArrowHeight))
            path.addArc(withCenter: CGPoint(x: viewWidth - radius, y: FT.DefaultMenuArrowHeight + radius),
                        radius: radius,
                        startAngle: .pi / 2 * 3,
                        endAngle: 0,
                        clockwise: true)
            path.addLine(to: CGPoint(x: viewWidth, y: viewHeight - radius))
            path.addArc(withCenter: CGPoint(x: viewWidth - radius, y: viewHeight - radius),
                        radius: radius,
                        startAngle: 0,
                        endAngle: .pi / 2,
                        clockwise: true)
            path.addLine(to: CGPoint(x: radius, y: viewHeight))
            path.addArc(withCenter: CGPoint(x: radius, y: viewHeight - radius),
                        radius: radius,
                        startAngle: .pi / 2,
                        endAngle: .pi,
                        clockwise: true)
            path.addLine(to: CGPoint(x: 0, y: FT.DefaultMenuArrowHeight + radius))
            path.addArc(withCenter: CGPoint(x: radius, y: FT.DefaultMenuArrowHeight + radius),
                        radius: radius,
                        startAngle: .pi,
                        endAngle: .pi / 2 * 3,
                        clockwise: true)
            path.close()
        } else {
            path.move(to: CGPoint(x: arrowPoint.x - FT.DefaultMenuArrowWidth, y: viewHeight - FT.DefaultMenuArrowHeight))
            
            let aDealta = FT.DefaultArrowCornerRadius * FT.DefaultMenuArrowHeight / sqrt(pow(FT.DefaultMenuArrowHeight, 2) + pow(FT.DefaultMenuArrowWidth, 2))
            let bDealta = FT.DefaultMenuArrowHeight * aDealta / FT.DefaultMenuArrowWidth
            let ax = arrowPoint.x - aDealta
            let ay = viewHeight - bDealta
            path.addLine(to: CGPoint(x: ax, y: ay))
            
            let degree = .pi - 2 * atan(FT.DefaultMenuArrowWidth / FT.DefaultMenuArrowHeight)
            let degreeDelta = (.pi - degree) / 2
            let startAngle = .pi - degreeDelta
            let endAngle = startAngle - degree
            path.addArc(withCenter: CGPoint(x: arrowPoint.x, y: ay - pow(aDealta, 2) / bDealta),
                        radius: FT.DefaultArrowCornerRadius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false)
            
            path.addLine(to: CGPoint(x: arrowPoint.x + FT.DefaultMenuArrowWidth, y: viewHeight - FT.DefaultMenuArrowHeight))
            path.addLine(to: CGPoint(x: viewWidth - radius, y: viewHeight - FT.DefaultMenuArrowHeight))
            path.addArc(withCenter: CGPoint(x: viewWidth - radius, y: viewHeight - FT.DefaultMenuArrowHeight - radius),
                        radius: radius,
                        startAngle: .pi / 2,
                        endAngle: 0,
                        clockwise: false)
            path.addLine(to: CGPoint(x: viewWidth, y: radius))
            path.addArc(withCenter: CGPoint(x: viewWidth - radius, y: radius),
                        radius: radius,
                        startAngle: 0,
                        endAngle: .pi / 2 * 3,
                        clockwise: false)
            path.addLine(to: CGPoint(x: radius, y: 0))
            path.addArc(withCenter: CGPoint(x: radius, y: radius),
                        radius: radius,
                        startAngle: .pi / 2 * 3,
                        endAngle: .pi,
                        clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: viewHeight - FT.DefaultMenuArrowHeight - radius))
            path.addArc(withCenter: CGPoint(x: radius, y: viewHeight - FT.DefaultMenuArrowHeight - radius),
                        radius: radius,
                        startAngle: .pi,
                        endAngle: .pi / 2,
                        clockwise: false)
            path.close()
        }
        return path
    }
}

extension FTPopOverMenuView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return configuration.menuRowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.ftPopOverMenuView(didSelect: indexPath.row)
    }
}

extension FTPopOverMenuView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuNameArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FTPopOverMenuCell = FTPopOverMenuCell(style: .default, reuseIdentifier: FT.PopOverMenuTableViewCellIndentifier)
        var imageObject: Imageable?

        if menuImageArray != nil {
            if (menuImageArray?.count)! >= indexPath.row + 1 {
                imageObject = menuImageArray![indexPath.row]
            }
        }

        cell.setupCellWith(menuName: menuNameArray[indexPath.row], menuImage: imageObject, configuration: configuration)
        if indexPath.row == menuNameArray.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: bounds.size.width, bottom: 0, right: 0)
        } else {
            cell.separatorInset = configuration.menuSeparatorInset
        }
        cell.selectionStyle = configuration.cellSelectionStyle
        return cell
    }
}
