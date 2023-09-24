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
