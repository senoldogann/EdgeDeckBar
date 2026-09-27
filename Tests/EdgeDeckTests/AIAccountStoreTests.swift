import Foundation
import XCTest
@testable import EdgeDeck

/// Gerçek dosya sistemi ve gerçek Keychain (`security`) ile Codex hesap geçişini doğrular.
/// Keychain'e benzersiz test hesapları yazılır ve test sonunda silinir.
final class AIAccountStoreTests: XCTestCase {
    private func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func codexAuthJSON(accountID: String, email: String) -> Data {
        let claims = #"{"email":"\#(email)","https://api.openai.com/auth":{"chatgpt_plan_type":"plus","chatgpt_account_id":"\#(accountID)"}}"#
        let idToken = "\(base64URL(Data(#"{"alg":"none"}"#.utf8))).\(base64URL(Data(claims.utf8))).sig"
        // Gerçek token'lar kadar uzun: `security -i` satır sınırını aşan kimlik bilgileri de saklanabilmeli
        let longAccessToken = String(repeating: "a", count: 6_000)
        let auth = #"{"auth_mode":"chatgpt","tokens":{"id_token":"\#(idToken)","access_token":"\#(longAccessToken)","refresh_token":"rt-\#(accountID)","account_id":"\#(accountID)"}}"#
        return Data(auth.utf8)
    }

    func testCodexAccountsAreAutoSavedAndSwitchable() async throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent("edgedeck-accounts-\(UUID().uuidString)")
        let authURL = home.appendingPathComponent(".codex/auth.json")
        try FileManager.default.createDirectory(at: authURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let suffix = UUID().uuidString.prefix(8)
        let firstID = "edgedeck-test-a-\(suffix)"
        let secondID = "edgedeck-test-b-\(suffix)"
        defer {
            try? FileManager.default.removeItem(at: home)
            try? deleteKeychainPassword(service: "dev.edgedeck.account.codex", account: firstID)
            try? deleteKeychainPassword(service: "dev.edgedeck.account.codex", account: secondID)
        }
        let store = AIAccountStore(registryURL: home.appendingPathComponent("ai_accounts.json"), homeDirectory: home)

        let firstAuth = codexAuthJSON(accountID: firstID, email: "first@example.com")
        try firstAuth.write(to: authURL)
        let afterFirstLogin = try await store.synchronize()
        XCTAssertEqual(afterFirstLogin.activeAccounts[.codex]?.accountID, firstID)
        XCTAssertEqual(afterFirstLogin.activeAccounts[.codex]?.planName, "Plus")

        // Kullanıcı terminalde başka hesaba giriş yapar
        try codexAuthJSON(accountID: secondID, email: "second@example.com").write(to: authURL)
        let afterSecondLogin = try await store.synchronize()
        XCTAssertEqual(afterSecondLogin.activeAccounts[.codex]?.accountID, secondID)
        XCTAssertEqual(Set(afterSecondLogin.registry.accounts.map(\.accountID)), [firstID, secondID])

        let firstAccount = try XCTUnwrap(afterSecondLogin.registry.accounts.first { $0.accountID == firstID })

        // Açık Codex oturumu varken geçiş reddedilir ve hiçbir dosya değişmez
        do {
            _ = try await store.switchAccount(to: firstAccount, runningSessionCount: 2)
            XCTFail("Switching with running sessions must fail")
        } catch AIAccountStoreError.providerSessionsRunning(let provider, let count) {
            XCTAssertEqual(provider, .codex)
            XCTAssertEqual(count, 2)
        }
        XCTAssertEqual(try parseCodexAccount(authJSON: Data(contentsOf: authURL)).accountID, secondID)

        let afterSwitch = try await store.switchAccount(to: firstAccount, runningSessionCount: 0)
        XCTAssertEqual(afterSwitch.activeAccounts[.codex]?.accountID, firstID)
        XCTAssertEqual(try Data(contentsOf: authURL), firstAuth)
        let permissions = try FileManager.default.attributesOfItem(atPath: authURL.path)[.posixPermissions] as? Int
        XCTAssertEqual(permissions, 0o600)
        XCTAssertNotNil(afterSwitch.registry.switchedAt[AIAccountProvider.codex.rawValue])

        let secondAccount = try XCTUnwrap(afterSwitch.registry.accounts.first { $0.accountID == secondID })
        let afterRemoval = try await store.removeAccount(secondAccount)
        XCTAssertEqual(afterRemoval.registry.accounts.map(\.accountID), [firstID])

        do {
            _ = try await store.removeAccount(firstAccount)
            XCTFail("Removing the active account must fail")
        } catch AIAccountStoreError.cannotRemoveActiveAccount {
            // Beklenen: aktif hesap silinemez
        }
    }
}
