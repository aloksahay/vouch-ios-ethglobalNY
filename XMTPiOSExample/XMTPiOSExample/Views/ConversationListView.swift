import SwiftUI
import XMTP

struct ConversationListView: View {
	var client: XMTP.Client

	@EnvironmentObject var coordinator: EnvironmentCoordinator
	@State private var conversations: [ConversationInfo] = []
	@State private var isShowingNewConversation = false

	var body: some View {
        // Set the background color here
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea() // Set the background color of the view
                List {
                    ForEach(conversations, id: \.conversation.peerAddress) { conversationInfo in
                        NavigationLink(value: conversationInfo.conversation) {
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
                                        Text(shortenStringToEllipsis(conversationInfo.conversation.peerAddress, characterCount: 10))
                                            .font(.headline)
                                            .foregroundColor(Color.black)
                                        
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
                                    
                                    if conversationInfo.latestMessage.isEmpty == false {
                                        Text(truncateStringTo40Characters(conversationInfo.latestMessage)) // Display the latest message
                                            .font(.subheadline)
                                            .foregroundColor(Color.black)
                                    
                                    } else {
                                        Text("No messages yet")
                                            .font(.subheadline)
                                            .foregroundColor(Color.black)
                                    }
                                    
                                }
                            }
                            .background(Color.white) // Make the cell background clear
                        }
                        .listRowBackground(Color.white) // Make the row background clear
                    }
                }
                .listStyle(PlainListStyle()) // Set the list style to PlainListStyle
            }
        }
		.navigationDestination(for: Conversation.self) { conversation in
			ConversationDetailView(client: client, conversation: conversation)
		}
        .navigationBarTitle("Chats", displayMode: .inline)
                   .background(NavigationConfigurator { nc in
                       nc.navigationBar.barTintColor = .blue
                       nc.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
                   })
        .onAppear {
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        }
        .tint(Color.white)
		.refreshable {
			await loadConversations()
		}
		.task {
			await loadConversations()
		}
		.task {
			do {
                for try await conversation in await client.conversations.stream() {
                        
                    let latestMessage = await fetchLatestMessage(for: conversation)
                    
                    if let message = latestMessage {
                        
                        var bodyText: String {
                            // swiftlint:disable force_try
                            return try! message.content()
                            // swiftlint:enable force_try
                        }
                        
                        let content = bodyText
                        let conversationInfo = ConversationInfo(conversation: conversation, latestMessage: content)
                        conversations.insert(conversationInfo, at: 0)
                    } else {
                        let conversationInfo = ConversationInfo(conversation: conversation, latestMessage: "")
                        conversations.insert(conversationInfo, at: 0)
                    }
        
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
                .tint(Color.white)
			}
		}
		.sheet(isPresented: $isShowingNewConversation) {
			NewConversationView(client: client) { conversation in
                                
                let conversationInfo = ConversationInfo(conversation: conversation, latestMessage: "")
                conversations.insert(conversationInfo, at: 0)
                
				coordinator.path.append(conversation)
			}
		}
	}

	func loadConversations() async {
		do {
			let conversations = try await client.conversations.list()
            
            var conversationInfoArray: [ConversationInfo] = []
            
            for conversation in conversations {
                // Fetch the latest message for each conversation
                let latestMessage = await fetchLatestMessage(for: conversation)
                
                
                
                if let message = latestMessage {
                    
                    var bodyText: String {
                        // swiftlint:disable force_try
                        return try! message.content()
                        // swiftlint:enable force_try
                    }
                    
                    let content = bodyText
                    let conversationInfo = ConversationInfo(conversation: conversation, latestMessage: content)
                    conversationInfoArray.append(conversationInfo)
                } else {
                    let conversationInfo = ConversationInfo(conversation: conversation, latestMessage: "")
                    conversationInfoArray.append(conversationInfo)
                }
            
                
            }
            
			await MainActor.run {
				self.conversations = conversationInfoArray
			}

			await add(conversations: conversations)
		} catch {
			print("Error loading conversations: \(error)")
		}
	}
    
    func fetchLatestMessage(for conversation: XMTP.Conversation) async -> XMTP.DecodedMessage? {
        do {
            // Fetch the latest message for the conversation
            let messages = try await conversation.messages()
            return messages.first
        } catch {
            print("Error fetching latest message for conversation: \(error)")
            return nil
        }
    }
    
    func truncateStringTo40Characters(_ input: String) -> String {
        if input.count <= 40 {
            return input
        } else {
            let truncated = input.prefix(40)
            return String(truncated)
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
        if input == "0xF8cd371Ae43e1A6a9bafBB4FD48707607D24aE43" {
            return "nickmolnar.eth"
        }
        
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

struct NavigationConfigurator: UIViewControllerRepresentable {
    var configure: (UINavigationController) -> Void = { _ in }

    func makeUIViewController(context: UIViewControllerRepresentableContext<NavigationConfigurator>) -> UIViewController {
        UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<NavigationConfigurator>) {
        if let nc = uiViewController.navigationController {
            self.configure(nc)
        }
    }

}

struct ConversationInfo {
    var conversation: XMTP.Conversation
    var latestMessage: String
}
