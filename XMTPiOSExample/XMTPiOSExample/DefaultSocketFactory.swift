import Foundation
import Starscream
import WalletConnectRelay

extension WebSocket: WebSocketConnecting { }

struct DefaultSocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("relay.walletconnect.com", forHTTPHeaderField: "Origin")
        return WebSocket(request: urlRequest)
    }
}
