import SwiftUI

struct FlowLayoutView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let isSelected: (Data.Element) -> Bool
    let onTap: (Data.Element) -> Void
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    init(items: Data,
         isSelected: @escaping (Data.Element) -> Bool,
         onTap: @escaping (Data.Element) -> Void,
         spacing: CGFloat = 4,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.isSelected = isSelected
        self.onTap = onTap
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(Array(items.enumerated()), id: \.element) { _, item in
                content(item)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                    .onTapGesture {
                        onTap(item)
                    }
            }
        }
    }
}
