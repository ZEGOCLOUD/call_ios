//
//  HomeVC.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/11.
//

import UIKit

class HomeVC: UIViewController {

    @IBOutlet weak var headImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userIDLabel: UILabel!
    
    @IBOutlet weak var backView: UIView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    
    @IBAction func signUpClick(_ sender: UIButton) {
    }
    
    
    @IBAction func getMoreClick(_ sender: UIButton) {
    }
    
}
