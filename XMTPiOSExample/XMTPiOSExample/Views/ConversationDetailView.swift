import SwiftUI
import XMTP

struct ConversationDetailView: View {
	var client: XMTP.Client
	var conversation: XMTP.Conversation

	@State private var messages: [DecodedMessage] = []

	var body: some View {
		VStack {
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
        .background(Color(hex: "F4DAC7").ignoresSafeArea())
		.navigationTitle(shortenStringToEllipsis(conversation.peerAddress, characterCount: 10))
		.navigationBarTitleDisplayMode(.inline)
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
