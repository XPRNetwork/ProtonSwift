//
//  WebServices.swift
//  ProtonChain
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

enum WebServiceError: Error, LocalizedError {
    case error(String)
    
    public var errorDescription: String? {
        switch self {
        case .error(let message):
            return "🌐 \(message)"
        }
    }
}

class WebServices: NSObject {
    
    var operationQueueSeq: OperationQueue
    var operationQueueMulti: OperationQueue
    
    static let shared = WebServices()
    
    private override init() {
        
        operationQueueSeq = OperationQueue()
        operationQueueSeq.qualityOfService = .utility
        operationQueueSeq.maxConcurrentOperationCount = 1
        operationQueueSeq.name = "\(UUID()).seq"
        
        operationQueueMulti = OperationQueue()
        operationQueueMulti.qualityOfService = .utility
        operationQueueMulti.name = "\(UUID()).multi"
        
    }
    
    // MARK: - Operation Services
    
    func addSeq(_ operation: AbstractOperation,
                completion: ((Result<Any?, Error>) -> Void)?) {
        
        operation.completion = completion
        operationQueueSeq.addOperation(operation)
        
    }
    
    func addMulti(_ operation: AbstractOperation,
                  completion: ((Result<Any?, Error>) -> Void)?) {
        
        operation.completion = completion
        operationQueueSeq.addOperation(operation)
        
    }
    
    func suspend(_ isSuspended: Bool) {
        operationQueueSeq.isSuspended = isSuspended
        operationQueueMulti.isSuspended = isSuspended
    }
    
    func cancelAll() {
        operationQueueSeq.cancelAllOperations()
        operationQueueMulti.cancelAllOperations()
    }
    
    // MARK: - HTTP Base Requests
    
    func getRequest(withURL url: URL, completion: ((Result<Data?, Error>) -> Void)?) {
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: url) { data, response, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error(error.localizedDescription)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("No data")))
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Response Error")))
                }
                return
            }
            
            if !(200...299).contains(response.statusCode) {
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Response Error Status code: \(response.statusCode)")))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion?(.success(data))
            }
            
        }
        
        task.resume()
        
    }
    
    func getRequestJSON(withURL url: URL, completion: ((Result<Any?, Error>) -> Void)?) {
        
        getRequest(withURL: url) { result in
            
            switch result {
                
            case .success(let data):
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion?(.failure(WebServiceError.error("No data")))
                    }
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    DispatchQueue.main.async {
                        completion?(.success(json))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion?(.failure(error))
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
                
            }
            
        }
        
    }
    
    func getRequest<T: Codable>(withURL url: URL, completion: ((Result<T, Error>) -> Void)?) {
        
        getRequest(withURL: url) { result in
            
            switch result {
                
            case .success(let data):
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion?(.failure(WebServiceError.error("No data")))
                    }
                    return
                }
                
                do {
                    let res = try JSONDecoder().decode(T.self, from: data)
                    DispatchQueue.main.async {
                        completion?(.success(res))
                    }
                } catch {
                    completion?(.failure(error))
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
            }
            
        }
        
    }
    
    func postRequestData(withURL url: URL, parameters: [String: Any]? = nil, completion: ((Result<Data?, Error>) -> Void)?) {
        
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        if let parameters = parameters, !parameters.isEmpty {
            do {
                let body = try JSONSerialization.data(withJSONObject: parameters, options: [])
                request.httpBody = body
            } catch {
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
            }
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("No data")))
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Response Error")))
                }
                return
            }
            
            if !(200...299).contains(response.statusCode) {
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Response Error Status code: \(response.statusCode)")))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion?(.success(data))
            }
            
        }
        
        task.resume()
        
    }
    
}
