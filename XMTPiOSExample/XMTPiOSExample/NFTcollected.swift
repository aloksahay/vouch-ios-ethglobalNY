//
//  NFT.swift
//  XMTPiOSExample
//
//  Created by Alok Sahay on 23.09.2023.
//

import Foundation

// Define the Swift structures to match the JSON data

struct CollectionData: Decodable {
    let data: CollectionResponse
}

struct CollectionResponse: Decodable {
    let collections: [Collection]
}

struct Collection: Decodable {
    let name: String
    let contract_address: String
    let total: Int
    let image_uri: String  // New field for image URI
    
    // CodingKeys enum to handle the snake_case to camelCase conversion
    private enum CodingKeys: String, CodingKey {
        case name
        case contract_address
        case total
        case image_uri = "image_uri"
    }
}

// Convert JSON data to Data
//if let jsonData = json.data(using: .utf8) {
//    do {
//        // Decode JSON data into CollectionData
//        let collectionData = try JSONDecoder().decode(CollectionData.self, from: jsonData)
//
//        // Access the collections
//        let collections = collectionData.data.collections
//
//        for collection in collections {
//            print("Collection Name: \(collection.name)")
//            print("Contract Address: \(collection.contract_address)")
//            print("Number of Tokens: \(collection.total)")
//            print("Image URI: \(collection.image_uri)") // Print the image URI
//            print("\n")
//        }
//    } catch {
//        print("Error decoding JSON: \(error)")
//    }
//}

