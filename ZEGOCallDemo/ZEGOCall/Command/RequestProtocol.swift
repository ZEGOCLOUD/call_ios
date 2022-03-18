//
//  RequestProtocol.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/16.
//

import Foundation

protocol RequestProtocol : AnyObject {
    func request(_ path: String, parameter: [String : AnyObject], callback: RequestCallback?)
}
