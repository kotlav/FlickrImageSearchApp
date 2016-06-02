//
//  ViewController.swift
//  FlickrImageSearchApp
//
//

import UIKit

class HomeViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet weak var resultsLabel: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView! // Holds Flickr Response Data in a grid like UI
    
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout! {
        didSet{
            collectionViewFlowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10) // Section Set insets
        }
    }
    
    @IBOutlet weak var searchBar: UISearchBar! // To search flickr photos api by tag
    
    // MARK: Instance Variables
    var sizingCell:FlickrCollectionViewCell? // Temp cell to calculate height of each collection view cell
    
    var items:[FlickrObject]? { // Array to load items to collection view
        didSet {
            collectionView?.reloadData() // Reloads collectionview if datasource changes
            resultsLabel?.text = "Showing \(items?.count ?? 0) results" // updates result label accordingly
        }
    }
    
    var imageCache:[String:UIImage] = [String:UIImage]() // Image cache that holds images against their id. Helps in preventing downloading of images everytime collection view scrolls to a particular cell
    var sizeCache:[String:CGSize] = [String:CGSize]() // Size cache holds CGSize of every cell, to prevent calculation of collection view cell if needed
    var favoriteCache:[String:Int] = [String:Int]() // Favorite cache holds favorite tag status for every cell. This ensures if the same image comes up as a result of a different tag search, the image is shown as already favorited.
    
    var searchByTagServiceTask:FlickrSeachByTagServiceTask? // This NSURLSession DataTask searches Flickr Rest API by given tag
    
    // MARK: View Controller Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpCollectionView()
        
        loadPrebundleDataFile()
    }
    
    // This function registers nib for Colletion View and creates a separate instance of collection view cell and saves as an instance variable, to be used for resizing purpose later
    func setUpCollectionView() {
        // Register Nib to use in Collection View
        let nib = UINib(nibName: FlickrCollectionViewCell.nibName, bundle: nil)
        collectionView?.registerNib(nib, forCellWithReuseIdentifier:FlickrCollectionViewCell.reuseIdentifier)
        
        let sizingNib = NSBundle.mainBundle().loadNibNamed(FlickrCollectionViewCell.nibName, owner: FlickrCollectionViewCell.self, options: nil) as NSArray
        sizingCell = sizingNib.objectAtIndex(0) as? FlickrCollectionViewCell

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        // Reset complete cache when memory warning comes
        resetInMemoryCache(shouldResetFavoriteCache: true)
    }

}

// MARK: Collection View Data Source and Delegate
extension HomeViewController:UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(FlickrCollectionViewCell.reuseIdentifier, forIndexPath: indexPath) as! FlickrCollectionViewCell
        
        if let data = items?[indexPath.item] {
            cell.configureCellWithData(data, delegate: self)
        }
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        // Cancel download image task as cell is not viewable to user
        let flickrCell = cell as? FlickrCollectionViewCell
        flickrCell?.serviceTask?.cancelTask()
    }
    
    // Returns height of each collection view cell
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        guard let data = items?[indexPath.item], let sizingCell = sizingCell else {
            return CGSizeZero
        }
        
        // Calculates cell height using resizing cell
        if let size = sizeCache[data.id] {
            return size
        } else {
            sizingCell.configureCellForSize(data)
            
            sizingCell.updateConstraintsIfNeeded()
            sizingCell.layoutIfNeeded()
            
            let width = collectionView.bounds.size.width / 2 - collectionViewFlowLayout.sectionInset.left -  collectionViewFlowLayout.sectionInset.right
            let height = sizingCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 10
            let size = CGSizeMake(width, height)
            sizeCache[data.id] = size
            return size
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // Resigns search bar responder when scrollview starts scrolling
        resignSearchBarTextResponder()
    }
}

// MARK: Search Bar Delegate
extension HomeViewController:UISearchBarDelegate {
    // Cancel button action
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        resignSearchBarTextResponder()
    }
    
    // This function dismisses keyboard
    func resignSearchBarTextResponder() {
        if searchBar.isFirstResponder() {
            searchBar.resignFirstResponder()
        }
    }
    
    // Search button on keyboard action
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        resignSearchBarTextResponder()
    }
    
    // This function sends text entered to
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.characters.count > 0 {
            updateSearchResults(searchText)
        } else {
            searchByTagServiceTask?.cancelTask()
            searchByTagServiceTask = nil
            self.resetInMemoryCache()
            self.items = nil
        }
    }
}

// MARK: Data Management
extension HomeViewController {
    // MARK: Load Prebundle Data
    func loadPrebundleDataFile() {
        // A json is prebundled with the app to show some results on app launch. This JSON is used to write test cases as well.
        guard let dataFile = NSBundle.mainBundle().URLForResource("welcome-flickr-search", withExtension: "json") else {
            return
        }
        
        guard let data = NSData(contentsOfURL: dataFile) else {
            return
        }
        
        guard let flickrSearchResponse = FlickrSearchResponse(data: data) else {
            return
        }
        
        searchBar?.text = "Graphic"
        
        items = flickrSearchResponse.items
    }
    
    // MARK: Load Data from Server
    func updateSearchResults(searchText:String) {
        searchByTagServiceTask?.cancelTask()
        searchByTagServiceTask = nil
        
        searchByTagServiceTask = FlickrSeachByTagServiceTask(tag: searchText)
        searchByTagServiceTask?.dataFromFlickrService({ (data, response, error) in
            NSOperationQueue.mainQueue().addOperationWithBlock({[weak self] in
                guard let data = data else {
                    return
                }
                guard let flickrSearchResponse = FlickrSearchResponse(data: data) else {
                    return
                }
                self?.resetInMemoryCache()
                self?.items = nil
                self?.items = flickrSearchResponse.items
        })
        })
    }
    
    // MARK: Reset In-Memory Cache
    func resetInMemoryCache(shouldResetFavoriteCache shouldResetFavoriteCache:Bool = false) {
        imageCache = [String:UIImage]()
        sizeCache = [String:CGSize]()
        
        if shouldResetFavoriteCache { // No Need to reset favorite cache for every search
            favoriteCache = [String:Int]()
        }
    }
}