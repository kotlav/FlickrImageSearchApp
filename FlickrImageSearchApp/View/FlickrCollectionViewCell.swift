//
//  FlickrCollectionViewCell.swift
//  FlickrImageSearchApp
//
//
import UIKit

class FlickrCollectionViewCell: UICollectionViewCell {
    
    // MARK: static iVars
    static let reuseIdentifier = "FlickrCollectionViewCell"
    static let nibName = "FlickrCollectionViewCell"
    
    // MARK: IBOutlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var tags: UILabel!
    @IBOutlet weak var flickrImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var flickrFavoriteButton: UIButton!

    // MARK: iVars
    var serviceTask:FlickrDownloadImageServiceTask? // NSURLSession Data Task to download image from flickr server
    
    var flickrObject:FlickrObject? // ViewModel Object to configure collection view cell
    
    weak var home:HomeViewController? // Weak Reference to Home to fill imageCache and favorite cache
    
    // MARK: Favorite/Not Favorite State
    let favoriteImage = UIImage(imageLiteral: "favorite")
    let notfavoriteImage = UIImage(imageLiteral: "notfavorite")
    
    var isFavorite:Bool = false {
        didSet {
            var intValue = 0
            if isFavorite {
                flickrFavoriteButton.setImage(favoriteImage, forState: .Normal)
                intValue = 1
            } else {
                flickrFavoriteButton.setImage(notfavoriteImage, forState: .Normal)
                intValue = 0
            }
            if let id = flickrObject?.id {
                home?.favoriteCache[id] = intValue
            }
        }
    }
    
    // MARK: View Lifecycle Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 2.0;
        layer.shadowColor = UIColor.lightGrayColor().CGColor
        layer.shadowOffset = CGSizeMake(0, 0.0);
        layer.shadowRadius = 2.0;
        layer.shadowOpacity = 1.0;
        layer.masksToBounds = false
    }
    
    override func layoutSubviews() {
        title.preferredMaxLayoutWidth = title.bounds.size.width;
        tags.preferredMaxLayoutWidth = tags.bounds.size.width;
        
        super.layoutSubviews()
    }
    
    // MARK: Configure Cell With Data
    
    // This function configures cell view with VM object. This VM object is parsed from the JSON that is either downloaded from flickr server or prebundled
    func configureCellWithData(data:FlickrObject, delegate:HomeViewController? = nil) {
        title.text = data.title
        flickrImageHeightConstraint?.constant = CGFloat(data.height)
        flickrObject = data
        
        self.home = delegate
        
        imageView.image = nil
        
        // If image is present in cache, sets image otherwise loads from Flickr Server
        if let image = home?.imageCache[data.id]  {
            imageView.image = image
        } else {
            loadImage()
        }
        
        // Reads FavoriteCache for favorite status
        if let intValue = home?.favoriteCache[data.id] {
            isFavorite = intValue == 1 ? true : false
        } else {
           isFavorite = false
        }
        
        loadTags(data.tags)
    }
    
    // This light-weight function is used to configure cell that helps in calculation of cell size
    func configureCellForSize(data:FlickrObject) {
        title.text = data.title
        loadTags(data.tags)
        flickrImageHeightConstraint?.constant = CGFloat(data.height)
    }

}

extension FlickrCollectionViewCell {
    // MARK: Image Loader
    
    // This function uses NSURLSession to download image from flickr web-service and after downloading saves image against object id.
    func loadImage() {
        guard let imageUrl = flickrObject?.imageUrl else {
            return
        }
        
        serviceTask = FlickrDownloadImageServiceTask(imageUrl: imageUrl)
        serviceTask?.dataFromFlickrService({ (data, response, error) in
            NSOperationQueue.mainQueue().addOperationWithBlock({[weak self] in
                guard let data = data else {
                    return
                }
                
                let image = UIImage(data: data)
                
                if let id = self?.flickrObject?.id {
                    self?.home?.imageCache[id] = image
                }
                
                self?.imageView.image = image
                self?.imageView.alpha = 0.0
                
                UIView.animateWithDuration(0.4, animations: {[weak self] in
                    self?.imageView.alpha = 1.0
                })
                
                })
        })
        
    }
}

extension FlickrCollectionViewCell {
    // MARK: Toggles favorite button status
    @IBAction func flickrFavoriteButtonPressed(sender: UIButton) {
        isFavorite = isFavorite ? false : true
    }
    
}

extension FlickrCollectionViewCell {
    // MARK: Tags Loader
    
    // Flickr SearchByTag service returns a lot of tags. Here, limiting tags shown as 3. Also, using attributed string to show alternate tags in different color.
    func loadTags(tagsArray:[String]?) {
        guard let tagsArray = tagsArray where tagsArray.count > 0 else {
            tags.attributedText = nil
            return
        }

        // Max three tags should be in the cell
        let mutableAttributedString:NSMutableAttributedString = NSMutableAttributedString()
        var i = 0
        for tag in tagsArray {
            
            let tagString =  "#\(tag) "
            
            var attrs:[String : AnyObject]?
            
            if i%2 == 0 {
                attrs = [NSForegroundColorAttributeName: UIColor.blackColor()]
            } else {
                attrs = [NSForegroundColorAttributeName: UIColor(red: 91.0/255.0, green: 178.0/255.0, blue: 160.0/255.0, alpha: 1.0)]
            }
            let attributedStr = NSAttributedString(string: tagString, attributes: attrs)
            mutableAttributedString.appendAttributedString(attributedStr)
            if i == 2 {
                break
            }
            
            i = i+1
        }
        tags.attributedText = mutableAttributedString
    }
}