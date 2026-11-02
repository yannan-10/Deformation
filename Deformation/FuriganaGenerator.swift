//
//  FuriganaGenerator.swift
//  Deformation
//
//  Created by BAIYANNAN on 2026/11/02.
//

import Foundation

/// 一个显示单位：文字 + 读音（不需要注音时 reading 为 nil）
struct FuriganaSegment: Identifiable {
    let id = UUID()
    let text: String
    let reading: String?
}

/// 把日语句子切成单词，并给含有汉字的单词生成平假名读音
enum FuriganaGenerator {

    static func generate(_ text: String) -> [FuriganaSegment] {
        var segments: [FuriganaSegment] = []
        let nsText = text as NSString
        let fullRange = CFRange(location: 0, length: nsText.length)

        // 苹果系统自带的分词器，指定日语
        let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            text as CFString,
            fullRange,
            kCFStringTokenizerUnitWordBoundary,
            Locale(identifier: "ja") as CFLocale
        )

        var lastEnd = 0   // 上一个单词结束的位置

        // 一个一个地取出单词
        while !CFStringTokenizerAdvanceToNextToken(tokenizer).isEmpty {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)

            // 分词器跳过的部分（标点、空格等）原样保留
            if range.location > lastEnd {
                let gap = nsText.substring(with: NSRange(location: lastEnd, length: range.location - lastEnd))
                segments.append(FuriganaSegment(text: gap, reading: nil))
            }

            let word = nsText.substring(with: NSRange(location: range.location, length: range.length))
            lastEnd = range.location + range.length

            // 没有汉字的词（平假名、片假名、数字）不需要注音
            guard containsKanji(word),
                  // 分词器能给出罗马字读音，例如 趣味 → "shumi"
                  let latin = CFStringTokenizerCopyCurrentTokenAttribute(
                      tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? String,
                  // 罗马字 → 平假名，例如 "shumi" → "しゅみ"
                  let hiragana = latin.applyingTransform(.latinToHiragana, reverse: false)
            else {
                segments.append(FuriganaSegment(text: word, reading: nil))
                continue
            }

            segments.append(contentsOf: splitOkurigana(word: word, reading: hiragana))
        }

        // 最后剩下的部分
        if lastEnd < nsText.length {
            segments.append(FuriganaSegment(text: nsText.substring(from: lastEnd), reading: nil))
        }
        return segments
    }

    /// 把送假名分出来，让读音只标在汉字上
    /// 例：好き（すき）→ 好[す] + き
    ///     お茶（おちゃ）→ お + 茶[ちゃ]
    private static func splitOkurigana(word: String, reading: String) -> [FuriganaSegment] {
        var chars = Array(word)
        var readingChars = Array(reading)
        var prefix = ""
        var suffix = ""

        // 去掉开头和读音相同的假名
        while let c = chars.first, let r = readingChars.first,
              !isKanji(c), toHiragana(c) == String(r) {
            prefix.append(c)
            chars.removeFirst()
            readingChars.removeFirst()
        }

        // 去掉结尾和读音相同的假名
        while let c = chars.last, let r = readingChars.last,
              !isKanji(c), toHiragana(c) == String(r) {
            suffix.insert(c, at: suffix.startIndex)
            chars.removeLast()
            readingChars.removeLast()
        }

        var result: [FuriganaSegment] = []
        if !prefix.isEmpty {
            result.append(FuriganaSegment(text: prefix, reading: nil))
        }
        if !chars.isEmpty {
            result.append(FuriganaSegment(text: String(chars),
                                          reading: readingChars.isEmpty ? nil : String(readingChars)))
        }
        if !suffix.isEmpty {
            result.append(FuriganaSegment(text: suffix, reading: nil))
        }
        return result
    }

    // MARK: - 小工具

    /// 判断一个字是不是汉字（包括「々」）
    static func isKanji(_ c: Character) -> Bool {
        c.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(scalar.value) ||   // 常用汉字
            (0x3400...0x4DBF).contains(scalar.value) ||   // 扩展汉字
            scalar.value == 0x3005                        // 々
        }
    }

    static func containsKanji(_ text: String) -> Bool {
        text.contains(where: isKanji)
    }

    /// 片假名转平假名（用于比较），例：キ → き
    private static func toHiragana(_ c: Character) -> String {
        String(c).applyingTransform(.hiraganaToKatakana, reverse: true) ?? String(c)
    }
}
