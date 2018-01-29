//
//  ZHMainViewController.swift
//  ZHSlideController
//
//  Created by 张志彬 on 2018/1/26.
//  Copyright © 2018年 张志彬. All rights reserved.
//

import UIKit

class ZHMainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func show() {
        ZHSlideViewController.sharedSlideViewController.showSideViewControllerAnimated(true) {
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
