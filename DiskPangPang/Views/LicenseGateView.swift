import SwiftUI

struct LicenseGateView: View {
    @State private var licenseKey = ""
    @State private var isValidating = false
    @State private var errorMessage: String?
    @State private var isActivated = LicenseService.shared.isActivated

    let onActivated: () -> Void

    var body: some View {
        if isActivated {
            Color.clear.onAppear { onActivated() }
        } else {
            activationView
        }
    }

    private var activationView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // App icon
                Image("AppLogo")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 8) {
                    Text("DiskPangPang")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("라이선스 키를 입력하세요")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                VStack(spacing: 12) {
                    TextField("DPANG-XXXX-XXXX-XXXX", text: $licenseKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, design: .monospaced))
                        .padding(12)
                        .background(AppTheme.surfaceLight, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 320)

                    Button {
                        activateLicense()
                    } label: {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            }
                            Text(isValidating ? "확인 중..." : "활성화")
                        }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(.white)
                        .frame(width: 320)
                        .padding(.vertical, 10)
                        .background(
                            licenseKey.isEmpty ? AppTheme.surfaceLight : AppTheme.accent,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(licenseKey.isEmpty || isValidating)

                    if let error = errorMessage {
                        Text(error)
                            .font(AppTheme.captionFont)
                            .foregroundStyle(.orange)
                    }
                }

                VStack(spacing: 4) {
                    Text("라이선스가 없으신가요?")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textTertiary)

                    Link("구매하기 ($2.49)", destination: URL(string: "https://polar.sh/unlimiting-studio/products/23a383c4-0755-4c53-80bf-aaac9f90fc23")!)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.accent)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .task {
            // Check if already activated on launch
            if LicenseService.shared.isActivated {
                let status = await LicenseService.shared.revalidateStoredKey()
                if case .valid = status {
                    isActivated = true
                    onActivated()
                }
            }
        }
    }

    private func activateLicense() {
        isValidating = true
        errorMessage = nil

        Task {
            let status = await LicenseService.shared.activate(key: licenseKey.trimmingCharacters(in: .whitespacesAndNewlines))

            isValidating = false
            switch status {
            case .valid:
                isActivated = true
                onActivated()
            case .invalid(let msg):
                errorMessage = msg
            case .error(let msg):
                errorMessage = msg
            }
        }
    }
}
