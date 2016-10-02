//
//  UIPDFCollectionViewController.swift
//  slides
//
//  Created by softphone on 01/04/16.
//  Copyright © 2016 soulsoftware. All rights reserved.
//

import Foundation
import SnapKit
import RxSwift
import RxCocoa

//
//  UIPDFPageCell
//
class UIPDFPageCell : UICollectionViewCell {
    
    lazy var box:UIImageView = UIImageView()
    
    private func initialize() {
    
        self.addSubview(box)
        
         box.snp_makeConstraints { (make) -> Void in
            make.width.height.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
         }
        
        self.layoutIfNeeded()
        self.layoutSubviews()
        self.setNeedsDisplay()
        
        
        //self.box.adjustsImageWhenAncestorFocused = true

    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        initialize()
        
    }
 
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        if (self.focused)
        {
            self.box.adjustsImageWhenAncestorFocused = true
        }
        else
        {
            self.box.adjustsImageWhenAncestorFocused = false
        }
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
}


//
//  MARK: UIPDFCollectionViewController
//
class UIPDFCollectionViewController :  UIViewController, UICollectionViewDataSource , UICollectionViewDelegateFlowLayout {
 
    static let storyboardIdentifier = "UIPDFCollectionViewController"
    
    @IBOutlet weak var pagesView: ThumbnailsView!
    
    @IBOutlet weak var settingsBar: SettingsBarView!
    @IBOutlet weak var pageView: PageView!
    @IBOutlet weak var pageImageView: UIImageView!
    
    private var doc:OHPDFDocument?

    private var pressesSubject = PublishSubject<UIPress>()
    private let disposeBag = DisposeBag()

    var documentLocation:NSURL? {
        didSet {
            doc = OHPDFDocument(URL: documentLocation)
            if( pagesView != nil ) {
                pagesView.reloadData()    
            }
        }
    }
    
    func showSlide(at index:UInt) {
        if let doc = self.doc {
            
            let page = doc.pageAtIndex(Int(index+1))
            
            let vectorImage = OHVectorImage(PDFPage: page)
            
            let fitSize = vectorImage.sizeThatFits(pageImageView.frame.size)
            self.pageImageView.image = vectorImage.renderAtSize(fitSize)
            
        }

    }
    
    // MARK: PLAY/PAUSE SLIDES
    
    private var _playPauseSlideShow:Disposable?
    private var _indexPathForPreferredFocusedView:NSIndexPath?
    
    
    
    private func playPauseSlideShow() {

        guard _playPauseSlideShow == nil else {
            // ALREADY IN PLAY
            return
        }
        
        let playSlides = Observable<Int>.interval(3, scheduler: MainScheduler.instance)
            .map({ (index:Int) -> Int in

                guard let prevIndex = self._indexPathForPreferredFocusedView else {
                    return index + 1
                }
                return prevIndex.row + 1
                
            })
            .takeWhile({ (slide:Int) -> Bool in
                return slide < self.doc?.pagesCount
            })
            .takeUntil( pressesSubject )
    
        
        self.fullpage = true
        
        _playPauseSlideShow = pressesSubject
            .filter{ (press:UIPress) -> Bool in
                return press.type == .PlayPause
            }
            .flatMap{ (_:UIPress) -> Observable<Int> in
                
                return playSlides.doOnCompleted{

                    self._playPauseSlideShow?.dispose()
                    self._playPauseSlideShow = nil
                    
                }

            }
            .subscribeNext { (slide:Int) in
                
                let i = NSIndexPath(forRow: slide, inSection: 0)
                self._indexPathForPreferredFocusedView = i
                self.pagesView.selectItemAtIndexPath(i, animated: false, scrollPosition: .None)
                self.pagesView.setNeedsFocusUpdate()
                self.pagesView.updateFocusIfNeeded()
            }
        
    }
    
    // MARK: Pointer Management
    
    private func setupPointer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(togglePointerOnTap) )
        tap.numberOfTapsRequired = 1
        pageView.addGestureRecognizer(tap)
        
        NSNotificationCenter.defaultCenter().rx_notification(SettingsBarView.Notifications.HIDDEN).bindNext { (n:NSNotification) in
            tap.enabled = n.object as! Bool
        }.addDisposableTo(disposeBag)
        
    }
    
    @IBAction func togglePointerOnTap(sender: UITapGestureRecognizer) {
        pageView.showPointer = !pageView.showPointer

    }

    // MARK: SettingsBar Management

    private func setupSettingsBar() {
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleSettingsBarOnTap) )
        tap.numberOfTapsRequired = 2
        tap.enabled = false
        //pageView.addGestureRecognizer(tap)

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(showSettingsBarOnSwipeDown) )
        swipe.direction = .Down
        tap.enabled = true
        pageView.addGestureRecognizer(swipe)

        settingsBar.hide(animated:false)
        
        self.settingsBar.rx_didPressItem
            .asDriver()
            .driveNext { (item:Int ) in
                print( "select \(item)")
                
                switch item {
                case 1: // toggle fullscreen
                    self.fullpage = !self.fullpage
                    break;
                default:
                    break
                }
        }.addDisposableTo(disposeBag)
        
    }
    
    @IBAction func toggleSettingsBarOnTap(sender: UITapGestureRecognizer) {
        print("=> ON SINGLE TAP")
        
        let isVisible = self.settingsBar.showConstraints.active
        
        if isVisible {
            settingsBar.hide(animated: true)
        }
        else {
            settingsBar.show(animated: true)
            _preferredFocusedView = settingsBar
        }
    }
    
    
    @IBAction func showSettingsBarOnSwipeDown( sender: UISwipeGestureRecognizer) {
        print("=> ON SWIPE DOWN")
        
        guard self.settingsBar.hideConstraints.active else {
            return
        }

        settingsBar.show(animated: true)
        _preferredFocusedView = settingsBar
    
    }
    
    
    // MARK: view lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupSettingsBar()
        self.setupPointer()
        
        pageImageView.translatesAutoresizingMaskIntoConstraints = false
 
        self._preferredFocusedView = pageView
        
        pageView.becomeFocusedPredicate = {
            
            return !self.settingsBar.active

        }
        
        self.setNeedsFocusUpdate()
        self.updateFocusIfNeeded()
 
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.showSlide(at: 0)
    }
    

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return layoutAttrs.cellSize //use height whatever you wants.
    }

    // Space between item on different row
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
            return layoutAttrs.minSpacingForLine
    }
    
    // Space between item on the same row
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
            return layoutAttrs.minSpacingForCell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    
    //func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize
    //func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize
    
    
// MARK: UICollectionViewDelegate
    
    //func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    //    print( "didSelectItemAtIndexPath: \(indexPath)" )
    //}
    
// MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        guard let doc = self.doc else {
            return 0
        }
        return doc.pagesCount
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("slide", forIndexPath:indexPath) as! UIPDFPageCell
        
        if let doc = self.doc {
            
            let page = doc.pageAtIndex(indexPath.row+1)
        
            let vectorImage = OHVectorImage(PDFPage: page)
            
            let fitSize = vectorImage.sizeThatFits(cell.frame.size)
            
            cell.box.image = vectorImage.renderAtSize(fitSize)
        }
        return cell;

    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
    //override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
    
    //override func collectionView(collectionView: UICollectionView, canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool
    //override func collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)
 
// MARK: Focus Engine
    
    private var _preferredFocusedView:UIView? {
        didSet {
            if _preferredFocusedView != nil {
                self.setNeedsFocusUpdate()
            }
        }
    }
    
    override var preferredFocusedView: UIView? {
        
        if let focusedView = self._preferredFocusedView {
            return focusedView
        }
        
        return super.preferredFocusedView
    }
    
    
    override func shouldUpdateFocusInContext(context: UIFocusUpdateContext) -> Bool {
        
        if context.nextFocusedView is UIPDFPageCell {
            settingsBar.hide(animated: true)
        }
        
        return true
    }
    
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator)
    {
        print( "view.didUpdateFocusInContext: focused: \(context.nextFocusedView.dynamicType)" );
    }
    
    
    func collectionView(collectionView: UICollectionView, didUpdateFocusInContext context: UICollectionViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        print("collectionView.didUpdateFocusInContext")
       
        if let i = context.nextFocusedIndexPath {
            self.showSlide(at: UInt(i.row))
            _indexPathForPreferredFocusedView = i
            
        }
    }
    
    func collectionView(collectionView: UICollectionView, canFocusItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        print( "collectionView.canFocusItemAtIndexPath(\(indexPath.row))" )
        return true
    }
    
    
    func indexPathForPreferredFocusedViewInCollectionView(collectionView: UICollectionView) -> NSIndexPath? {
        print("collectionView.indexPathForPreferredFocusedViewInCollectionView: \(_indexPathForPreferredFocusedView)")
        
        // Return index path for selected show that you will be playing
        return _indexPathForPreferredFocusedView
    }
    
    // MARK: Presses Handling
    
    override func pressesBegan(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        print("pressesBegan")
        
        
        if let press = presses.first {
            
            switch press.type {
                case .PlayPause:
                    playPauseSlideShow( )
                    break
                case .Menu:
                    settingsBar.hide(animated: true) ;
                    _preferredFocusedView = pageView
                    break
                default:
                    break
            }

            pressesSubject.on( .Next(press) )
        }
    }
    
    override func pressesChanged(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        if let press = presses.first {
            pressesSubject.on( .Next(press) )
        }
    }
    
    override func pressesEnded(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
    }
    
    override func pressesCancelled(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
    }
    
}
