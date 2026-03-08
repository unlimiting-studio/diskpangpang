import Foundation

struct LicenseValidationResponse: Codable {
    let id: String
    let status: String
    let key: String
    let activation: LicenseActivation?
}

struct LicenseActivation: Codable {
    let id: String
    let label: String
}

struct LicenseActivationResponse: Codable {
    let id: String
    let license_key_id: String
    let label: String
}

enum LicenseStatus {
    case valid
    case invalid(String)
    case error(String)
}

@MainActor
final class LicenseService {
    static let shared = LicenseService()

    private let organizationId = "4f4403a6-7515-4a25-a081-ff41be227676"
    private let validateURL = "https://api.polar.sh/v1/customer-portal/license-keys/validate"
    private let activateURL = "https://api.polar.sh/v1/customer-portal/license-keys/activate"

    private let licenseKeyKey = "diskpangpang_license_key"
    private let activationIdKey = "diskpangpang_activation_id"

    var storedLicenseKey: String? {
        UserDefaults.standard.string(forKey: licenseKeyKey)
    }

    var storedActivationId: String? {
        UserDefaults.standard.string(forKey: activationIdKey)
    }

    var isActivated: Bool {
        storedLicenseKey != nil && storedActivationId != nil
    }

    func activate(key: String) async -> LicenseStatus {
        // First validate the key
        let validateResult = await validate(key: key)
        guard case .valid = validateResult else {
            return validateResult
        }

        // Activate on this device
        let label = Host.current().localizedName ?? "Mac"
        guard let url = URL(string: activateURL) else {
            return .error("잘못된 URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "key": key,
            "organization_id": organizationId,
            "label": label
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error("서버 응답 오류")
            }

            if httpResponse.statusCode == 200 {
                let activation = try JSONDecoder().decode(LicenseActivationResponse.self, from: data)
                UserDefaults.standard.set(key, forKey: licenseKeyKey)
                UserDefaults.standard.set(activation.id, forKey: activationIdKey)
                return .valid
            } else if httpResponse.statusCode == 403 {
                return .invalid("활성화 한도 초과 (최대 3대)")
            } else {
                return .invalid("활성화 실패 (코드: \(httpResponse.statusCode))")
            }
        } catch {
            return .error("네트워크 오류: \(error.localizedDescription)")
        }
    }

    func validate(key: String) async -> LicenseStatus {
        guard let url = URL(string: validateURL) else {
            return .error("잘못된 URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "key": key,
            "organization_id": organizationId
        ]

        if let activationId = storedActivationId {
            body["activation_id"] = activationId
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error("서버 응답 오류")
            }

            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(LicenseValidationResponse.self, from: data)
                if result.status == "granted" {
                    return .valid
                } else {
                    return .invalid("라이선스가 비활성화 상태입니다 (\(result.status))")
                }
            } else if httpResponse.statusCode == 404 {
                return .invalid("유효하지 않은 라이선스 키입니다")
            } else {
                return .invalid("검증 실패 (코드: \(httpResponse.statusCode))")
            }
        } catch {
            // Offline grace: if previously activated, allow usage
            if isActivated {
                return .valid
            }
            return .error("네트워크 오류: \(error.localizedDescription)")
        }
    }

    func revalidateStoredKey() async -> LicenseStatus {
        guard let key = storedLicenseKey else {
            return .invalid("저장된 라이선스 없음")
        }
        return await validate(key: key)
    }

    func clearLicense() {
        UserDefaults.standard.removeObject(forKey: licenseKeyKey)
        UserDefaults.standard.removeObject(forKey: activationIdKey)
    }
}
