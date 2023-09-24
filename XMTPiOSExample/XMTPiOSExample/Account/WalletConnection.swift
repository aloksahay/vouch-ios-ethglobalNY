//
//  WalletConnection.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation
import UIKit
import web3
import XMTP
import UIKit
import Auth
import WalletConnectRelay
import WalletConnectNetworking
import WalletConnectModal
import WalletConnectSign
import Combine

extension WCURL {
	var asURL: URL {
		// swiftlint:disable force_unwrapping
		URL(string: "wc://wc?uri=\(absoluteString)")!
		// swiftlint:enable force_unwrapping
	}
}

enum WalletConnectionError: String, Error {
	case walletConnectURL
	case noSession
	case noAddress
	case invalidMessage
	case noSignature
}

protocol WalletConnection {
	var isConnected: Bool { get }
	var walletAddress: String? { get }
	func preferredConnectionMethod() async throws -> WalletConnectionMethodType
	func connect() async throws
	func sign(_ data: Data) async throws -> Data
}

class WCWalletConnection: WalletConnection {
	@Published public var isConnected = false
    
//    var walletConnectClient: WalletConnectSwift.Client!
//    var session: WalletConnectSwift.Session? {

    var session: Session?
    var walletURI: WalletConnectURI?
    var signResponse: String?
    private var publishers = Set<AnyCancellable>()
//	var walletConnectClient: WalletConnectModalClient!
//	var session: WCSession? {
//		didSet {
//			DispatchQueue.main.async {
//				self.isConnected = self.session != nil
//			}
//		}
//	}

    init() {
            
//        let peerMeta = Session.ClientMeta(
//              name: "xmtp-ios",
//              description: "XMTP",
//              icons: [],
//              // swiftlint:disable force_unwrapping
//              url: URL(string: "https://safe.gnosis.io")!
//              // swiftlint:enable force_unwrapping
//        )
//        let dAppInfo = WalletConnectSwift.Session.DAppInfo(peerId: UUID().uuidString, peerMeta: peerMeta)
//
//        walletConnectClient = WalletConnectSwift.Client(delegate: self, dAppInfo: dAppInfo)
//
        
//        Networking.configure(projectId: "dda791cb05cfaa66cefbe9853f970659", socketFactory: DefaultSocketFactory())
//        Auth.configure(crypto: DefaultCryptoProvider())
//
//        let metadata = AppMetadata(
//            name: "xmtp-ios",
//            description: "XMTP",
//            url: "https://safe.gnosis.io",
//            icons: []
//        )
//
//        WalletConnectModal.configure(
//            projectId: "dda791cb05cfaa66cefbe9853f970659",
//            metadata: metadata,
//            accentColor: .green
//        )
                
	}

    @MainActor func preferredConnectionMethod() async throws -> WalletConnectionMethodType {
                
        Networking.configure(projectId: "dda791cb05cfaa66cefbe9853f970659", socketFactory: DefaultSocketFactory(), socketConnectionType: .manual)
        try Networking.instance.connect()
        
        Auth.configure(crypto: DefaultCryptoProvider())
        
        let metadata = AppMetadata(
            name: "vouch-ios",
            description: "Vouch iOS",
            url: "https://safe.gnosis.io",
            icons: []
        )
        
        
        Pair.configure(metadata: metadata)
        
        walletURI = try await Pair.instance.create()
        

//        guard let url = walletURI else {
//			throw WalletConnectionError.walletConnectURL
//		}
        
        

//		if UIApplication.shared.canOpenURL(uri) {
//			return WalletRedirectConnectionMethod(redirectURI: uri).type
//		}
        
        
        return WalletQRCodeConnectionMethod(redirectURI: walletURI!).type
	}
    
	lazy var walletConnectURL: WCURL? = {
		do {
			let keybytes = try secureRandomBytes(count: 32)
            
			return WCURL(
				topic: UUID().uuidString,
				// swiftlint:disable force_unwrapping
                version: "2",
                bridgeURL: URL(string: "wss://relay.walletconnect.com")!,
				// swiftlint:enable force_unwrapping
				key: keybytes.reduce("") { $0 + String(format: "%02x", $1) }
			)
            
		} catch {
			return nil
		}
	}()

	func secureRandomBytes(count: Int) throws -> Data {
		var bytes = [UInt8](repeating: 0, count: count)

		// Fill bytes with secure random data
		let status = SecRandomCopyBytes(
			kSecRandomDefault,
			count,
			&bytes
		)

		// A status of errSecSuccess indicates success
		if status == errSecSuccess {
			return Data(bytes)
		} else {
			fatalError("could not generate random bytes")
		}
	}

	func connect() async throws {
        
        
        let uri = walletURI!
        
        let methods: Set<String> = ["eth_sendTransaction", "personal_sign", "eth_signTypedData"]
        let blockchains: Set<Blockchain> = [Blockchain("eip155:1")!, Blockchain("eip155:137")!]
        let namespaces: [String: ProposalNamespace] = ["eip155": ProposalNamespace(chains: blockchains, methods: methods, events: [])]
        
        try await Sign.instance.connect(requiredNamespaces: namespaces, topic: uri.topic)
        
        Sign.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { sessions in
                let method = "personal_sign"
                let walletAddress = sessions.accounts.first?.address
                let requestParams = AnyCodable(["0x4d7920656d61696c206973206a6f686e40646f652e636f6d202d2031363533333933373535313531", walletAddress])
                let request = Request(topic: sessions.topic, method: method, params: requestParams, chainId: Blockchain("eip155:1")!)
                Task {
                    await self.sendRequest(request: request)
                }
            }.store(in: &publishers)

        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                print("delete publisher")
            }.store(in: &publishers)

        Sign.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] response in
                print("got response", response.chainId)
                
                do {
                    let resultJSON = try response.result.value.asJSONEncodedString()
                    signResponse = resultJSON.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "\\", with: "")
                } catch {
                    print("failed conversion")
                }
                
                if let session = Sign.instance.getSessions().first {
                    print("got session")
                    DispatchQueue.main.async {
                        self.session = session
                        self.isConnected = session != nil
                    }
                    
                } else {
                    print("no session")
                }
            }.store(in: &publishers)
        
//        try Networking.instance.connect()
//        Pair.configure(metadata: metadata)
                
//        Sign.instance.sessionDeletePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [unowned self] _ in
//                print("delete publisher")
//            }.store(in: &publishers)
//
//        Sign.instance.sessionResponsePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [unowned self] response in
//                print("got response", response.chainId)
//            }.store(in: &publishers)
        
//        if let session = Sign.instance.getSessions().first {
//            print("got session")
//        } else {
//            print("no session")
//        }
	}
    
    func sendRequest(request: Request) async {
        do {
            try await Sign.instance.request(params: request)
        } catch {
            print("Uh oh")
        }
        
    }

	func sign(_ data: Data) async throws -> Data {
        
        // sign it
        
		guard session != nil else {
			throw WalletConnectionError.noSession
		}

		guard let walletAddress = walletAddress else {
			throw WalletConnectionError.noAddress
		}

//		guard let url = walletConnectURL else {
//			throw WalletConnectionError.walletConnectURL
//		}

		guard let message = String(data: data, encoding: .utf8) else {
			throw WalletConnectionError.invalidMessage
		}

		return try await withCheckedThrowingContinuation { continuation in
			do {
//				try walletConnectClient.personal_sign(url: url, message: message, account: walletAddress) { response in
                if (signResponse ?? "").isEmpty {
                    continuation.resume(throwing: WalletConnectionError.noSignature)
                    return
                }

                do {
                    var resultString = signResponse!

                    // Strip leading 0x that we get back from `personal_sign`
                    if resultString.hasPrefix("0x"), resultString.count == 132 {
                        resultString = String(resultString.dropFirst(2))
                    }

                    guard let resultDataBytes = resultString.web3.bytesFromHex else {
                        continuation.resume(throwing: WalletConnectionError.noSignature)
                        return
                    }

                    var resultData = Data(resultDataBytes)

                    // Ensure we have a valid recovery byte
                    resultData[resultData.count - 1] = 1 - resultData[resultData.count - 1] % 2

                    continuation.resume(returning: resultData)
                } catch {
                    continuation.resume(throwing: WalletConnectionError.noSignature)
                }
//				}
			} catch {
				continuation.resume(throwing: WalletConnectionError.noSignature)
			}
		}
	}

	var walletAddress: String? {
        if let address = session?.namespaces.first?.value.accounts.first?.absoluteString {
            return EthereumAddress(address).toChecksumAddress()
		}

		return nil
	}

//	func client(_: WalletConnectSwift.Client, didConnect _: WalletConnectSwift.WCURL) {}
//
//	func client(_: WalletConnectSwift.Client, didFailToConnect _: WalletConnectSwift.WCURL) {}
//
//	func client(_: WalletConnectSwift.Client, didConnect session: Session) {
//		// TODO: Cache session
//		self.session = session
//	}
//
//	func client(_: WalletConnectSwift.Client, didUpdate session: Session) {
//		self.session = session
//	}
//
//	func client(_: WalletConnectSwift.Client, didDisconnect _: Session) {
//		session = nil
//	}
}
