//
//  SlideViewer+Fullpage.swift
//  slides
//
//  Created by softphone on 01/10/2016.
//  Copyright © 2016 soulsoftware. All rights reserved.
//

import Foundation

extension UIPDFCollectionViewController {
    
    fileprivate struct AssociatedKeys {
        static var fullpage = "_fullpage"
    }
    
    //this lets us check to see if the item is supposed to be displayed or not
    @objc var fullpage : Bool {
        get {
            guard let number = objc_getAssociatedObject(self, &AssociatedKeys.fullpage) as? NSNumber else {
                return false
            }
            return number.boolValue
        }
        
        set {
            self.willChangeValue(forKey: "fullpage")
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.fullpage,
                                     NSNumber(value: newValue as Bool),
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.didChangeValue(forKey: "fullpage")

            self.settingsBar.hide(animated: true, preferredFocusedView: pageView)
            

            if newValue {
                hideThumbnails()
            }
            else {
                showThumbnails()
            }
            self.view.setNeedsUpdateConstraints()
            
        }
    }
    
    fileprivate func showThumbnails() {
        print( "showThumbnails")
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            
            let w = self.thumbnailsWidth
            
            var page_frame = self.pageView.frame
            page_frame.origin.x += w
            self.pageView.frame = page_frame
            
            
            var pages_frame = self.pagesView.frame
            pages_frame.size.width = w
            self.pagesView.frame = pages_frame
            
            
        } ) { (completion:Bool) in
            
        }
        
        
    }
    
    fileprivate func hideThumbnails()  {
        print( "hideThumbnails")
        
        let width = self.pagesView.frame.size.width
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions() , animations: {
            
            var pages_frame = self.pagesView.frame
            pages_frame.size.width = 0
            self.pagesView.frame = pages_frame
            
            var page_frame = self.pageView.frame
            page_frame.origin.x -= width
            self.pageView.frame = page_frame
            
            
        }) { (completion:Bool) in
            
        }
    }
    
}
