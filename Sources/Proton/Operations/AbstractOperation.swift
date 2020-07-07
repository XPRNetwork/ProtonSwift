//
//  AbstractOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation

class AbstractOperation: Operation {
    
    var abstractOperation: AbstractOperation!
    var completion: ((Result<Any?, Error>) -> Void)!
    
    override init() {}
    
    convenience init(_ completion: @escaping ((Result<Any?, Error>) -> Void)) {
        self.init()
        self.completion = completion
    }
    
    private var _executing = false {
        willSet { willChangeValue(forKey: "isExecuting") }
        didSet { didChangeValue(forKey: "isExecuting") }
    }
    
    private var _finished = false {
        willSet { willChangeValue(forKey: "isFinished") }
        didSet { didChangeValue(forKey: "isFinished") }
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    override func main() {
        
        guard isCancelled == false else {
            finish()
            return
        }
        
        _executing = true
        
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    func finish(retval: Any? = nil, error: Error? = nil) {
        DispatchQueue.main.async {
            if let error = error {
                print(error.localizedDescription)
                self.completion?(.failure(error))
            } else {
                self.completion?(.success(retval))
            }
        }
        _executing = false
        _finished = true
    }
    
    func finish<T: Codable>(retval: T? = nil, error: Error? = nil) {
        DispatchQueue.main.async {
            if let error = error {
                print(error.localizedDescription)
                self.completion?(.failure(error))
            } else {
                self.completion?(.success(retval))
            }
        }
        _executing = false
        _finished = true
    }
    
}
