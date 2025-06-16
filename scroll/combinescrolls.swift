import SwiftUI

struct ProductItems: View {
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(0..<100) { i in
                    Text("Item \(i)")
                        .containerRelativeFrame(.horizontal, count: 4, spacing: 16)
                        .frame(height: 128)
                        .background(.thinMaterial, in: .rect(cornerRadius: 8))
                }
            }

        }
    }
}

#Preview {
    ProductItems()
}

struct CombineScrollsDemo: View {
    var body: some View {
        NavigationStack {
            
            ScrollView(.vertical) {
                LazyVStack {
                    Text("Top header")
                        .frame(width: .infinity, height: 128)
                        .background(.red)
                    
                    Text("Movies").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    ProductItems()
                    
                    ForEach(0..<20) { i in
                        Text("Item \(i)")
                    }
                    
                    Text("Books").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    ProductItems()
                    
                }
            }
            
        }
    }
}

#Preview {
    CombineScrollsDemo()
}
