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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
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
        myUserName = subStringOfBytes(userName: userName)
        if userName.count > 0 {
            loginButton.isUserInteractionEnabled = true
            loginButton.backgroundColor = ZegoColor("0055FF")
        } else {
            loginButton.isUserInteractionEnabled = false
            loginButton.backgroundColor = ZegoColor("0055FF").withAlphaComponent(0.4)
        }
    }
    
    func subStringOfBytes(userName: String) -> String {
        var count:Int = 0
        var newStr:String = ""
        for i in 0..<userName.count {
            let startIndex = userName.index(userName.startIndex, offsetBy: i)
            let index = userName.index(userName.startIndex, offsetBy: i)
            let aStr:String = String(userName[startIndex...index])
            count += aStr.lengthOfBytes(using: .utf8)
            if count <= 32 {
                newStr.append(aStr)
            } else {
                break
            }
        }
        return newStr
    }
    
    //MARK: -Action
    
    @IBAction func loginClick(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension LoginVC : UITextFieldDelegate {
    //MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let proposeLength = (textField.text?.lengthOfBytes(using: .utf8))! - range.length + string.lengthOfBytes(using: .utf8)
        if proposeLength > 32 {
            return false
        }
        return true
    }

}

