//
//  PhotosViewController.swift
//  YAMAlbumAdressParserDemo
//
//  Created by ext.yangqinghui1 on 2021/8/17.
//

import UIKit
import Photos

class PhotosViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var album: YAMAddressAlbum?
    var assets: PHFetchResult<PHAsset>?
    var collectionView: UICollectionView!
    
    let cellW: CGFloat = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = album?.city
        self.view.backgroundColor = .white
        self.assets = PHAsset.fetchAssets(withLocalIdentifiers: album?.localIdentifier ?? [], options: nil)
        
        let backItem = UIBarButtonItem(title: "返回", style: .done, target: self, action: #selector(backClicked))
        self.navigationItem.leftBarButtonItem = backItem
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: cellW, height: cellW)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        
        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        view.addSubview(collectionView)
    }
    
    @objc func backClicked() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        cell.backgroundColor = .red
        if let asset = assets?.object(at: indexPath.row) {
            let deviceScale = UIScreen.main.scale
            let targetSize = CGSize(width: cellW*deviceScale, height: cellW*deviceScale)
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .opportunistic
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { (image, _) in
                cell.image = image
            }
        }
        return cell
    }
}
