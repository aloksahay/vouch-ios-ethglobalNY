//
//  ContentView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 11/22/22.
//

import SwiftUI
import Starscream
import XMTP

struct ContentView: View {
	enum Status {
		case unknown, connecting, connected(Client), error(String)
	}

	@StateObject var accountManager = AccountManager()

	@State private var status: Status = .unknown

	@State private var isShowingQRCode = false
	@State private var qrCodeImage: UIImage?

	@State private var client: Client?

	var body: some View {
        ZStack {
            Color(.black).ignoresSafeArea()
            VStack {
                switch status {
                case .unknown:
                    Spacer()
                    Image(uiImage: UIImage(named: "Logo")!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding(80)
                    Text("This is Vouch")
                        .font(.title)
                        .foregroundColor(.white)
                        .fontWeight(Font.Weight.bold)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    Text("Protect yourself from the dark side of social.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))
                    Button(action: connectWallet) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "872d86")) //theme color
                            .cornerRadius(30)
                    }.padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))
                    Button("Let me in", action: generateWallet)
                        .foregroundColor(Color(hex: "872d86"))
                        .font(.title2)
                        .fontWeight(Font.Weight.semibold)
                        .padding(EdgeInsets.init(top: 20, leading: 0, bottom: 0, trailing: 0))
                case .connecting:
                    ProgressView("Connecting…")
                        .progressViewStyle(DefaultProgressViewStyle())
                        .accentColor(Color(.white))
                case let .connected(client):
                    LoggedInView(client: client)
                case let .error(error):
                    Text("Error: \(error)").foregroundColor(.red)
                }
            }
            .task {
                UIApplication.shared.registerForRemoteNotifications()
                
                do {
                    _ = try await XMTPPush.shared.request()
                } catch {
                    print("Error requesting push access: \(error)")
                }
            }
            .sheet(isPresented: $isShowingQRCode) {
                QRCodeSheetView(image: qrCodeImage)
            }
        }
	}
    
    func connectWallet()  {
		status = .connecting
        
        Task {
            do {
                switch try await accountManager.account.preferredConnectionMethod() {
                case let .qrCode(image):
                    qrCodeImage = image
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self.isShowingQRCode = true
                    }
                case let .redirect(url):
                    await UIApplication.shared.open(url)
                case let .manual(url):
                    print("Open \(url) in mobile safari")
                }

                Task {
                    do {
                        try await accountManager.account.connect()

                        for _ in 0 ... 90 {
                            if accountManager.account.isConnected {
                                
                                let wallet = try PrivateKey.generate()
                                
                                let client = try await Client.create(account: wallet, options: .init(api: .init(env: .production, isSecure: true, appVersion: "XMTPTest/v1.0.0")))
                                
                                // let client = try await Client.create(account: accountManager.account, options: .init(api: .init(env: .dev)))

                                let keysData = try client.privateKeyBundle.serializedData()
                                Persistence().saveKeys(keysData)

                                self.status = .connected(client)
                                self.isShowingQRCode = false
                                return
                            }

                            try await Task.sleep(for: .seconds(1))
                        }

                        self.status = .error("Timed out waiting to connect (90 seconds)")
                    } catch {
                        await MainActor.run {
                            self.status = .error("Error connecting: \(error)")
                            self.isShowingQRCode = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.status = .error("Error connecting: \(error)")
                    self.isShowingQRCode = false
                }
            }
        }
	}

	func generateWallet() {
        
        let wallet = AccountManager.getKey()
        
		Task {
			do {
//				let wallet = try PrivateKey.generate()
                
                let keyData = try AccountManager.generate(privateKeyString: wallet!)
                let account = try PrivateKey(keyData)
                
				let client = try await Client.create(account: account, options: .init(api: .init(env: .production, isSecure: true, appVersion: "XMTPTest/v1.0.0")))

				let keysData = try client.privateKeyBundle.serializedData()
				Persistence().saveKeys(keysData)
                
                print(account.address)

				await MainActor.run {
					self.status = .connected(client)
				}
			} catch {
				await MainActor.run {
					self.status = .error("Error generating wallet: \(error)")
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
