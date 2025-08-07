import Foundation
import LocalAuthentication
import CommonCrypto

@available(iOS 11.3, *)
class ModernEncryptionStrategy : EncryptionStrategy {
    
    func getServerKey(tag: String) throws -> String? {
        guard let secKey = try? getSecKey(tag: tag, flag: "S") else {
            throw CustomError.runtimeError("Failed to retrieve the private key")
        }

        var error: Unmanaged<CFError>?
        guard let keyData = SecKeyCopyExternalRepresentation(secKey, &error) as Data? else {
            if let error = error {
                throw error.takeRetainedValue() as Error
            }
            throw CustomError.runtimeError("Failed to extract key data from SecKey")
        }
        
        let base64EncodedKey = keyData.base64EncodedString()

        var pemKey = "-----BEGIN RSA PRIVATE KEY-----\n"
        var index = base64EncodedKey.startIndex

        while index < base64EncodedKey.endIndex {
            let endIndex = base64EncodedKey.index(index, offsetBy: 64, limitedBy: base64EncodedKey.endIndex) ?? base64EncodedKey.endIndex
            pemKey += base64EncodedKey[index..<endIndex] + "\n"
            index = endIndex
        }

        pemKey += "-----END RSA PRIVATE KEY-----\n"
        return pemKey
    }

    func storeCertificate(certificateData: Data, tag: String) throws -> Bool {
        let secAttrApplicationTag = (tag + "_cert").data(using: .utf8)!
 
        // First check if certificate already exists
        let checkQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: secAttrApplicationTag,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var status = SecItemCopyMatching(checkQuery as CFDictionary, nil)
        
        if status == errSecSuccess {
            // Certificate exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: secAttrApplicationTag
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: certificateData
            ]
            
            status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        } else if status == errSecItemNotFound {
            // Certificate does not exist, add it
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: secAttrApplicationTag,
                kSecValueData as String: certificateData
            ]
            
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }
        
        if status != errSecSuccess {
            if let errorMessage = SecCopyErrorMessageString(status, nil) {
                print("Certificate operation failed with error: \(errorMessage)")
            } else {
                print("Certificate operation failed with unknown error. Status code: \(status)")
            }
            return false
        }
        
        return true
    }
    
    func getCertificate(tag: String) throws -> String? {
        let secAttrApplicationTag = (tag + "_cert").data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: secAttrApplicationTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let certData = dataTypeRef as? Data else {
            return nil
        }

        return String(data: certData, encoding: .utf8)
    }
    
    func removeCertificate(tag: String) -> Bool {
        let secAttrApplicationTag = (tag + "_cert").data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: secAttrApplicationTag
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    func storeServerPrivateKey(privateKeyData: Data, tag: String) throws -> Bool {
        let secAttrApplicationTag = (tag + "_ss").data(using: .utf8)!
        
        // Process the PEM private key
        guard let pemString = String(data: privateKeyData, encoding: .utf8),
              let base64Encoded = pemString.split(separator: "\n").dropFirst().dropLast().joined().data(using: .utf8),
              let derData = Data(base64Encoded: base64Encoded) else {
            throw CustomError.runtimeError("Invalid private key data format")
        }
        
        // Create a dictionary for importing the private key
        let keyParams: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrIsPermanent as String: true
        ]
        
        // Create the SecKey object from the private key data
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(derData as CFData, keyParams as CFDictionary, &error) else {
            if let error = error {
                throw error.takeRetainedValue() as Error
            }
            throw CustomError.runtimeError("Failed to create the private key")
        }
        
        // First check if key already exists using SecItemCopyMatching
        let checkQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrApplicationTag as String: secAttrApplicationTag,
            kSecReturnRef as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var status = SecItemCopyMatching(checkQuery as CFDictionary, nil)
        
        if status == errSecSuccess {
            // Key exists, remove it before adding the new one
            // For SecKey objects this is the most reliable approach across all iOS versions
            if !removeKey(tag: tag, flag: "S") {
                throw CustomError.runtimeError("Failed to update existing private key")
            }
        }
        
        // Add the new key (whether it existed before or not)
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrApplicationTag as String: secAttrApplicationTag,
            kSecValueRef as String: secKey,
            kSecAttrIsPermanent as String: true
        ]
        
        status = SecItemAdd(addQuery as CFDictionary, nil)
        
        if status != errSecSuccess {
            if let errorMessage = SecCopyErrorMessageString(status, nil) {
                print("Private key operation failed with error: \(errorMessage)")
            } else {
                print("Private key operation failed with unknown error. Status code: \(status)")
            }
            return false
        }
        
        return true
    }

    func generateKeyPair(accessControlParam: AccessControlParam) throws -> SecKey  {
        // options
        //let secAccessControlCreateFlags: SecAccessControlCreateFlags = accessControlParam.option
         if try isKeyCreated(tag: accessControlParam.tag, flag: "C") == true{
            _ = removeKey(tag: accessControlParam.tag, flag: "C")   
         }
        
        let secAttrApplicationTag: Data? = accessControlParam.tag.data(using: .utf8)!
        var accessError: Unmanaged<CFError>?
        let secAttrAccessControl =
        SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            // dynamis dari flutter
            .privateKeyUsage,
            &accessError
        )
        
        let parameter : CFDictionary
        var parameterTemp: Dictionary<String, Any>
        
        if let error = accessError {
            throw error.takeRetainedValue() as Error
        }
        
        if let secAttrApplicationTag = secAttrApplicationTag {
            #if targetEnvironment(simulator)
                // target is current running in the simulator
                parameterTemp = [
                    kSecAttrKeyType as String           : kSecAttrKeyTypeEC, //kSecAttrKeyTypeEC,
                    kSecAttrKeySizeInBits as String     : 256,
                    kSecPrivateKeyAttrs as String       : [
                        kSecAttrIsPermanent as String       : true,
                        kSecAttrApplicationTag as String    : secAttrApplicationTag,
                        kSecAttrAccessControl as String     : secAttrAccessControl!
                    ]
                ]
            #else
                parameterTemp = [
                    kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
                    kSecAttrKeySizeInBits as String     : 256,
                    kSecAttrTokenID as String           : kSecAttrTokenIDSecureEnclave,
                    kSecPrivateKeyAttrs as String : [
                        kSecAttrIsPermanent as String       : true, 
                        kSecAttrApplicationTag as String    : secAttrApplicationTag,
                        kSecAttrAccessControl as String     : secAttrAccessControl!
                    ]
                ]
            #endif
            
            // convert ke CFDictinery,0
            parameter = parameterTemp as CFDictionary
            
            var secKeyCreateRandomKeyError: Unmanaged<CFError>?
            
            guard let secKey = SecKeyCreateRandomKey(parameter, &secKeyCreateRandomKeyError)
                    
            else {
                throw secKeyCreateRandomKeyError!.takeRetainedValue() as Error
            }
            
            return secKey
        } else {
            // tag error
            throw CustomError.runtimeError("Invalid TAG") as Error
        }
    }
    
    func removeKey(tag: String, flag: String) -> Bool {
        var tagValue = tag
        if flag == "S" {
            tagValue += "_ss"
        }
        let secAttrApplicationTag : Data = tagValue.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : secAttrApplicationTag
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            return true
        }

        if let message = SecCopyErrorMessageString(status, nil) {
            print("removeKey failed with error: \(message)")
        }

        return false
    }
    
    internal func getSecKey(tag: String, flag: String = "C") throws -> SecKey?  {
        var tagValue = tag
        if flag == "S" {
            tagValue += "_ss"
        }
        let secAttrApplicationTag = tagValue.data(using: .utf8)!
        // Determine key type based on flag
        let keyType: CFString = (flag == "S") ? kSecAttrKeyTypeRSA : kSecAttrKeyTypeEC
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : secAttrApplicationTag,
            kSecAttrKeyType as String           : keyType,
            kSecMatchLimit as String            : kSecMatchLimitOne ,
            kSecReturnRef as String             : true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw  NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: SecCopyErrorMessageString(status,nil) ?? "Undefined error"])
        }
        
        if let item = item {
            return (item as! SecKey)
        } else {
            return nil
        }
    }
    
    func isKeyCreated(tag: String, flag: String) throws -> Bool?  {
        do{
            let result =  try getSecKey(tag: tag, flag: flag)
            return result != nil ? true : false
        } catch {
            return false
        }
    }
    
    func getPublicKey(tag: String) throws -> String? {
        let secKey : SecKey
        let publicKey : SecKey
        
        do{
            secKey = try getSecKey(tag: tag)!
            publicKey = SecKeyCopyPublicKey(secKey)!
        } catch{
            throw error
        }
        
        if let publicKeyBase64 = exportPublicKeyAsSPKIBase64(publicKey: publicKey) {
            return publicKeyBase64
        }
        return nil
    }
    
    func exportPublicKeyAsSPKIBase64(publicKey: SecKey) -> String? {
        var error: Unmanaged<CFError>?
        if let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? {
            let header: [UInt8] = [
                0x30, 0x59, // SEQUENCE header
                0x30, 0x13, // SEQUENCE header for algorithm identifier
                0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, // OID for id-ecPublicKey
                0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, // OID for prime256v1 curve
                0x03, 0x42, 0x00 // BIT STRING header
            ]
            var spkiData = Data(header)
            spkiData.append(publicKeyData)
            return spkiData.base64EncodedString()
        } else {
            print("Error exporting public key: \(error.debugDescription)")
            return nil
        }
    }
    
    func encrypt(message: String, tag: String) throws -> FlutterStandardTypedData?  {
        let secKey : SecKey
        let publicKey : SecKey
        
        do{
            secKey = try getSecKey(tag: tag)!
            publicKey = SecKeyCopyPublicKey(secKey)!
        } catch{
            throw error
        }
        
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw CustomError.runtimeError("Algorithm not suppoort")
        }
        
        var error: Unmanaged<CFError>?
        let clearTextData = message.data(using: .utf8)!
        let cipherTextData = SecKeyCreateEncryptedData(
            publicKey,
            algorithm,
            clearTextData as CFData,
            &error) as Data?
        
        if let error = error {
            throw error.takeRetainedValue() as Error
        }
        
        if let cipherTextData = cipherTextData {
            return FlutterStandardTypedData(bytes: cipherTextData)
        } else {
            throw CustomError.runtimeError("Cannot encrypt data")
        }
    }
    
    func decrypt(message: Data, tag: String) throws -> String?  {
        let secKey : SecKey
        
        do{
            secKey = try getSecKey(tag: tag, flag: "S")!
        } catch{
            throw error
        }
        
        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA256 //.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        let cipherTextData = message as CFData
        
        guard SecKeyIsAlgorithmSupported(secKey, .decrypt, algorithm) else {
            throw CustomError.runtimeError("Algorithm not supported")
        }
        
        var error: Unmanaged<CFError>?
        let plainTextData = SecKeyCreateDecryptedData(
            secKey,
            algorithm,
            cipherTextData,
            &error) as Data?
        
        if let error = error {
            throw error.takeUnretainedValue() as Error
        }
        
        if let plainTextData = plainTextData {
            // Server returns raw AES key bytes, convert to base64 for consistent handling
            let base64Key = plainTextData.base64EncodedString()
            return base64Key
        } else {
            throw CustomError.runtimeError("Can't decrypt data")
        }
    }
    
    func sign(tag: String, message: Data) throws -> String?{
        let secKey : SecKey
        
        do{
            secKey = try getSecKey(tag: tag)!
        } catch {
            throw error
        }

        var error: Unmanaged<CFError>?
        guard let signData = SecKeyCreateSignature(
            secKey,
            SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256,
            message as CFData, &error) else {
            if let e = error {
              throw e.takeUnretainedValue() as Error
            }
            throw CustomError.runtimeError("Can't sign data")
        } //2
        
        let signedData = signData as Data
        let signedString = signedData.base64EncodedString(options: [])
        return signedString
    }
    
    
    func verify(tag: String, plainText: String, signature: String) throws -> Bool {
        // Base64 decode the signature
            guard let signatureData = Data(base64Encoded: signature) else {
                return false
            }

            // Get the existing key pair from Secure Enclave / Keychain
            let secKey = try getSecKey(tag: tag)!
            
            // Get public key reference from private key
            guard let publicKey = SecKeyCopyPublicKey(secKey) else {
                throw CustomError.runtimeError("Public key not found")
            }

            // Normalize the plaintext and convert to data
            let normalizedPlainText = plainText.precomposedStringWithCanonicalMapping
            guard let messageData = normalizedPlainText.data(using: .utf8) else {
                return false
            }

            // Check algorithm support
            let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256
            guard SecKeyIsAlgorithmSupported(publicKey, .verify, algorithm) else {
                throw CustomError.runtimeError("Algorithm not supported for verification")
            }

            // Perform signature verification
            let verifyRes =  SecKeyVerifySignature(
                publicKey,
                algorithm,
                messageData as CFData,
                signatureData as CFData,
                nil
            )
        return verifyRes;
    }
    
    func decryptWithAES(encryptedData: Data, aesKey: Data) throws -> String? {
        // Server updated: IV is now prepended to encrypted data
        // Format: [IV (16 bytes)][Encrypted Data (remaining bytes)]
        
        guard encryptedData.count > kCCBlockSizeAES128 else {
            throw CustomError.runtimeError("Encrypted data too short - must contain at least 16 bytes for IV")
        }
        
        // Extract IV from first 16 bytes
        let iv = encryptedData.prefix(kCCBlockSizeAES128)
        let actualEncryptedData = encryptedData.dropFirst(kCCBlockSizeAES128)
        
        // Create output buffer
        let bufferSize = actualEncryptedData.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted: size_t = 0
        
        let status = CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            aesKey.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress },
            aesKey.count,
            iv.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress },
            actualEncryptedData.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress },
            actualEncryptedData.count,
            &buffer,
            bufferSize,
            &numBytesDecrypted
        )
        
        guard status == kCCSuccess else {
            throw CustomError.runtimeError("AES decryption failed with status: \(status)")
        }
        
        let decryptedData = Data(bytes: buffer, count: numBytesDecrypted)
        return String(data: decryptedData, encoding: .utf8)
    }
}
