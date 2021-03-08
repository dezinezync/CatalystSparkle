//
//  DZNetworking.swift
//  DZNetworking
//
//  Created by Nikhil Nigade on 08/03/21.
//  Copyright © 2021 Dezine Zync Studios LLP. All rights reserved.
//

import Foundation
import DZNetworking

public typealias successTypedBlock<R: Decodable> = (Result<(HTTPURLResponse?, R?), Error>) -> Void

extension DZURLSession {
    
    @discardableResult public func GET<R: Decodable>(path: String, query: [String: String]?, completion: @escaping successTypedBlock<R>) -> URLSessionTask? {
        
        return performRequest(withURI: path, method: "GET", params: query) { [weak self] (data, response, _) in
            
            guard let data = data else {
                completion(.success((response, nil)))
                return
            }
            
            self?.decodeResponse(data: data as! Data, response: response, completion: completion)
            
        } error: { (error: Error?, response, _) in
            
            guard let error = error else {
                return
            }
            
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            
        }
        
    }
    
    @discardableResult public func POST<R: Decodable>(path: String, query: [String: String]?, body: [String: AnyHashable]?, completion: @escaping successTypedBlock<R>) -> URLSessionTask? {
        
        return performRequest(withURI: path, method: "POST", query: query, body: body) { [weak self] (data, response, _) in
            
            guard let data = data else {
                completion(.success((response, nil)))
                return
            }
            
            self?.decodeResponse(data: data as! Data, response: response, completion: completion)
            
        } error: { (error: Error?, response, _) in
            
            guard let error = error else {
                return
            }
            
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            
        }
        
    }
    
    @discardableResult public func PUT<R: Decodable>(path: String, query: [String: String]?, body: [String: AnyHashable]?, completion: @escaping successTypedBlock<R>) -> URLSessionTask? {
        
        return performRequest(withURI: path, method: "PUT", query: query, body: body) { [weak self] (data, response, _) in
            
            guard let data = data else {
                completion(.success((response, nil)))
                return
            }
            
            self?.decodeResponse(data: data as! Data, response: response, completion: completion)
            
        } error: { (error: Error?, response, _) in
            
            guard let error = error else {
                return
            }
            
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            
        }
        
    }
    
    @discardableResult public func PATCH<R: Decodable>(path: String, query: [String: String]?, completion: @escaping successTypedBlock<R>) -> URLSessionTask? {
        
        return performRequest(withURI: path, method: "PATCH", params: query) { [weak self] (data, response, task) in
            
            guard let data = data else {
                completion(.success((response, nil)))
                return
            }
            
            self?.decodeResponse(data: data as! Data, response: response, completion: completion)
            
        } error: { (error: Error?, response, _) in
            
            guard let error = error else {
                return
            }
            
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            
        }
        
    }
    
    @discardableResult public func DELETE<R: Decodable>(path: String, query: [String: String]?, completion: @escaping successTypedBlock<R>)  -> URLSessionTask? {
        
        return performRequest(withURI: path, method: "DELETE", params: query) { [weak self] (data, response, task) in
            
            guard let data = data else {
                completion(.success((response, nil)))
                return
            }
            
            self?.decodeResponse(data: data as! Data, response: response, completion: completion)
            
        } error: { (error: Error?, response, _) in
            
            guard let error = error else {
                return
            }
            
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            
        }
        
    }
    
    @discardableResult public func HEAD<R: Decodable>(path: String, query: [String: String]?, completion: @escaping successTypedBlock<R>)  -> URLSessionTask? {
        
        return performRequest(withURI: path, method: "HEAD", params: query) { [weak self] (data, response, task) in
            
            guard let data = data else {
                completion(.success((response, nil)))
                return
            }
            
            self?.decodeResponse(data: data as! Data, response: response, completion: completion)
            
        } error: { (error: Error?, response, _) in
            
            guard let error = error else {
                return
            }
            
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            
        }
        
    }
    
    @discardableResult public func OPTIONS<R: Decodable>(path: String, query: [String: String]?, completion: @escaping successTypedBlock<R>)  -> URLSessionTask? {
        
        return performRequest(withURI: path, method: "OPTIONS", params: query) { [weak self] (data, response, task) in
            
            guard let data = data else {
                completion(.success((response, nil)))
                return
            }
            
            self?.decodeResponse(data: data as! Data, response: response, completion: completion)
            
        } error: { (error: Error?, response, _) in
            
            guard let error = error else {
                return
            }
            
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            
        }
        
    }
    
    public func decodeResponse<R: Decodable>(data: Data, response: HTTPURLResponse?,  completion: @escaping successTypedBlock<R>) {
        
        let dateDecoding: JSONDecoder.DateDecodingStrategy = .iso8601
        let keyDecoding: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecoding
        decoder.keyDecodingStrategy = keyDecoding
        
        do {
            let decoded = try decoder.decode(R.self, from: data)
            DispatchQueue.main.async {
                completion(.success((response, decoded)))
            }
        }
        catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
        
    }
    
}
