//
//  Savednote.swift
//  Deformation
//
//  Created by BAIYANNAN on 2026/11/02.
//
import Foundation
import SwiftData

/// 一条收藏：只保存识别出的文字和保存时间（不保存照片）
/// @Model 表示这是 SwiftData 的数据模型，会自动保存到手机里，关掉 app 也不会丢
@Model
final class SavedNote {
    var text: String
    var createdAt: Date

    init(text: String, createdAt: Date = .now) {
        self.text = text
        self.createdAt = createdAt
    }

    /// 列表里显示的标题：取开头的一部分文字
    var title: String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(18))
    }

    /// 标题下面的预览文字
    var preview: String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).dropFirst(18).prefix(50))
    }
}
