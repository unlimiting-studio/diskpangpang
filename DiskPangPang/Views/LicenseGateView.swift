import SwiftUI

struct LicenseGateView: View {
    @State private var licenseKey = ""
    @State private var isValidating = false
    @State private var errorMessage: String?

    let onActivated: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.accent)

                Text("라이선스 필요")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("파일 삭제 기능을 사용하려면\n라이선스 키를 입력하세요")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ZStack(alignment: .leading) {
                    if licenseKey.isEmpty {
                        Text("DPANG-XXXX-XXXX-XXXX")
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .padding(.leading, 12)
                    }
                    TextField("", text: $licenseKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(12)
                        .onChange(of: licenseKey) { _, newValue in
                            licenseKey = newValue.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
                        }
                }
                .background(AppTheme.surfaceLight, in: RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 10) {
                    Button("취소") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.surfaceLight, in: RoundedRectangle(cornerRadius: 8))

                    Button {
                        activateLicense()
                    } label: {
                        HStack(spacing: 6) {
                            if isValidating {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            }
                            Text(isValidating ? "확인 중..." : "활성화")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            licenseKey.isEmpty ? AppTheme.surfaceLight : AppTheme.accent,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(licenseKey.isEmpty || isValidating)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)
                }
            }

            VStack(spacing: 4) {
                Text("라이선스가 없으신가요?")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textTertiary)

                Link("구매하기", destination: URL(string: "https://buy.polar.sh/polar_cl_Jq3WmvzFD48mMuTbVuKcGX79iBhUQA2cD8swI3GcdPP")!)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(32)
        .frame(width: 380)
        .background(AppTheme.surface)
    }

    private func activateLicense() {
        isValidating = true
        errorMessage = nil

        Task {
            let status = await LicenseService.shared.activate(key: licenseKey.trimmingCharacters(in: .whitespacesAndNewlines))

            isValidating = false
            switch status {
            case .valid:
                onActivated()
                dismiss()
            case .invalid(let msg):
                errorMessage = msg
            case .error(let msg):
                errorMessage = msg
            }
        }
    }
}
