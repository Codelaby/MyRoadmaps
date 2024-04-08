import SwiftUI

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct OTPField: View {
    
    @Environment(\.isEnabled) var isEnabled

    private enum FocusField: Hashable {
        case otpField
    }
    @FocusState private var focusedField: FocusField?
    
    @Binding var otpCode: String
    private let otpCodeLength: Int
    private let isError: Bool
    
    private let cornerRadius = 8.0
    
    init(_ otpCode: Binding<String>, otpCodeLength: Int = 6, isError: Bool = false) {
        self._otpCode = otpCode
        self.otpCodeLength = min(max(otpCodeLength, 1), 8)
        self.isError = isError
    }
    
    var body: some View {
        
        VStack {
            
            ZStack {
                
                HStack (spacing: 8) {
                    ForEach(0..<6) { index in
                        otpText(text: otpDigit(at: index), isSelected: otpCode.count == index )
                    }
                }
                
                TextField("", text: $otpCode)
                    .disabled(!isEnabled)
                    .frame(width: 0, height: 0)
                    .textContentType(.oneTimeCode)
                    .focused($focusedField, equals: .otpField)
                    .foregroundColor(.clear)
                    .accentColor(.clear)
                    .background(Color.clear)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
                    .onChange(of: otpCode, { oldValue, newValue in
                        let filteredValue = newValue.filter { $0.isNumber }
                        otpCode = String(filteredValue.prefix(6))
                    })
                
            }
        }
        .onAppear {
            self.focusedField = .otpField
        }
    }
    
    private func otpText(text: String, isSelected: Bool) -> some View {
        
        let bgColor = isError ? Color.red : Color.secondary
        
        return Text(text)
            .font(.title)
            .foregroundStyle(isError ? .red : .primary)
            .frame(width: 48, height: 48)
            .background(bgColor.opacity(0.25), in: .rect(cornerRadius: cornerRadius))
        
            //.overlay(RoundedRectangle(cornerRadius: cornerRadius).frame(width: nil, height: 2, alignment: .bottom), alignment: .bottom)
            .if(isSelected ) { view in
                view.overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke( Color.accentColor, lineWidth: 2)
                }
            }
        
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = .otpField
            }
    }
    
    private  func otpDigit(at index: Int) -> String {
        guard index < otpCode.count else { return "" } //placeholder
        return String(Array(otpCode)[index])
    }
}


class OTPViewModel: ObservableObject {
    
    private let testOTPvalild = "123456"
    
    @Published var otpCode: String = ""
    let otpCodeLength: Int = 6

    let duration: Duration = .seconds(240)
    var secondsRemaining: Int
    @Published var isExpired: Bool = false
    private var timer: Timer?

    init() {
        secondsRemaining = Int(duration.components.seconds)
        startTimer()
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsRemaining -= 1
            if self.secondsRemaining == 0 {
                self.isExpired = true
                self.timer?.invalidate()
            }
        }
    }
    private func pauseTimer() {
        timer?.invalidate()
    }
    
    private func resetTime() {
        secondsRemaining = Int(duration.components.seconds)
        isExpired = false
        startTimer()
    }
    
    func resendOTPCode() {
        print("✉️ Resend OTP Code")
        resetTime()
    }
    
    func isOTPValid() -> Bool {
        print("🚦 Check OTP code")
        if otpCode == testOTPvalild {
            pauseTimer()
        }
        return otpCode == testOTPvalild
    }
}

struct OTP_PlayGround: View {

    @StateObject var viewModel = OTPViewModel()
    
    @State var isOTPError: Bool = false
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .resizable()
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .scaledToFit()
                .frame(width: 72)
            Text("Enter you verification code").font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            Text("A message with a verification code has been sent to your devices. Please enter the code to continue.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            OTPField($viewModel.otpCode, isError: isOTPError)
                .disabled(viewModel.isExpired || viewModel.isOTPValid())
                .onChange(of: viewModel.otpCode) { oldValue, newValue in
                    if newValue.count >= viewModel.otpCodeLength {
                        isOTPError = !viewModel.isOTPValid()
                        if viewModel.isOTPValid() {
                            print("✅ User enter valid OTP Code")
                        }
                    } else {
                        isOTPError = false
                    }
                }
            
            HStack {
                Button("Resend code") {
                    viewModel.resendOTPCode()
                }
                .controlSize(.mini)
                .disabled(!viewModel.isExpired)
                Spacer()

                if !viewModel.isOTPValid() {
                    if viewModel.isExpired {
                        Text("OTP code expired")
                            .font(.footnote)
                            .foregroundStyle(.red)
                        
                    } else {
                        Group {
                            Text("Expire in ")
                                .font(.footnote)
                            +
                            Text(Date().addingTimeInterval(TimeInterval(viewModel.duration.components.seconds)), style: .timer)
                        }
                        .font(Font.system(.footnote, design: .monospaced))
                        .foregroundStyle(.secondary)
                    }
                } else {
                    Text("OTP code valid").font(.footnote).foregroundStyle(.green)
                }
                
            }
            
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("bento.me/codelaby").foregroundStyle(.blue)
        }
        .padding()
    }
}

#Preview {
    OTP_PlayGround()
}
