//
//  FuriganaText.swift
//  Deformation
//
//  Created by BAIYANNAN on 2026/11/02.
//

import SwiftUI

/// 显示带注音的日语文章（读音显示在汉字上方）
struct FuriganaText: View {
    let segments: [FuriganaSegment]
    var fontSize: CGFloat = 22

    /// 没有读音的部分拆成单个字，这样换行可以发生在任何位置
    private var units: [FuriganaSegment] {
        segments.flatMap { segment -> [FuriganaSegment] in
            if segment.reading == nil {
                return segment.text
                    .filter { $0 != "\n" }
                    .map { FuriganaSegment(text: String($0), reading: nil) }
            }
            return [segment]
        }
    }

    var body: some View {
        FlowLayout(lineSpacing: 6) {
            ForEach(units) { unit in
                VStack(spacing: 0) {
                    // 上面的小字读音；没有读音时放一个空格，保证每个字高度一致
                    Text(unit.reading ?? " ")
                        .font(.system(size: fontSize * 0.45))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                    // 下面的正文
                    Text(unit.text)
                        .font(.system(size: fontSize))
                        .fixedSize()
                }
            }
        }
    }
}

/// 自定义布局：从左到右排列，一行放不下就自动换到下一行
struct FlowLayout: Layout {
    var lineSpacing: CGFloat = 6

    // 计算整个布局需要多大
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            // 放不下了，换行
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width
            totalWidth = max(totalWidth, x)
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: totalWidth, height: y + lineHeight)
    }

    // 把每个子视图放到对应位置
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    FuriganaText(segments: FuriganaGenerator.generate("映画を見ることが好きなので、自分の映画の趣味を褒められて、うれしかったからです。"))
        .padding()
}
