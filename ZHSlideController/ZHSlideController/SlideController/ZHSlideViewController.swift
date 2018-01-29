//
//  ZHSlideViewController.swift
//
//  Created by 张志彬 on 2018/1/15.
//  Copyright © 2018年 MTD. All rights reserved.
//

import UIKit

let panGesResponeMinWidth: CGFloat = 80
let animationDuration: CGFloat = 0.3

class ZHSlideViewController: UIViewController {
    // public static controller
    static let sharedSlideViewController = sharedSlideController()
    // default is true
    public var canShowLeft: Bool
    
    // private params
    private var mainContentController: UIViewController?
    private var sideContentController: UIViewController?
    private var mainContentContainer: UIView?
    private var sideContentContainer: UIView?
    private var sideBackgroundView: UIView?
    
    static private func sharedSlideController() -> ZHSlideViewController {
        return ZHSlideViewController()
    }
    
    // public setup action
    public func setup(MainViewController mainController: UIViewController, sideViewController sideController: UIViewController) {
        self.mainContentController = mainController
        self.sideContentController = sideController
        
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
    
    /// private action
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.canShowLeft = true
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.canShowLeft = true
        super.init(coder: aDecoder)
    }
    
    private func initSubviews() {
        // setup mainContent
        self.mainContentContainer = UIView(frame: self.mainContentController!.view.frame)
        self.view.addSubview(self.mainContentContainer!)
        self.mainContentContainer?.addSubview(self.mainContentController!.view)
        self.addChildViewController(self.mainContentController!)
        
        // setup sideContent
        self.sideContentContainer = UIView(frame: self.sideContentController!.view.frame)
        self.view.addSubview(self.sideContentContainer!)
        self.sideContentContainer?.addSubview(self.sideContentController!.view)
        self.addChildViewController(self.sideContentController!)
        
        // setup background view
        self.sideBackgroundView = UIView(frame: (self.mainContentController?.view.bounds)!)
        self.sideBackgroundView?.backgroundColor = UIColor.white
        
        // add observer for sideContentContainer.frame to change the alpha value of the background view
        self.sideContentContainer?.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.new, context: nil)
        
        // setup container frame
        self.mainContentContainer?.frame.origin.x = 0
        self.mainContentContainer?.frame.origin.y = 0
        self.sideContentContainer?.frame.origin.x = -(self.sideContentContainer?.frame.size.width)!
        self.sideContentContainer?.frame.origin.y = 0
    }
    
    private var gesStartX: CGFloat?
    private var sideStartX: CGFloat?
    
    private func initGestures() {
        // config main container gesture
        let mainPanGes = UIPanGestureRecognizer(target: self, action: #selector(mainGesAction(_:)))
        self.mainContentContainer?.addGestureRecognizer(mainPanGes)
        
        // config side container gesture
        let sidePanGes = UIPanGestureRecognizer(target: self, action: #selector(sideGesAction(_:)))
        self.sideContentContainer?.addGestureRecognizer(sidePanGes)
        self.sideBackgroundView?.addGestureRecognizer(sidePanGes)
        
        // tap to hide
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(hideAction(_:)))
        tapGes.require(toFail: sidePanGes)
        self.sideBackgroundView?.addGestureRecognizer(tapGes)
    }
    
    @objc func mainGesAction(_ gesture: UIGestureRecognizer) {
        if !self.canShowLeft {
            return
        }
        
        let panGes = gesture as! UIPanGestureRecognizer
        
        switch panGes.state {
        case .began:
            self.gesStartX = panGes.location(in: self.view).x
            self.sideStartX = self.sideContentContainer?.frame.origin.x
        case .changed:
            let currentX = panGes.location(in: self.view).x
            var durationX = currentX - self.gesStartX!
            // 防止划过了，左边出现空白
            if durationX > (self.sideContentContainer?.frame.size.width)! {
                durationX = (self.sideContentContainer?.frame.size.width)!
            }
            self.sideContentContainer?.frame.origin.x = -(self.sideContentContainer?.frame.size.width)! + (durationX > 0 ? durationX  : 0)
        case .ended:
            let currentX = panGes.location(in: self.view).x
            let durationX = currentX - self.gesStartX!
            //
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
            self.sideStartX = self.sideContentContainer?.frame.origin.x
        case .changed:
            let currentX = panGes.location(in: self.view).x
            let durationX = currentX - self.gesStartX!
            self.sideContentContainer?.frame.origin.x = durationX < 0 ? durationX : 0
        case .ended:
            let currentX = panGes.location(in: self.view).x
            let durationX = currentX - self.gesStartX!
            //
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
            // change the alpha value of the background view by the sideContentContainer's frame
            self.sideBackgroundView?.alpha = ((self.sideContentContainer?.frame.origin.x)! + (self.sideContentContainer?.frame.size.width)!)/(self.mainContentContainer?.frame.size.width)!
            
            // add the backgroundView to the background if sideContainContainer is visible
            if ((self.sideContentContainer?.frame.origin.x)! + (self.sideContentContainer?.frame.size.width)!) > 0 && self.sideBackgroundView?.superview == nil {
                self.mainContentContainer?.addSubview(self.sideBackgroundView!)
            }
        }
    }
    
    public func showSideViewControllerAnimated(_ animated: Bool, completionBlock: @escaping ()->Void) {
        if !self.canShowLeft {
            return
        }
        
        let duration = animationDuration * (-(self.sideContentContainer?.frame.origin.x)!/(self.sideContentContainer?.frame.size.width)!)
        
        weak var weakSelf = self
        
        UIView.animate(withDuration: TimeInterval(duration), animations: {
            weakSelf?.sideContentContainer?.frame.origin.x = 0
        }) { (finished) in
            if finished {
                completionBlock()
            }
        }
    }
    
    public func hideSideViewControllerAnimated(_ animated: Bool, completionBlock: @escaping ()->Void) {
        let duration = animationDuration * (((self.sideContentContainer?.frame.origin.x)! + (self.sideContentContainer?.frame.size.width)!)/(self.sideContentContainer?.frame.size.width)!)
        
        weak var weakSelf = self
        
        UIView.animate(withDuration: TimeInterval(duration), animations: {
            weakSelf?.sideContentContainer?.frame.origin.x = -(weakSelf?.sideContentContainer?.frame.size.width)!
        }) { (finished) in
            if finished {
                // remove the backgroundView if sideContainContainer is invisible
                weakSelf?.sideBackgroundView?.removeFromSuperview()
                completionBlock()
            }
        }
    }
}
