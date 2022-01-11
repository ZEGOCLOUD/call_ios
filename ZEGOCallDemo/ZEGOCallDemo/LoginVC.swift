//
//  ViewController.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/10.
//

import UIKit

class LoginVC: UIViewController {
    
    
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var whiteBackGroundView: UIView!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var inputNameTipLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    var myUserName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        clipRoundCorners()
    }
    
    func clipRoundCorners() -> Void {
        let maskPath: UIBezierPath = UIBezierPath.init(roundedRect: CGRect.init(x: 0, y: 0, width: whiteBackGroundView.bounds.size.width, height: whiteBackGroundView.bounds.size.height), byRoundingCorners: [.topLeft,.topRight], cornerRadii: CGSize.init(width: 24, height: 24))
        let maskLayer: CAShapeLayer = CAShapeLayer()
        maskLayer.frame = whiteBackGroundView.bounds
        maskLayer.path = maskPath.cgPath
        whiteBackGroundView.layer.mask = maskLayer
    }

    @IBAction func userNameTextFieldDidChanged(_ sender: UITextField) {
        var userName = sender.text! as String
        if userName.count > 32 {
            let startIndex = userName.index(userName.startIndex, offsetBy: 0)
            let index = userName.index(userName.startIndex, offsetBy: 32)
            userName = String(userName[startIndex...index])
            sender.text = userName
        }
        myUserName = userName
    }
    
    @IBAction func loginClick(_ sender: Any) {
        
    }
    
}

