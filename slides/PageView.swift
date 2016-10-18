//
//  PageView.swift
//  slides
//
//  Created by softphone on 26/09/2016.
//  Copyright © 2016 soulsoftware. All rights reserved.
//

import UIKit

class PageView: UIView {

    // MARK: standard lifecycle
    
    override func didMoveToSuperview() {
    }
    
    override func updateConstraints() {
        super.updateConstraints()
    }
    
    typealias BecomeFocusPredicate = () -> Bool
    
    var becomeFocusedPredicate:BecomeFocusPredicate?
    
    // MARK: Focus Management
    override func canBecomeFocused() -> Bool {
        guard let predicate = self.becomeFocusedPredicate else {
            print( "PageView.canBecomeFocused: true" )
            return true
        }
        let result = predicate()
        print( "PageView.canBecomeFocused: \(result)" )

        return result
    }
    
    /// Asks whether the system should allow a focus update to occur.
    override func shouldUpdateFocusInContext(context: UIFocusUpdateContext) -> Bool {
        print( "PageView.shouldUpdateFocusInContext:" )
        return true
        
    }
    
    /// Called when the screen’s focusedView has been updated to a new view. Use the animation coordinator to schedule focus-related animations in response to the update.
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator)
    {
        print( "PageView.didUpdateFocusInContext: focused: \(self.focused)" );
    }
    
    // MARK: Pointer Management
    
    private lazy var pointer:UIView = {
        
        let pointer:UIView = UIView( frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        
        pointer.backgroundColor = UIColor.magentaColor()
        pointer.userInteractionEnabled = false
        
        pointer.layer.cornerRadius = 10.0
        
        // border
        pointer.layer.borderColor = UIColor.lightGrayColor().CGColor
        pointer.layer.borderWidth = 1.5
        
        // drop shadow
        pointer.layer.shadowColor = UIColor.blackColor().CGColor
        pointer.layer.shadowOpacity = 0.8
        pointer.layer.shadowRadius = 3.0
        pointer.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        
        return pointer
        
    }()
    
    var showPointer:Bool = false {
        
        didSet {
            
            if !showPointer {
                pointer.removeFromSuperview()
                return;
            }
            
            if !oldValue {
                pointer.frame.origin = self.center
                
                addSubview(pointer)
            }
        }
    }
    
    // MARK: Touch Handling
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let firstTouch = touches.first else { return }
        guard showPointer else {return}
        
        let locationInView = firstTouch.locationInView(firstTouch.view)
        
        var f = pointer.frame
        f.origin = locationInView
        
        pointer.frame = f
    }
    
    override func  touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        //print("touchesMoved ")
        
        guard let firstTouch = touches.first else { return }
        guard showPointer else {return}
        
        
        let locationInView = firstTouch.locationInView(firstTouch.view)
        
        var f = pointer.frame
        f.origin = locationInView
        
        pointer.frame = f
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("touchesEnded ")
        showPointer = false
        
    }
    
    override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("touchesCancelled ")
        showPointer = false
        
    }
    
    

}