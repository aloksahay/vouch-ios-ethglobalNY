import Foundation

public extension Data {
    init?(hex: String, id: Int = -1) {
        if let byteArray = try? CustomHexUtil.byteArray(fromHex: hex.web3.noHexPrefix) {
            self.init(bytes: byteArray, count: byteArray.count)
        } else {
            return nil
        }
    }
}
