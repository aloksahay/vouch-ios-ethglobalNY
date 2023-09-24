import SwiftUI
import XMTP

struct ConversationDetailView: View {
	var client: XMTP.Client
	var conversation: XMTP.Conversation

	@State private var messages: [DecodedMessage] = []

	var body: some View {
        VStack {
            Image(uiImage: UIImage(named: "sample_avatar")!)
                .resizable()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .foregroundColor(.white)
            
            MessageListView(myAddress: client.address, messages: messages)
                .refreshable {
                    await loadMessages()
                }
                .task {
                    await loadMessages()
                }
                .task {
                    do {
                        for try await message in conversation.streamMessages() {
                            await MainActor.run {
                                messages.append(message)
                            }
                        }
                    } catch {
                        print("Error in message stream: \(error)")
                    }
                }
            
            MessageComposerView { text in
                do {
                    try await conversation.send(text: text)
                } catch {
                    print("Error sending message: \(error)")
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(shortenStringToEllipsis(conversation.peerAddress, characterCount: 10))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Add your icons here
                Button(action: {
                    // Add your action for the first icon here
                }) {
                    Image(uiImage: UIImage(named: "ens_icon")!)
                        .resizable()
                        .frame(width: 20, height: 20)
                }.padding(.trailing, -12)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                // Add your second icon here
                Button(action: {
                    // Add your action for the second icon here
                }) {
                    Image(uiImage: UIImage(named: "ape_icon")!)
                        .resizable()
                        .frame(width: 20, height: 20)
                }.padding(.trailing, -12)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                // Add your second icon here
                Button(action: {
                    // Add your action for the second icon here
                }) {
                    Image(uiImage: UIImage(named: "farcaster_icon")!)
                        .resizable()
                        .frame(width: 20, height: 20)
                }.padding(.trailing, -8)
            }
            
        }
	}

	func loadMessages() async {
		do {
			let messages = try await conversation.messages()
			await MainActor.run {
				self.messages = messages
			}
		} catch {
			print("Error loading messages for \(conversation.peerAddress)")
		}
	}
    
    func shortenStringToEllipsis(_ input: String, characterCount: Int) -> String {
        guard input.count > (characterCount + 3) else {
            return input
        }

        let prefixLength = (characterCount - 1) / 2
        let suffixLength = characterCount - prefixLength - 3

        let prefix = String(input.prefix(prefixLength))
        let suffix = String(input.suffix(suffixLength))

        return "\(prefix)...\(suffix)"
    }


}
