import Foundation
import Security
import LocalAuthentication
import CommonCrypto


class EncryptionContext {
    static func create() -> EncryptionStrategy {
        if #available(iOS 11.0, *) {
            // Check if Secure Enclave is supported
            if isSecureEnclaveSupported() {
                return ModernEncryptionStrategy()
            }
        }
        return LegacyEncryptionStrategy()
    }

    private static func isSecureEnclaveSupported() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if device supports biometry and Secure Enclave
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if context.biometryType == .faceID || context.biometryType == .touchID {
                return true
            }
        }
        
        return false
    }
}
