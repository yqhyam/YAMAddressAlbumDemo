//
//  YAMAsset.swift
//  YAMAlbumAdressParserDemo
//
//  Created by ext.yangqinghui1 on 2021/7/22.
//

import Foundation
import Photos

struct YAMAsset {
    /// 本地资源
    var asset: PHAsset?
    /// 资源 id
    var localIdentifier: String?
    /// 照片创建时间
    var date: Date?
    /// 经纬度
    var coor: CLLocationCoordinate2D?
}
