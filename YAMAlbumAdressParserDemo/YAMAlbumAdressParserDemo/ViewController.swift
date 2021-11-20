//
//  ViewController.swift
//  YAMAlbumAdressParserDemo
//
//  Created by ext.yangqinghui1 on 2021/7/22.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    var albums: [YAMAddressAlbum] = []

    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.contentInset = UIEdgeInsets(top: UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0, left: 0, bottom: 0, right: 0)
        tableView.frame = self.view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        view.addSubview(tableView)
        
        loadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let album = albums[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = "\(album.city ?? "未知")(\(album.localIdentifier.count))"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = PhotosViewController()
        vc.album = albums[indexPath.row]
        let nav = UINavigationController(rootViewController: vc)
        self.present(nav, animated: true, completion: nil)
    }
    
    func loadData() {
        let items = YAMAssetsManager().fetchAlbums()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 200
        
        var ops: [Operation] = []
        
        var albumDict: [String: [String]] = [:]

        for item in items {
            guard let coor = item.coor else {
                return
            }
            let params = ["key": "fd5e6ba6dbac9084015c04f1b4b1e33c",
                          "location": "\(coor.longitude),\(coor.latitude)",
                          "extensions": "base",
                          "batch": "true"] as [String : Any]
            
            let operation = YAMNetworkOperation(urlString: "https://restapi.amap.com/v3/geocode/regeo", params: params) { responseObject, error in
                if let json = responseObject as? [String: Any],
                    let regeocodes = json["regeocodes"] as? [Any],
                    regeocodes.count > 0 {
                    
                    for (index, value) in regeocodes.enumerated() {
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
            for (k, v) in albumDict {
                let album = YAMAddressAlbum()
                album.city = k
                album.localIdentifier = v
                self.albums.append(album)
            }
            print(self.albums)
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

}

