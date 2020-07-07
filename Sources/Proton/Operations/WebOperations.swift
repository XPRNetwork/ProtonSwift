//
//  WebOperations.swift
//  ProtonChain
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation

enum WebOperationError: Error, LocalizedError {
    case error(String)
    
    public var errorDescription: String? {
        switch self {
        case .error(let message):
            return "🌐 \(message)"
        }
    }
}

class WebOperations: NSObject {
    
    var operationQueueSeq: OperationQueue
    var operationQueueMulti: OperationQueue
    
    enum RequestMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }
    
    enum Auth: String {
        case basic = "Basic"
        case bearer = "Bearer"
        case none = "none"
    }
    
    enum ContentType: String {
        case applicationJson = "application/json"
        case none = ""
    }
    
    static let shared = WebOperations()
    
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
        operationQueueMulti.addOperation(operation)
        
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
    
    // TODO: Decided to use URLSession.shared or create custom sessions...
    
    func request(method: RequestMethod = .get, auth: Auth = .none, authValue: String? = nil, contentType: ContentType = .applicationJson, url: URL, parameters: [String: Any]? = nil, completion: ((Result<Data?, Error>) -> Void)?) {
        
        let session = URLSession.shared

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let authValue = authValue, auth != .none {
            request.addValue("\(auth.rawValue) \(authValue)", forHTTPHeaderField: "Authorization")
        }

        if contentType == .applicationJson {
            request.addValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
            request.addValue(contentType.rawValue, forHTTPHeaderField: "Accept")
        }

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
                    completion?(.failure(WebOperationError.error("No data")))
                }
                return
            }

            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion?(.failure(WebOperationError.error("Response Error")))
                }
                return
            }

            if !(200...299).contains(response.statusCode) {
                DispatchQueue.main.async {
                    completion?(.failure(WebOperationError.error("Response Error Status code: \(response.statusCode)")))
                }
                return
            }

            DispatchQueue.main.async {
                completion?(.success(data))
            }

        }

        task.resume()
        
    }

    func request<T: Any>(method: RequestMethod = .get, auth: Auth = .none, authValue: String? = nil, contentType: ContentType = .applicationJson, url: URL, parameters: [String: Any]? = nil, completion: ((Result<T?, Error>) -> Void)?) {

        request(method: method, auth: auth, authValue: authValue, contentType: contentType, url: url, parameters: parameters) { result in

            switch result {

            case .success(let data):

                guard let data = data else {
                    DispatchQueue.main.async {
                        completion?(.failure(WebOperationError.error("No data")))
                    }
                    return
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    DispatchQueue.main.async {
                        completion?(.success(json as? T))
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
    
    func request<T: Codable>(method: RequestMethod = .get, auth: Auth = .none, authValue: String? = nil, contentType: ContentType = .applicationJson, url: URL, parameters: [String: Any]? = nil, completion: ((Result<T, Error>) -> Void)?) {

        request(method: method, auth: auth, authValue: authValue, contentType: contentType, url: url, parameters: parameters) { result in

            switch result {

            case .success(let data):

                guard let data = data else {
                    DispatchQueue.main.async {
                        completion?(.failure(WebOperationError.error("No data")))
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
    
}
