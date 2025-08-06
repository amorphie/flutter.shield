import Flutter
import UIKit


// @available(iOS 11.3, *)
public class SwiftSecureEnclavePlugin: NSObject, FlutterPlugin {
    let encryptionStrategy = EncryptionContext.create()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_shield", binaryMessenger: registrar.messenger())
        let instance: SwiftSecureEnclavePlugin = SwiftSecureEnclavePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method{
        case "storeCertificate":
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let certificateData = param!["certificateData"] as! FlutterStandardTypedData
                let isSuccess = try encryptionStrategy.storeCertificate(certificateData: certificateData.data, tag: tag)
                result(resultSuccess(data:isSuccess))
            } catch {
                result(resultError(error:error))
            }
         case "getCertificate":
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let certificate = try encryptionStrategy.getCertificate(tag: tag)
                result(resultSuccess(data:certificate))
            } catch {
                result(resultError(error:error))
            }
        case "removeCertificate":
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let isSuccess = try encryptionStrategy.removeCertificate(tag: tag)
                result(resultSuccess(data:isSuccess))
            } catch {
                result(resultError(error:error))
            }
            
        case "storeServerPrivateKey":
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let privateKeyData = param!["privateKeyData"] as! FlutterStandardTypedData
                let isSuccess = try encryptionStrategy.storeServerPrivateKey(privateKeyData: privateKeyData.data, tag: tag)
                result(resultSuccess(data:isSuccess))
            } catch {
                result(resultError(error:error))
            }
            
        case "getServerKey":
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let privateKeyData = try encryptionStrategy.getServerKey(tag: tag)
                result(resultSuccess(data:privateKeyData))
            } catch {
                result(resultError(error:error))
            }
            
        case "generateKeyPair":
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let accessControlParam = AccessControlFactory(value: param!["accessControl"] as! Dictionary<String, Any>).build()
                                
                _ = try encryptionStrategy.generateKeyPair(accessControlParam: accessControlParam)
                result(resultSuccess(data:true))
            } catch {
                result(resultError(error:error))
            }
            
        case "removeKey":
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let flag = param!["flag"] as! String             
                let isSuccess = try encryptionStrategy.removeKey(tag: tag, flag: flag)
                result(resultSuccess(data:isSuccess))
            } catch {
                result(resultError(error:error))
            }
            
        case "isKeyCreated":
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let flag = param!["flag"] as! String             
                let key = try encryptionStrategy.isKeyCreated(tag: tag, flag: flag)
                result(resultSuccess(data:key!))
            } catch {
                result(resultSuccess(data:false))
            }
            
        case "getPublicKey":
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let key = try encryptionStrategy.getPublicKey(tag: tag)
                result(resultSuccess(data:key!))
            } catch {
                result(resultError(error:error))
            }
            
        case "encrypt" :
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let message = param!["message"] as! String
                let encrypted = try encryptionStrategy.encrypt(message: message, tag: tag)
                result(resultSuccess(data:encrypted))
            } catch {
                result(resultError(error:error))
            }
            
        case "decrypt" :
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let message = param!["message"] as! FlutterStandardTypedData
                let decrypted = try encryptionStrategy.decrypt(message: message.data, tag: tag)
                result(resultSuccess(data:decrypted))
            } catch {
                result(resultError(error:error))
            }
            
        case "sign" :
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let message = param!["message"] as! FlutterStandardTypedData
                let signature = try encryptionStrategy.sign(tag: tag, message: message.data)
                
                result(resultSuccess(data:signature))
            } catch {
                result(resultError(error:error))
            }
            
        case "verify" :
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let signatureText = param!["signature"] as! String
                let plainText = param!["plainText"] as! String
                let signature = try encryptionStrategy.verify(
                    tag: tag, plainText: plainText, signature: signatureText
                )
                
                result(resultSuccess(data:signature))
            } catch {
                result(resultError(error:error))
            }
            
        case "decryptWithAES" :
            do{
                let param = call.arguments as? Dictionary<String, Any>
                let encryptedData = param!["encryptedData"] as! FlutterStandardTypedData
                let aesKey = param!["aesKey"] as! FlutterStandardTypedData
                let decrypted = try encryptionStrategy.decryptWithAES(encryptedData: encryptedData.data, aesKey: aesKey.data)
                result(resultSuccess(data:decrypted))
            } catch {
                result(resultError(error:error))
            }
       
        default:
            return
        }
        
    }
}
