import SwiftUI

struct FlowLayout: Layout {
    var alignment: Alignment = .center
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        let proposedWidth = proposal.width ?? .infinity
        
        for size in sizes {
            if lineWidth + size.width > proposedWidth {
                
                totalHeight += lineHeight + spacing
                totalWidth = max(totalWidth, lineWidth)
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        
        totalHeight += lineHeight
        totalWidth = max(totalWidth, lineWidth)
        
        return CGSize(width: totalWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var point = CGPoint(x: bounds.minX, y: bounds.minY)
        var lineHeight: CGFloat = 0
        let proposedWidth = proposal.width ?? bounds.width
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if point.x + size.width > bounds.minX + proposedWidth {
                point.y += lineHeight + spacing
                point.x = bounds.minX
                lineHeight = 0
            }
            
            // Place the view
            subview.place(at: point, proposal: .unspecified)
            
            // Update position and line height
            point.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
