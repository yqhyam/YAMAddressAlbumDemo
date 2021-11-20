//
//  YAMAssetsManager.swift
//  YAMAlbumAdressParserDemo
//
//  Created by ext.yangqinghui1 on 2021/7/22.
//

import UIKit
import Photos

class YAMAssetsManager: NSObject {
    
    private var cachedAlbums: [YAMAsset]?
    
    // 返回带有经纬度的不重复的本地媒体
    func fetchAlbums() -> [YAMAsset] {
        if let cachedAlbums = cachedAlbums {
            return cachedAlbums
        }
        
        var ids: Set<String> = []
        var albums: [YAMAsset] = []
        let options = PHFetchOptions()
        
        let smartAlbumsResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                        subtype: .any,
                                                                        options: options)
        let albumsResult = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                   subtype: .any,
                                                                   options: options)
        for result in [smartAlbumsResult, albumsResult] {
            result.enumerateObjects({ assetCollection, _, _ in

                let count = self.mediaCountFor(collection: assetCollection)
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                options.predicate = NSPredicate(format: "mediaType = %d",
                                                PHAssetMediaType.image.rawValue)
                if count > 0 {
                    let r = PHAsset.fetchAssets(in: assetCollection, options: options)
                    
                    r.enumerateObjects { (asset, idx, _) in
                        let a = ids.insert(asset.localIdentifier)
                        if a.inserted && asset.location?.coordinate != nil {
                            var obj = YAMAsset()
                            obj.asset = asset
                            obj.localIdentifier = asset.localIdentifier
                            obj.date = asset.creationDate
                            obj.coor = asset.location?.coordinate
                            albums.append(obj)
                        }
                    }
                }
            })
        }
        
        cachedAlbums = albums
        return albums
    }
    
    func mediaCountFor(collection: PHAssetCollection) -> Int {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d",
                                        PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(in: collection, options: options)
        return result.count
    }
    
    private func titleOfAlbumForChinse(title:String?) -> String? {
        if title == "Slo-mo" {
            return "慢动作"
        } else if title == "Recently Added" {
            return "最近添加"
        } else if title == "Favorites" {
            return "个人收藏"
        } else if title == "Recently Deleted" {
            return "最近删除"
        } else if title == "Videos" {
            return "视频"
        } else if title == "All Photos" {
            return "所有照片"
        } else if title == "Selfies" {
            return "自拍"
        } else if title == "Screenshots" {
            return "屏幕快照"
        } else if title == "Camera Roll" {
            return "相机胶卷"
        }
        return title
    }
}
