//
//  ChangeUserAccountAvatarOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation
import WebOperations

#if os(macOS)
import AppKit
public typealias AvatarImage = NSImage

#else
import UIKit
public typealias AvatarImage = UIImage
#endif

import func AVFoundation.AVMakeRect

// :nodoc:
class ChangeUserAccountAvatarOperation: BaseOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    var signature: String
    var image: AvatarImage
    
    init(account: Account, chainProvider: ChainProvider, signature: String, image: AvatarImage) {
        self.account = account
        self.signature = signature
        self.chainProvider = chainProvider
        self.image = image
    }
    
    override func main() {
        
        super.main()
        
        #if os(macOS)
        
        let width = image.size.width
        let height = image.size.height
        
        #else
        
        let width = image.size.width * image.scale
        let height = image.size.height * image.scale
        
        #endif

        if width > 600 || height > 600 {
            
            guard let resizedImage = resizedImage(image: image) else {
                self.finish(retval: nil, error: Proton.ProtonError(message: "ERROR RESIZING IMAGE"))
                return
            }
            
            image = resizedImage
            
        }
        
        #if os(macOS)
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "ERROR CONVERTING IMAGE TO DATA"))
            return
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let imageData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:]) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "ERROR CONVERTING IMAGE TO DATA"))
            return
        }
        
        #else
        
        guard let imageData = self.image.jpegData(compressionQuality: 1) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "ERROR CONVERTING IMAGE TO DATA"))
            return
        }
        
        #endif
        
        
        var path = ""
        
        guard let baseUrl = Proton.config?.baseUrl else {
            fatalError("⚛️ PROTON ERROR: BaseUrl must be valid")
        }
        
        DispatchQueue.main.sync {
            path = "\(baseUrl)\(chainProvider.updateAccountAvatarPath.replacingOccurrences(of: "{{account}}", with: account.name.stringValue))"
        }
        
        guard let url = URL(string: path) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to form URL for updateAccountNameUrl"))
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(signature)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let httpBody = NSMutableData()
        
        if let nameFieldData = convertFormField(named: "account", value: account.name.stringValue, using: boundary).data(using: .utf8) {
            httpBody.append(nameFieldData)
        }
        
        httpBody.append(convertFileData(fieldName: "img", fileName: "img.jpeg", mimeType: "image/jpeg", fileData: imageData, using: boundary))
        
        if let endBoundaryData = "--\(boundary)--".data(using: .utf8) {
            httpBody.append(endBoundaryData)
        }

        request.httpBody = httpBody as Data
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                self.finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
                return
            }

            guard let response = response as? HTTPURLResponse else {
                self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to parse response"))
                return
            }

            if !(200...299).contains(response.statusCode) {
                self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to parse response", response: response.statusCode))
                return
            }

            DispatchQueue.main.async {
                self.finish(retval: nil, error: nil)
            }

        }

        task.resume()
        
    }
    
    func resizedImage(image: AvatarImage, for size: CGSize = CGSize(width: 600, height: 600)) -> AvatarImage? {
        #if os(macOS)
        let destSize = NSMakeSize(size.width, size.height)
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        image.draw(in: NSMakeRect(0, 0, destSize.width, destSize.height), from: NSMakeRect(0, 0, image.size.width, image.size.height), operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return newImage
        #else
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image.draw(in: AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: .zero, size: size)))
        }
        #endif
    }
    
    func convertFileData(fieldName: String, fileName: String, mimeType: String, fileData: Data, using boundary: String) -> Data {
        
        let data = NSMutableData()

        if let boundaryData = "--\(boundary)\r\n".data(using: .utf8) {
            data.append(boundaryData)
        }
        
        if let dispositionData = "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8) {
            data.append(dispositionData)
        }
        
        if let contentTypeData = "Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8) {
            data.append(contentTypeData)
        }
        
        data.append(fileData)
        
        if let endData = "\r\n".data(using: .utf8) {
            data.append(endData)
        }

        return data as Data
    }
    
    func convertFormField(named name: String, value: String, using boundary: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"
        return fieldString
    }
    
}
