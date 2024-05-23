import SwiftUI

@Observable
final class MyTipViewModel {
    
    var showTip = false
    
    func asyncresponse() async {
        try! await Task.sleep(for: .seconds(1))
        showTip.toggle()
    }
}

struct ShowTipAnimationPlayground: View {
    @State private var isShowTip: Bool = false
    
    @State private var viewModel = MyTipViewModel()
    
    var body: some View {
        VStack {
            
            if isShowTip {
                Text("Your changes have been saved succesfully").foregroundStyle(.green)
                    .padding(8)
                    .background(.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    //.transition(.slide)
            }
            
            HStack {
                Text("Full name")
                Spacer()
                Button("Edit") {
                    Task {
                        await viewModel.asyncresponse()
                    }
                }
            }
            .padding()
            
            HStack {
                Text("Email adress")
                Spacer()
                Button("Edit") {
                    Task {
                        await viewModel.asyncresponse()
                    }
                }
            }
            .padding()
        }
        .onChange(of: viewModel.showTip) { oldValue, newValue in
            withAnimation() {
                isShowTip.toggle()
            }
        }
    }
}

#Preview {
    ShowTipAnimationPlayground()
}
