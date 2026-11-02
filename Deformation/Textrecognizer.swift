//
//  Textrecognizer.swift
//  Deformation
//
//  Created by BAIYANNAN on 2026/10/31.
//

import UIKit
import Vision

/// 负责从图片中识别日语文字（使用苹果的 Vision 框架，在手机上离线完成）
enum TextRecognizer {

    enum RecognizerError: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            "图片格式无法读取"
        }
    }

    /// 传入一张图片，返回识别出的文字（多行用换行连接）
    static func recognize(_ image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw RecognizerError.invalidImage
        }
        // 照片可能是横着拍的，需要告诉 Vision 图片的方向
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        // 识别比较耗时，放到后台执行，避免界面卡住
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate        // 精确模式（比快速模式慢，但准）
            request.recognitionLanguages = ["ja-JP"]    // 识别日语
            request.usesLanguageCorrection = true       // 自动纠正识别错误

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
            try handler.perform([request])

            // 每个结果是一行文字，取可信度最高的候选
            let lines = (request.results ?? []).compactMap {
                $0.topCandidates(1).first?.string
            }
            return lines.joined()
        }.value
    }
}

/// 把 UIKit 的图片方向转换成 Vision 使用的方向
extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
