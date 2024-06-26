import Foundation
import LocalAuthentication

// Abstraction/Protocol class of EncryptionStrategy
protocol EncryptionStrategy {
    // create and store private key to secure enclave
    func generateKeyPair(accessControlParam: AccessControlParam) throws -> SecKey
    
    // remove key from secure enclave
    func removeKey(tag: String) throws -> Bool
    
    // get status SecKey key from secure enclave (private method)
    func isKeyCreated(tag: String) throws -> Bool?
    
    // get publicKey key from secure enclave
    func getPublicKey(tag: String) throws -> String?
    
    // encryption
    func encrypt(message: String, tag: String) throws -> FlutterStandardTypedData?
    
    // decryption
    func decrypt(message: Data, tag: String) throws -> String?
    
    // sign
    func sign(tag: String, message: Data) throws -> String?
    
    // verify
    func verify(tag: String, plainText: String, signature: String) throws -> Bool
}