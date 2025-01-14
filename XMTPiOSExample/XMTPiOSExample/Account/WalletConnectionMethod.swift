//
//  WalletConnectionMethod.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import CoreImage.CIFilterBuiltins
import UIKit
import WalletConnectUtils
//import WalletConnectSwift

protocol WalletConnectionMethod {
	var type: WalletConnectionMethodType { get }
}

/// Describes WalletConnect flows.
public enum WalletConnectionMethodType {
	case redirect(URL), qrCode(UIImage), manual(String)
}

struct WalletRedirectConnectionMethod: WalletConnectionMethod {
	var redirectURI: WalletConnectURI
	var type: WalletConnectionMethodType {
		// swiftlint:disable force_unwrapping
        .redirect(URL(string: redirectURI.absoluteString)!)
		// swiftlint:enable force_unwrapping
	}
}

struct WalletQRCodeConnectionMethod: WalletConnectionMethod {
	var redirectURI: WalletConnectURI
	var type: WalletConnectionMethodType {
        let data = Data(redirectURI.absoluteString.utf8)
		let context = CIContext()
		let filter = CIFilter.qrCodeGenerator()
		filter.setValue(data, forKey: "inputMessage")

		// swiftlint:disable force_unwrapping
		let outputImage = filter.outputImage!
		let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
		let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent)!
		// swiftlint:enable force_unwrapping

		let image = UIImage(cgImage: cgImage)
        
        print("YOOO URL", redirectURI.absoluteString)

		return .qrCode(image)
	}
}

struct WalletManualConnectionMethod: WalletConnectionMethod {
	var redirectURI: String
	var type: WalletConnectionMethodType {
		.manual(redirectURI)
	}
}
