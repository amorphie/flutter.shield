import Foundation
import CommonCrypto

class LegacyEncryptionStrategy : EncryptionStrategy {
    
    func storeServerPrivateKey(privateKeyData: Data, tag: String) throws -> Bool {
        let secAttrApplicationTag = (tag + "_ss").data(using: .utf8)!
        
        // Create a dictionary for importing the private key
        let keyParams: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA, //kSecAttrKeyTypeEC
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrIsPermanent as String: true
        ]
        
        if let pemString = String(data: privateKeyData, encoding: .utf8),
           let base64Encoded = pemString.split(separator: "\n").dropFirst().dropLast().joined().data(using: .utf8),
           let derData = Data(base64Encoded: base64Encoded) {
            var error: Unmanaged<CFError>?
            guard let secKey = SecKeyCreateWithData(derData as CFData, keyParams as CFDictionary, &error) else {
                if let error = error {
                    throw error.takeRetainedValue() as Error
                }
                throw CustomError.runtimeError("Failed to create the private key")
            }
            
            // Create a dictionary for adding the private key to the Keychain
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
                kSecAttrApplicationTag as String: secAttrApplicationTag,
                kSecValueRef as String: secKey,
                kSecAttrIsPermanent as String: true
            ]
            
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            guard status == errSecSuccess else {
                if status == errSecDuplicateItem {
                    throw CustomError.runtimeError("Private key already exists")
                }
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: SecCopyErrorMessageString(status, nil) ?? "Undefined error"])
            }
        }
        
        // Verify if the key was successfully stored
        return try isKeyCreated(tag: tag) ?? false
    }
    
     func generateKeyPair(accessControlParam: AccessControlParam) throws -> SecKey {
         let secAttrApplicationTag: Data? = accessControlParam.tag.data(using: .utf8)

         if secAttrApplicationTag == nil {
             // tag error
             throw CustomError.runtimeError("Invalid TAG") as Error
         }

         let parameter : CFDictionary
         var parameterTemp: Dictionary<String, Any>
         parameterTemp = [
             kSecAttrKeyType as String           : kSecAttrKeyTypeEC, //kSecAttrKeyTypeEC,
             kSecAttrKeySizeInBits as String     : 256,
             kSecPrivateKeyAttrs as String       : [
                 kSecAttrIsPermanent as String       : true,
                 kSecAttrApplicationTag as String    : secAttrApplicationTag!
             ]
         ]
         
         // convert to CFDictionary
         parameter = parameterTemp as CFDictionary
         
         var secKeyCreateRandomKeyError: Unmanaged<CFError>?
         
         guard let secKey = SecKeyCreateRandomKey(parameter, &secKeyCreateRandomKeyError) else {
             throw secKeyCreateRandomKeyError!.takeRetainedValue() as Error
         }
         
         return secKey
    }
    
    func removeKey(tag: String) throws -> Bool {
        let secAttrApplicationTag : Data = tag.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : secAttrApplicationTag
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess else {
            if status == errSecNotAvailable || status == errSecItemNotFound {
                return false
            } else {
                throw  NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: SecCopyErrorMessageString(status,nil) ?? "Undefined error"])
            }
        }
        
        return true
    }
    
    internal func getSecKey(tag: String) throws -> SecKey?  {
        let secAttrApplicationTag = tag.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : secAttrApplicationTag,
            //kSecAttrKeyType as String           : kSecAttrKeyTypeEC, //kSecAttrKeyTypeEC,
            //kSecMatchLimit as String            : kSecMatchLimitOne ,
            kSecReturnRef as String             : kCFBooleanTrue!
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
    
    func isKeyCreated(tag: String) throws -> Bool?  {
        do{
            let result =  try getSecKey(tag: tag)
            return result != nil ? true : false
        } catch{
            throw error
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
    
    func convertToPEMFormat(base64PublicKey: String) -> String {
        let pemHeader = "-----BEGIN PUBLIC KEY-----\n"
        let pemFooter = "\n-----END PUBLIC KEY-----"
        
        // Base64 string'i 64 karakterlik satırlara böler ve son satırda fazladan newline eklemez
        let chunkSize = 64
        var formattedKey = ""
        for i in stride(from: 0, to: base64PublicKey.count, by: chunkSize) {
            let startIndex = base64PublicKey.index(base64PublicKey.startIndex, offsetBy: i)
            let endIndex = base64PublicKey.index(startIndex, offsetBy: chunkSize, limitedBy: base64PublicKey.endIndex) ?? base64PublicKey.endIndex
            formattedKey += base64PublicKey[startIndex..<endIndex]
            if endIndex < base64PublicKey.endIndex {
                formattedKey += "\n"
            }
        }
        
        return pemHeader + formattedKey + pemFooter
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
            secKey = try getSecKey(tag: tag)!
        } catch{
            throw error
        }
        
        let algorithm: SecKeyAlgorithm = .rsaEncryptionPKCS1  // .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
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
            let plainText = String(decoding: plainTextData, as: UTF8.self)
            return plainText
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
        } 
        
        let signedData = signData as Data
        let signedString = signedData.base64EncodedString(options: [])
        return signedString
    }
    
    
    func verify(tag: String, plainText: String, signature: String) throws -> Bool {
        let externalKeyB64String : String
        
        guard Data(base64Encoded: signature) != nil else {
            return false
        }
        
        do{
            externalKeyB64String = try getPublicKey(tag: tag)!
        } catch{
            throw error
        }
        
        //convert b64 key back to usable key
        let newPublicKeyData = Data(base64Encoded: externalKeyB64String, options: [])
        let newPublicParams: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC, //kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 256
        ]
        guard let newPublicKey = SecKeyCreateWithData(newPublicKeyData! as CFData, newPublicParams as CFDictionary, nil) else {
            return false
        }
        
        let normalizedPlainText = plainText.precomposedStringWithCanonicalMapping
        guard let messageData = normalizedPlainText.data(using: String.Encoding.utf8) else {
            return false
        }
        
        guard let signatureData = Data(base64Encoded: signature, options: []) else {
            return false
        }
        
        let verify = SecKeyVerifySignature(newPublicKey, SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256, messageData as CFData, signatureData as CFData, nil)
        return verify
    }
}
