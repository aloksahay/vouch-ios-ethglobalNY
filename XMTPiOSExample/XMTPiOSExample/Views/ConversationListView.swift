//
//  ConversationListView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import SwiftUI
import XMTP

struct ConversationListView: View {
	var client: XMTP.Client

	@EnvironmentObject var coordinator: EnvironmentCoordinator
	@State private var conversations: [XMTP.Conversation] = []
	@State private var isShowingNewConversation = false

	var body: some View {
        // Set the background color here
        NavigationView {
            ZStack {
                Color(hex: "F4DAC7").ignoresSafeArea() // Set the background color of the view

                List {
                    ForEach(conversations, id: \.peerAddress) { conversation in
                        NavigationLink(value: conversation) {
                            HStack {
                                // Circular Image View
                                Image(uiImage: UIImage(named: "sample_avatar")!)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .foregroundColor(.white)

                                // Peer Address and Last Message
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(shortenStringToEllipsis(conversation.peerAddress, characterCount: 10))
                                            .font(.headline)
                                        
                                        // if conversation.isActiveOnEns {
                                        Image(uiImage: UIImage(named: "ens_icon")!)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                        //}
                                        //if conversation.isActiveOnApe {
                                        Image(uiImage: UIImage(named: "ape_icon")!)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                        //}
                                        //if conversation.isActiveOnFarcaster {
                                        Image(uiImage: UIImage(named: "farcaster_icon")!)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                        //}
                                    }
                                    
                                    Text("Hi there, fancy meeting at the coffee place? ")
                                        .font(.subheadline)
                                }
                            }
                            .background(Color.clear) // Make the cell background clear
                        }
                        .listRowBackground(Color.clear) // Make the row background clear
                    }
                }
                .listStyle(PlainListStyle()) // Set the list style to PlainListStyle
            }
        }
		.navigationDestination(for: Conversation.self) { conversation in
			ConversationDetailView(client: client, conversation: conversation)
		}
		.navigationTitle("Chats")
		.refreshable {
			await loadConversations()
		}
		.task {
			await loadConversations()
		}
		.task {
			do {
				for try await conversation in await client.conversations.stream() {
					conversations.insert(conversation, at: 0)

					await add(conversations: [conversation])
				}

			} catch {
				print("Error streaming conversations: \(error)")
			}
		}
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button(action: {
					self.isShowingNewConversation = true
				}) {
					Label("New Conversation", systemImage: "plus")
				}
                .tint(Color(hex: "F68633"))
			}
		}
		.sheet(isPresented: $isShowingNewConversation) {
			NewConversationView(client: client) { conversation in
				conversations.insert(conversation, at: 0)
				coordinator.path.append(conversation)
			}
		}
	}

	func loadConversations() async {
		do {
			let conversations = try await client.conversations.list()

			await MainActor.run {
				self.conversations = conversations
			}

			await add(conversations: conversations)
		} catch {
			print("Error loading conversations: \(error)")
		}
	}

	func add(conversations: [Conversation]) async {
		// Ensure we're subscribed to push notifications on these conversations
		do {
			try await XMTPPush.shared.subscribe(topics: conversations.map(\.topic))
		} catch {
			print("Error subscribing: \(error)")
		}

		for conversation in conversations {
			do {
				try Persistence().save(conversation: conversation)
			} catch {
				print("Error saving \(conversation.topic): \(error)")
			}
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

struct ConversationListView_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			PreviewClientProvider { client in
				NavigationView {
					ConversationListView(client: client)
				}
			}
		}
	}
}
