//
//  GeneralWebVC.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/11.
//

import UIKit
import WebKit

class GeneralWebVC: UIViewController {
    
    
    @IBOutlet weak var webview: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func loadUrl(_ url: String) {
        let webUrl: URL? = URL(string: url)
        if let webUrl = webUrl {
            webview.load(NSURLRequest(url: webUrl) as URLRequest)
        }
    }

}
