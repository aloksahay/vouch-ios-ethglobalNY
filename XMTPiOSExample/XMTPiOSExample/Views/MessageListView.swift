import SwiftUI
import XMTP

struct MessageListView: View {
	var myAddress: String
	var messages: [DecodedMessage]

	var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    ForEach(Array(messages.sorted(by: { $0.sent < $1.sent }).enumerated()), id: \.0) { i, message in
                        MessageCellView(myAddress: myAddress, message: message)
                            .transition(.scale)
                            .id(i)
                    }
                    Spacer()
                        .onChange(of: messages.count) { _ in
                            withAnimation {
                                proxy.scrollTo(messages.count - 1, anchor: .bottom)
                            }
                        }
                }
            }
        }
        .padding(.horizontal)
	}
}

struct MessageListView_Previews: PreviewProvider {
	static var previews: some View {
		PreviewClientProvider { client in
			MessageListView(
				myAddress: "0x00", messages: [
					XMTP.DecodedMessage.preview(client: client, topic: "foo", body: "Hello", senderAddress: "0x00", sent: Date().addingTimeInterval(-10)),
					XMTP.DecodedMessage.preview(client: client, topic: "foo",body: "Oh hi", senderAddress: "0x01", sent: Date().addingTimeInterval(-9)),
					XMTP.DecodedMessage.preview(client: client, topic: "foo",body: "Sup", senderAddress: "0x01", sent: Date().addingTimeInterval(-8)),
					XMTP.DecodedMessage.preview(client: client, topic: "foo",body: "Nice to see you", senderAddress: "0x00", sent: Date().addingTimeInterval(-7)),
					XMTP.DecodedMessage.preview(client: client, topic: "foo",body: "What if it's a longer message I mean really really long like should it wrap?", senderAddress: "0x01", sent: Date().addingTimeInterval(-6)),
					XMTP.DecodedMessage.preview(client: client, topic: "foo",body: "🧐", senderAddress: "0x00", sent: Date().addingTimeInterval(-5)),
				]
			)
		}
	}
}
