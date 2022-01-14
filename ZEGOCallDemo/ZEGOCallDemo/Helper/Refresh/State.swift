//
//  State.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/14.
//

import Foundation

public enum State: Equatable, CustomStringConvertible {
    
    case initial
    case releasing(progress: CGFloat)
    case loading
    case finished
    
    public var description: String {
        switch self {
        case .initial: return "Inital"
        case .releasing(let progress): return "Releasing:\(progress)"
        case .loading: return "Loading"
        case .finished: return "Finished"
        }
    }
}

public func ==(a: State, b: State) -> Bool {
    switch (a, b) {
    case (.initial, .initial): return true
    case (.loading, .loading): return true
    case (.finished, .finished): return true
    case (.releasing, .releasing): return true
    default: return false
    }
}
