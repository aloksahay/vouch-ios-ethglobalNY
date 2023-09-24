//
//  QRCodeSheetView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 11/22/22.
//

import SwiftUI

struct QRCodeSheetView: View {
	var image: UIImage?

    var body: some View {
        ZStack {
            Color(hex: "F4DAC7")

            VStack {
                Text("Scan the below QR code to get started and to connect your wallet with our network")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.top, 20)
                
                Image(uiImage: UIImage(named: "qrimage")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(20)
            }
        }
    }
}
