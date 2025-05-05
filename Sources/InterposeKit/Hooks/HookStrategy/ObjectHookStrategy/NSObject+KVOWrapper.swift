//
//  NSObject+KVOWrapper.swift
//
//
//  Created by Wang Ya on 12/27/20.
//  Copyright © 2020 Yanni. All rights reserved.
//

import Foundation
import _ExceptionCatcher
import AppKit

extension NSObject {
    func wrapKVOIfNeeded() throws {
        guard kvoObserver == nil else { return }
        guard isSupportedKVO() else {
            throw InterposeError.unsupportedKVO(object: self)
        }
        kvoObserver = KVOObserver(for: self)
    }
    
    func unwrapKVO() {
        kvoObserver = nil
    }
    
    fileprivate func isSupportedKVO() -> Bool {
        if let isSupportedKVO = objc_getAssociatedObject(self, &isSupportedKVOAssociatedKey) as? Bool {
            return isSupportedKVO
        }
        
        let result: Bool
        let actualClass: AnyClass = object_getClass(self)
        if actualClass != type(of: self), NSStringFromClass(actualClass).hasPrefix("NSKVO") {
            result = true
        } else {
            do {
                try NSObject.catchException {
                    addObserver(RealObserver.shared, forKeyPath: RealObserver.keyPath, options: .new, context: &RealObserver.context)
                }
                defer {
                    removeObserver(RealObserver.shared, forKeyPath: RealObserver.keyPath, context: &RealObserver.context)
                }
                result = actualClass != object_getClass(self)
            } catch {
                result = false
            }
        }
        objc_setAssociatedObject(self, &isSupportedKVOAssociatedKey, result, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        return result
    }
    
    fileprivate var kvoObserver: KVOObserver? {
        get { objc_getAssociatedObject(self, &swiftHookObserverAssociatedKey) as? KVOObserver }
        set { objc_setAssociatedObject(self, &swiftHookObserverAssociatedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

fileprivate class KVOObserver: NSObject {
    unowned(unsafe) let target: NSObject
    
    init(for target: NSObject) {
        self.target = target
        super.init()
        target.addObserver(RealObserver.shared, forKeyPath: RealObserver.keyPath, options: .new, context: &RealObserver.context)
    }
    
    deinit {
        target.removeObserver(RealObserver.shared, forKeyPath: RealObserver.keyPath, context: &RealObserver.context)
    }
}

fileprivate class RealObserver: NSObject {
    #if compiler(>=5.10)
    nonisolated(unsafe) static let shared = RealObserver()
    nonisolated(unsafe) static var context = 0
    #else
    static let shared = RealObserver()
    static var context = 0
    #endif
    static let keyPath = "kvoPrivateProperty"
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath != Self.keyPath else { return }
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
}

#if compiler(>=5.10)
fileprivate nonisolated(unsafe) var swiftHookObserverAssociatedKey = 0
fileprivate nonisolated(unsafe) var isSupportedKVOAssociatedKey = 0
#else
fileprivate var swiftHookObserverAssociatedKey = 0
fileprivate var isSupportedKVOAssociatedKey = 0
#endif
