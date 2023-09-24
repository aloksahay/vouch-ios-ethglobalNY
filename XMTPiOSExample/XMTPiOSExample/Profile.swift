//
//  Profile.swift
//  XMTPiOSExample
//
//  Created by Alok Sahay on 23.09.2023.
//

import Foundation

struct Profile: Codable {
    let address: String
    let identity: String
    let platform: String
    let displayName: String
    let avatar: String
    let email: String?
    let description: String
    let location: String?
    let header: String?
    let links: Links
    let addresses: Addresses
}

struct Links: Codable {
    let website: Link?
    let twitter: Link?
    let github: Link?
    let discord: Link?
    let reddit: Link?
    let telegram: Link?
    let lenster: Link?
}

struct Link: Codable {
    let link: String
    let handle: String
}

struct Addresses: Codable {
    let eth: String
}
