import SwiftUI

extension UINavigationBarAppearance {
    static var custom: UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backgroundColor = UIColor.black
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        return appearance
    }
}
