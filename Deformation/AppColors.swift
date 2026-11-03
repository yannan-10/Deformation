//
//  AppColors.swift
//  Deformation
//
//  Created by BAIYANNAN on 2026/11/03.
//
import SwiftUI

/// App 的配色，集中在这里管理
extension Color {
    /// 背景：米白色（和纸）
    static let appBackground = Color(red: 0.97, green: 0.95, blue: 0.91)
    /// 主色：朱红色
    static let appAccent = Color(red: 0.82, green: 0.30, blue: 0.25)
    /// 主色的浅色版（用于功能按钮的底色）
    static let appAccentLight = Color(red: 0.82, green: 0.30, blue: 0.25).opacity(0.12)
}
