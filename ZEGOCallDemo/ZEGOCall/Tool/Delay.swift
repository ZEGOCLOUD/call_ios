//
//  Delay.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/28.
//

import Foundation

typealias Task = (_ cancel: Bool) -> Void

@discardableResult
func delay(by delayTime: TimeInterval, qosClass: DispatchQoS.QoSClass? = nil, _ task: @escaping () -> Void) -> Task? {
    
    func dispatch_later(block: @escaping () -> Void) {
        let dispatchQueue = qosClass != nil ? DispatchQueue.global(qos: qosClass!) : .main
        dispatchQueue.asyncAfter(deadline: .now() + delayTime, execute: block)
    }
    
    var closure: (() -> Void)? = task
    var result: Task?
    
    let delayedClosure: Task = { cancel in
        if let internalClosure = closure {
            if !cancel {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }
    
    result = delayedClosure
    
    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
    return result
}

func delayCancel(_ task: Task?) {
    task?(true)
}
