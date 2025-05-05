//
//  ViewController.swift
//  KVO_Test
//
//  Created by Florian Zand on 05.05.25.
//

import Cocoa
import InterposeKit

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textField = NSTextField(frame: CGRect(x: 30, y: 30, width: 200, height: 40))
        view.addSubview(textField)
        
        // Crash
        do {
            try textField.applyHook(for: #selector(NSTextField.textDidChange(_:)),
           methodSignature: (@convention(c)  (AnyObject, Selector, Notification) -> ()).self,
           hookSignature: (@convention(block)  (AnyObject, Notification) -> ()).self) { store in {
               object, notification in
                Swift.print("textDidChange", notification)
               }
           }
        } catch {
           debugPrint(error)
        }
    }

}

