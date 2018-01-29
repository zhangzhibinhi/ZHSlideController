//
//  ZHSlideViewController.swift
//
//  Created by 张志彬 on 2018/1/15.
//  Copyright © 2018年 MTD. All rights reserved.
//

import UIKit

extension UIView {
    var top: CGFloat {
        get {
            return self.frame.origin.y
        }
        
        set {
            self.frame.origin.y = newValue
        }
    }
    
    var left: CGFloat {
        get {
            return self.frame.origin.x
        }
        
        set {
            self.frame.origin.x = newValue
        }
    }
    
    var right: CGFloat {
        get {
            return self.frame.origin.x + self.frame.size.width
        }
        
        set {
            self.frame.origin.x = newValue - self.frame.size.width
        }
    }
    
    var bottom: CGFloat {
        get {
            return self.frame.origin.y + self.frame.size.height
        }
        
        set {
            self.frame.origin.y = newValue - self.frame.size.height
        }
    }
    
    var width: CGFloat {
        get {
            return self.frame.size.width
        }
        
        set {
            self.frame.size.width = newValue
        }
    }
    
    var height: CGFloat {
        get {
            return self.frame.size.height
        }
        
        set {
            self.frame.size.height = newValue
        }
    }
}

typealias ActionBlock = (_ sender: AnyObject)-> Void

class UIGestureRecognizerBlockTarget: NSObject {
    private var block: ActionBlock?
    
    init(block: @escaping ActionBlock) {
        super.init()
        self.block = block
    }
    
    @objc public func invoke(_ sender: AnyObject) {
        self.block?(sender)
    }
}

var block_key = "block_key"

extension UIGestureRecognizer {
//    var allUIGestureRecognizerBlockTargets: [UIGestureRecognizerBlockTarget] {
//        get {
//            var targets = objc_getAssociatedObject(self, &block_key)
//            if targets == nil {
//                targets = [UIGestureRecognizerBlockTarget]()
//                objc_setAssociatedObject(self, &block_key, targets, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//            }
//
//            return targets as! [UIGestureRecognizerBlockTarget]
//        }
//    }
    
    convenience init(actionBlock: ActionBlock?) {
        self.init()
        self.add(actionBlock: actionBlock!)
    }
    
    func add(actionBlock: @escaping ActionBlock) {
        let target = UIGestureRecognizerBlockTarget(block: actionBlock)
        self.addTarget(target, action: #selector(UIGestureRecognizerBlockTarget.invoke(_:)))  //#selector(target.invoke(_:))
//        var targets = self.allUIGestureRecognizerBlockTargets
//        targets.append(target)
    }
    
//    func removeAllActionBlocks() {
//        var targets = self.allUIGestureRecognizerBlockTargets
//
//        for target in targets {
//            self.re
//            self.removeTarget(target, action: #selector(UIGestureRecognizerBlockTarget.invoke(_:)))
//        }
//        targets.removeAll()
//    }
}

let panGesResponeMinWidth: CGFloat = 80
let animationDuration: CGFloat = 0.3

class ZHSlideViewController: UIViewController {
    static let sharedSlideViewController = sharedSlideController()
    public var canShowLeft: Bool
    
    private var mainContentController: UIViewController?
    private var sideContentController: UIViewController?
    private var mainContentContainer: UIView?
    private var sideContentContainer: UIView?
    private var sideBackgroundView: UIView?
    
    static private func sharedSlideController() -> ZHSlideViewController {
        return ZHSlideViewController()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.canShowLeft = true
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.canShowLeft = true
        super.init(coder: aDecoder)
    }
    
    public func setup(MainViewController mainController: UIViewController, sideViewController sideController: UIViewController) {
        mainContentController = mainController
        sideContentController = sideController
        
        // remove childControllers and reset containerView
        for childController in self.childViewControllers {
            childController.removeFromParentViewController()
        }
        
        for subview in self.view.subviews {
            subview.removeFromSuperview()
        }
        
        self.initSubviews()
        self.initGestures()
    }
    
    private func initSubviews() {
        // setup mainContent
        mainContentContainer = UIView(frame: mainContentController!.view.frame)
        self.view.addSubview(mainContentContainer!)
        mainContentContainer?.addSubview(mainContentController!.view)
        self.addChildViewController(mainContentController!)
        
        // setup sideContent
        sideContentContainer = UIView(frame: sideContentController!.view.frame)
        self.view.addSubview(sideContentContainer!)
        sideContentContainer?.addSubview(sideContentController!.view)
        self.addChildViewController(sideContentController!)
        
        sideBackgroundView = UIView(frame: (mainContentController?.view.bounds)!)
        sideBackgroundView?.isUserInteractionEnabled = true
        sideBackgroundView?.backgroundColor = UIColor.white
//        let imageView = UIImageView(image: UIImage(named: "fh_"))
//        imageView.top = 29
//        imageView.left = (sideBackgroundView?.width)!-60
//        sideBackgroundView?.addSubview(imageView)
        
        sideContentContainer?.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.new, context: nil)
        
        // setup container frame
        mainContentContainer?.left = 0
        mainContentContainer?.top = 0
        sideContentContainer?.right = 0
        sideContentContainer?.top = 0
    }
    
    private var gesStartX: CGFloat?
    private var sideStartX: CGFloat?
    
    private func initGestures() {
        // config main container gesture
        let mainPanGes = UIPanGestureRecognizer(target: self, action: #selector(mainGesAction(_:)))
        mainContentContainer?.addGestureRecognizer(mainPanGes)
        
        // config side container gesture
        let sidePanGes = UIPanGestureRecognizer(target: self, action: #selector(sideGesAction(_:)))
        sideContentContainer?.addGestureRecognizer(sidePanGes)
        sideBackgroundView?.addGestureRecognizer(sidePanGes)
        
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(hideAction(_:)))
        tapGes.require(toFail: sidePanGes)
        sideBackgroundView?.addGestureRecognizer(tapGes)
    }
    @objc func mainGesAction(_ gesture: UIGestureRecognizer) {
        if !self.canShowLeft {
            return
        }
        
        let panGes = gesture as! UIPanGestureRecognizer
        
        switch panGes.state {
        case .began:
            self.gesStartX = panGes.location(in: self.view).x
            self.sideStartX = self.sideContentContainer?.left
        case .changed:
            let currentX = panGes.location(in: self.view).x
            var durationX = currentX - self.gesStartX!
            // 防止划过了，左边出现空白
            if durationX > (self.sideContentContainer?.width)! {
                durationX = (self.sideContentContainer?.width)!
            }
            self.sideContentContainer?.right = durationX > 0 ? durationX : 0
        case .ended:
            let currentX = panGes.location(in: self.view).x
            let durationX = currentX - self.gesStartX!
            if durationX > panGesResponeMinWidth {
                self.showSideViewControllerAnimated(true, completionBlock: {
                    
                })
            } else {
                self.hideSideViewControllerAnimated(true, completionBlock: {
                    
                })
            }
        default:
            break
        }
    }
    
    @objc func sideGesAction(_ gesture: UIGestureRecognizer) {
        let panGes = gesture as! UIPanGestureRecognizer
        
        switch panGes.state {
        case .began:
            self.gesStartX = panGes.location(in: self.view).x
            self.sideStartX = self.sideContentContainer?.left
        case .changed:
            let currentX = panGes.location(in: self.view).x
            let durationX = currentX - self.gesStartX!
            self.sideContentContainer?.left = durationX < 0 ? durationX : 0
        case .ended:
            let currentX = panGes.location(in: self.view).x
            let durationX = currentX - self.gesStartX!
            if durationX < -panGesResponeMinWidth {
                self.hideSideViewControllerAnimated(true, completionBlock: {
                    
                })
            } else {
                self.showSideViewControllerAnimated(true, completionBlock: {
                    
                })
            }
        default:
            break
        }
    }
    
    @objc func hideAction(_ gesture: UIGestureRecognizer) {
        self.hideSideViewControllerAnimated(true, completionBlock: {
            
        });
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frame" {
            sideBackgroundView?.alpha = (sideContentContainer?.right)!/(mainContentContainer?.width)!
            
            if (sideContentContainer?.right)! > 0 && sideBackgroundView?.superview == nil {
                mainContentContainer?.addSubview(sideBackgroundView!)
            }
        }
    }
    
    public func showSideViewControllerAnimated(_ animated: Bool, completionBlock: @escaping ()->Void) {
        if !self.canShowLeft {
            return
        }
        
        let duration = animationDuration * (-(sideContentContainer?.left)!/(sideContentContainer?.width)!)
        
        weak var weakSelf = self
        
        UIView.animate(withDuration: TimeInterval(duration), animations: {
            weakSelf?.sideContentContainer?.left = 0
        }) { (finished) in
            if finished {
                completionBlock()
            }
        }
    }
    
    public func hideSideViewControllerAnimated(_ animated: Bool, completionBlock: @escaping ()->Void) {
        let duration = animationDuration * ((sideContentContainer?.right)!/(sideContentContainer?.width)!)
        
        weak var weakSelf = self
        
        UIView.animate(withDuration: TimeInterval(duration), animations: {
            weakSelf?.sideContentContainer?.right = 0
        }) { (finished) in
            if finished {
                weakSelf?.sideBackgroundView?.removeFromSuperview()
                completionBlock()
            }
        }
    }
}
