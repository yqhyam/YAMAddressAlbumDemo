//
//  YAMNetworkOperation.swift
//  YAMAlbumAdressParserDemo
//
//  Created by ext.yangqinghui1 on 2021/7/22.
//

import UIKit
import Alamofire

class YAMNetworkOperation: AsynchronousOperation {

    // define properties to hold everything that you'll supply when you instantiate
    // this object and will be used when the request finally starts
    //
    // in this example, I'll keep track of (a) URL; and (b) closure to call when request is done

    private let urlString: String
    private let params: [String: Any]
    private var networkOperationCompletionHandler: ((_ responseObject: Any?, _ error: Error?) -> Void)?

    // we'll also keep track of the resulting request operation in case we need to cancel it later
    
    weak var request: Alamofire.Request?
    
    // define init method that captures all of the properties to be used when issuing the request

    init(urlString: String, params: [String: Any], networkOperationCompletionHandler: ((_ responseObject: Any?, _ error: Error?) -> Void)? = nil) {
        self.urlString = urlString
        self.params = params
        self.networkOperationCompletionHandler = networkOperationCompletionHandler
        super.init()
    }

    // when the operation actually starts, this is the method that will be called

    override func main() {
        
        request = AF.request(urlString, method: .get, parameters: params)
            .responseJSON { response in
                // do whatever you want here; personally, I'll just all the completion handler that was passed to me in `init`
                switch response.result {
                case .success(let res):
                    self.networkOperationCompletionHandler?(res, response.error)
                    self.networkOperationCompletionHandler = nil
                    break
                default:
                    break
                }
                
                
                // now that I'm done, complete this operation
                
                self.completeOperation()
        }
    }

    // we'll also support canceling the request, in case we need it

    override func cancel() {
//        request?.cancel()
        super.cancel()
    }
}

public class AsynchronousOperation : Operation {

    private let stateLock = NSLock()

    private var _executing: Bool = false
    override private(set) public var isExecuting: Bool {
        get {
            return stateLock.withCriticalScope { _executing }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            stateLock.withCriticalScope { _executing = newValue }
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var _finished: Bool = false
    override private(set) public var isFinished: Bool {
        get {
            return stateLock.withCriticalScope { _finished }
        }
        set {
            willChangeValue(forKey: "isFinished")
            stateLock.withCriticalScope { _finished = newValue }
            didChangeValue(forKey: "isFinished")
        }
    }

    /// Complete the operation
    ///
    /// This will result in the appropriate KVN of isFinished and isExecuting

    public func completeOperation() {
        if isExecuting {
            isExecuting = false
        }

        if !isFinished {
            isFinished = true
        }
    }

    override public func start() {
        if isCancelled {
            isFinished = true
            return
        }

        isExecuting = true

        main()
    }

    override public func main() {
        fatalError("subclasses must override `main`")
    }
}

extension NSLocking {

    /// Perform closure within lock.
    ///
    /// An extension to `NSLocking` to simplify executing critical code.
    ///
    /// - parameter block: The closure to be performed.

    func withCriticalScope<T>(block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}
