//
//  PhotoCollectionViewCell.swift
//  YAMAlbumAdressParserDemo
//
//  Created by ext.yangqinghui1 on 2021/8/17.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    var image: UIImage? {
        didSet {
            self.imageView.image = image
        }
    }
    
    private var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}
