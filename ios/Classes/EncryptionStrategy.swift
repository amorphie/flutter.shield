import Foundation
import LocalAuthentication

// Abstraction/Protocol class of EncryptionStrategy
protocol EncryptionStrategy {
    
    func storeCertificate(certificateData: Data, tag: String) throws -> Bool

    func getCertificate(tag: String) throws -> String?

    func removeCertificate(tag: String) throws -> Bool
    
    func storeServerPrivateKey(privateKeyData: Data, tag: String) throws -> Bool

    func getServerKey(tag: String) throws -> String?
    
    func generateKeyPair(accessControlParam: AccessControlParam) throws -> SecKey
    
    func removeKey(tag: String, flag: String) throws -> Bool
    
    func isKeyCreated(tag: String, flag: String) throws -> Bool?
    
    func getPublicKey(tag: String) throws -> String?
    
    func encrypt(message: String, tag: String) throws -> FlutterStandardTypedData?
    
    func decrypt(message: Data, tag: String) throws -> String?
    
    func sign(tag: String, message: Data) throws -> String?
    
    func verify(tag: String, plainText: String, signature: String) throws -> Bool
}
