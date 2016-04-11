//
//  SlideSearchViewController.swift
//  slides
//
//  Created by softphone on 11/04/16.
//  Copyright © 2016 soulsoftware. All rights reserved.
//
import RxSwift
import RxCocoa

class SearchSlideCollectionViewCell: UICollectionViewCell {
    // MARK: Properties
    
    static let reuseIdentifier = "SearchSlideCell"
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var imageView: UIImageView?
    
    var representedDataItem: Slideshow?
    
    // MARK: Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // These properties are also exposed in Interface Builder.
        imageView?.adjustsImageWhenAncestorFocused = true
        imageView?.clipsToBounds = false
        
        label.alpha = 0.0
    }
    
    // MARK: UICollectionReusableView
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset the label's alpha value so it's initially hidden.
        label.alpha = 0.0
    }
    
    // MARK: UIFocusEnvironment
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        /*
         Update the label's alpha value using the `UIFocusAnimationCoordinator`.
         This will ensure all animations run alongside each other when the focus
         changes.
         */
        coordinator.addCoordinatedAnimations({
            if self.focused {
                self.label.alpha = 1.0
            }
            else {
                self.label.alpha = 0.0
            }
            }, completion: nil)
    }
}


public class SearchSlidesViewController: UICollectionViewController, UISearchResultsUpdating {
    // MARK: Properties
    
    public static let storyboardIdentifier = "SearchSlidesViewController"
    
    //private let cellComposer = DataItemCellComposer()
    
    private var filteredDataItems:[Slideshow] = []
    
    let disposeBag = DisposeBag()
    
    let slidehareItemsParser = SlideshareItemsParser()
    
    //let searchResultsUpdatingSubject = PublishSubject<String>()

    var filterString = "" {
        didSet {
            // Return if the filter string hasn't changed.
            guard filterString != oldValue else { return }
            
            // Apply the filter or show all items if the filter string is empty.
            if filterString.isEmpty {
                filteredDataItems.removeAll()
            }
            else {
                
                slideshareSearch( apiKey: "N2ouIG0m", sharedSecret: "kWG85pR1", what: filterString )
                    .flatMap({ (data:NSData) -> Observable<Slideshow> in
                    
                        return self.slidehareItemsParser.rx_parse(data)
                    })
                    .observeOn(MainScheduler.instance)
                    .subscribe({ e in
                        
                        if let slide = e.element {
                            
                            self.filteredDataItems.append(slide)
                            
                            let title = slide["title"]
                            print( "\(title) \(self.collectionView)")
                            
                            self.collectionView?.reloadData()
                        }
                        
                    }).addDisposableTo(disposeBag)
                
                //filteredDataItems = allDataItems.filter { $0.title.localizedStandardContainsString(filterString) }
            }
            
            // Reload the collection view to reflect the changes.
        }
    }
    
    // MARK: UICollectionViewController Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: UICollectionViewDataSource
    
    override public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        /*
        guard let items = filteredDataItems else {
            return 0;
        }
        */
        return filteredDataItems.count
    }
    
    override public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Dequeue a cell from the collection view.
        return collectionView.dequeueReusableCellWithReuseIdentifier(SearchSlideCollectionViewCell.reuseIdentifier, forIndexPath: indexPath)
    }
    
    // MARK: UICollectionViewDelegate
    
    override public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? SearchSlideCollectionViewCell else { fatalError("Expected to display a `DataItemCollectionViewCell`.") }
        let item = filteredDataItems[indexPath.row]
        
        cell.label.text = item["title"]
        
        // Configure the cell.
        //cellComposer.composeCell(cell, withDataItem: item)

    }
    
    override public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: UISearchResultsUpdating
    
    public func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        //searchResultsUpdatingSubject.onNext(<#T##element: String##String#>)
        filterString = searchController.searchBar.text ?? ""
        
        
    }
}
