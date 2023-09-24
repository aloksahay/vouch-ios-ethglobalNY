//
//  ApiManager.swift
//  XMTPiOSExample
//
//  Created by Alok Sahay on 23.09.2023.
//


import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case decodingFailed
}

class APIManager {
    
    func fetchProfile(address: String, completion: @escaping (Result<[Profile], Error>) -> Void) {
        guard let url = URL(string: "https://api.web3.bio/profile/\(address)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let profiles = try JSONDecoder().decode([Profile].self, from: data)
                completion(.success(profiles))
            } catch {
                completion(.failure(APIError.decodingFailed))
            }
        }
        
        task.resume()
    }
    
    func fetchNFTs(address: String, completion: @escaping (Result<[Collection], Error>) -> Void) {
        
        guard let url = URL(string: "https://api.web3.bio/profile/\(address)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let profiles = try JSONDecoder().decode([Collection].self, from: data)
                completion(.success(profiles))
            } catch {
                completion(.failure(APIError.decodingFailed))
            }
        }
        
        task.resume()
    }
    
}

// Usage:
// let APIManager = APIManager()
//
// APIManager.fetchProfile(profileName: "exampleProfile") { result in
//    switch result {
//    case .success(let profile):
//        print("Profile name: \(profile.name)")
//        // Access other properties of the profile as needed.
//    case .failure(let error):
//        print("Error: \(error.localizedDescription)")
//    }
//}
