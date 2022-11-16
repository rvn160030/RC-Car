//
//  Controls.swift
//  RC Car
//
// From Mohammad Azam (C) 2017
//

import Foundation
import UIKit


class DPadButton: UIButton{
    var callbackFunc: () -> ()
    private var timer: Timer!
    
    init(frame: CGRect, callback: @escaping () -> ()) {
        self.callbackFunc = callback
        super.init(frame: frame)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { [weak self] (timer :Timer) in
            self?.callbackFunc()
        })
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.timer.invalidate()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
