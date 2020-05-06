//
//  WebServices.swift
//  ProtonChain
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

enum WebServiceError: Error {
    case error(String)
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
                print("Client error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error(error.localizedDescription)))
                }
                return
            }
            
            guard let data = data else {
                print("Client Data error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("No data")))
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Response error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Response Error")))
                }
                return
            }
            
            guard let mime = response.mimeType, mime == "application/json" else {
                print("Wrong MIME type!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Wrong MIME type!")))
                }
                return
            }
            
            do {
                
                _ = try JSONSerialization.jsonObject(with: data, options: [])
                // print(json)
                DispatchQueue.main.async {
                    completion?(.success(data))
                }
                
            } catch {
                print("JSON error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("JSON error: \(error.localizedDescription)")))
                }
            }
            
        }
        
        task.resume()
        
    }
    
    func getRequestJSON(withURL url: URL, completion: ((Result<Any?, Error>) -> Void)?) {
        
        getRequest(withURL: url) { result in
            
            switch result {
                
            case .success(let data):
                
                guard let data = data else {
                    print("Client Data error!")
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
                    print("JSON error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion?(.failure(WebServiceError.error("JSON error: \(error.localizedDescription)")))
                    }
                }
                
            case .failure(let error):
                
                print("Client error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error(error.localizedDescription)))
                }
                
            }
            
        }
        
    }
    
    func getRequest<T: Codable>(withURL url: URL, completion: ((Result<T, Error>) -> Void)?) {
        
        getRequest(withURL: url) { result in
            
            switch result {
                
            case .success(let data):
                
                guard let data = data else {
                    print("Client Data error!")
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
                    print(error)
                }
                
            case .failure(let error):
                print("Client error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error(error.localizedDescription)))
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
                print("Parameter Serialization problem")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Parameter Serialization problem")))
                }
            }
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Client error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error(error.localizedDescription)))
                }
                return
            }
            
            guard let data = data else {
                print("Client Data error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("No data")))
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Response error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Response Error")))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion?(.success(data))
            }
            
        }
        
        task.resume()
        
    }
    
    func postRequestJSON(withURL url: URL, parameters: [String: Any]? = nil, completion: ((Result<Any?, Error>) -> Void)?) {
        
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
                print("Parameter Serialization problem")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Parameter Serialization problem")))
                }
            }
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Client error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error(error.localizedDescription)))
                }
                return
            }
            
            guard let data = data else {
                print("Client Data error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("No data")))
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Response error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Response Error")))
                }
                return
            }
            
            guard let mime = response.mimeType, mime == "application/json" else {
                print("Wrong MIME type!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Wrong MIME type!")))
                }
                return
            }
            
            do {
                
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                DispatchQueue.main.async {
                    completion?(.success(json))
                }
                
            } catch {
                print("JSON error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("JSON error: \(error.localizedDescription)")))
                }
            }
        }
        
        task.resume()
        
    }
    
    func postRequestJSON(withURL url: URL, data: Data, completion: ((Result<Any?, Error>) -> Void)?) {
        
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = data
        
        let task = session.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Client error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error(error.localizedDescription)))
                }
                return
            }
            
            guard let data = data else {
                print("Client Data error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("No data")))
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Response error!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Response Error")))
                }
                return
            }
            
            guard let mime = response.mimeType, mime == "application/json" else {
                print("Wrong MIME type!")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("Wrong MIME type!")))
                }
                return
            }
            
            do {
                
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                // print(json)
                DispatchQueue.main.async {
                    completion?(.success(json))
                }
                
            } catch {
                print("JSON error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion?(.failure(WebServiceError.error("JSON error: \(error.localizedDescription)")))
                }
            }
        }
        
        task.resume()
        
    }
    
}
