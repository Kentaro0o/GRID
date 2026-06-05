import SwiftUI

enum GRIDLayout {
    /// 各タブのヘッダー上部パディング
    static let headerTopPadding: CGFloat    = 32
    /// 各タブのヘッダー下部パディング
    static let headerBottomPadding: CGFloat = 20
    /// ボトムナビバーと被らないためのコンテンツ下部余白
    /// タブバー高さ（約80）＋ホームインジケーター（約34）を考慮
    static let tabBarBottomPadding: CGFloat = 124
    /// タブバー自体のホームインジケーター上余白（iPhone X以降は34pt）
    static let tabBarHomePadding: CGFloat   = 34
}
