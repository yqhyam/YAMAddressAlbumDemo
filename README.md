# YAMAddressAlbumDemo

## 前言

在开启定位服务时，用户使用系统相机拍摄的照片 iOS 系统都会将照片拍摄地点的经纬度、时间等信息记录下来，作为一款基于地图的社交 app，产品基于此提出了一个需求，即将用户系统相册中所有带经纬度信息的照片按照地址来分类，自动生成地址相簿，如下图所示。

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a6cec40c5a524e89a81bbc3c28b35814~tplv-k3u1fbpfcp-watermark.image)


## 实现思路
分析需求后，可将实现过程分为三步：
1. 将系统相册中所有照片取出来并剔除没有经纬度信息的照片
    - 这里选择最快的查找方式就行，只用获取 id、经纬度等信息
2. 将照片的的 id、经纬度、时间等信息转换为 model 并缓存在内存和本地
    - 完成数据的转换后，把 Model 缓存在内存和本地，内存缓存这里我采用的是一个全局的单例，本地我采用的数据库方式
    - 在后面获取数据的时候，先查内存，如果内存没有，再查本地，获取到缓存数据后先展示，之后同时在后台查询是否有新照片，如果有新照片就还是上述步骤缓存起来并更新页面
3. 将所有照片的经纬度通过反地理编码转换为地址并按照需求城市或省份划分相簿

## 以下是关键代码：
### 这里的代码为第一步和第二步的部分实现
```
    // 返回带有经纬度的不重复的本地媒体
    func fetchAlbums() -> [YAMAsset] {
        // 如果有缓存则先返回缓存
        // 这里可以增加是否有新照片的判断和本地缓存，由于是 demo 就省掉了这块的实现
        if let cachedAlbums = cachedAlbums {
            return cachedAlbums
        }
        var ids: Set<String> = []
        var albums: [YAMAsset] = []
        let options = PHFetchOptions()
        // 选择最快的方式获取照片
        let smartAlbumsResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                        subtype: .any,
                                                                        options: options)
        let albumsResult = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                   subtype: .any,
                                                                   options: options)
        // 遍历所有照片资源
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
                        // 将 asset 转换为 model
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
        // 简单将数据缓存在内存中
        cachedAlbums = albums
        return albums
    }
```

### 第三步，这里的代码是整个功能的关键代码


反地理编码是用的高德提供的 API 接口，key需要自己去高德这里申请，另外不支持国外的经纬度解析
https://lbs.amap.com/api/webservice/guide/api/georegeo/#regeo
```
func loadData() {

        let items = YAMAssetsManager().fetchAlbums()
        let queue = OperationQueue()
        // 高德 api 最大并发为 200
        queue.maxConcurrentOperationCount = 200

        var ops: [Operation] = []
        var albumDict: [String: [String]] = [:]

        for item in items {
            guard let coor = item.coor else {
                return
            }
            // 这里需要将 xxx 换成自己申请的 key
            let params = ["key": "xxx",
                          "location": "\(coor.longitude),\(coor.latitude)",
                          "extensions": "base",
                          "batch": "true"] as [String : Any]
            // 通过高德的 api 接口解析经纬度
            let operation = YAMNetworkOperation(urlString: "https://restapi.amap.com/v3/geocode/regeo", params: params) { responseObject, error in

                if let json = responseObject as? [String: Any],
                    let regeocodes = json["regeocodes"] as? [Any],
                    regeocodes.count > 0 {

                    for (index, value) in regeocodes.enumerated() {
                    // 这里通过城市去分类照片
                        if let dict = value as? [String: Any], let res = dict["addressComponent"] as? [String: Any] {
                            let city = (res["city"] as? String) ?? (res["province"] as? String) ?? (res["country"] as? String) ?? "未知"
                            let area = res["district"] as? String ?? ""
                            let key = city + area

                            if albumDict[key] == nil {
                                albumDict[key] = []
                            }
                            albumDict[key]?.append(item.localIdentifier ?? "")
                            print(index)
                        }
                    }
                }
            }
            ops.append(operation)
        }

        let lastOperation = BlockOperation {
        /// 执行完毕后回调展示 刷新
            for (k, v) in albumDict {
                let album = YAMAddressAlbum()
                album.city = k
                album.localIdentifier = v
                self.albums.append(album)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }

        for op in ops {
            lastOperation.addDependency(op)
        }
        ops.append(lastOperation)
        queue.addOperations(ops, waitUntilFinished: false)

    }
```

功能 demo 待上传。
