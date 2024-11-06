package id.my.burganbank.flutter_shield

import id.my.burganbank.flutter_shield.model.*
import id.my.burganbank.flutter_shield.factory.*
import java.math.BigInteger;
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.PublicKey
import java.security.Signature
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;
import javax.security.auth.x500.X500Principal;
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import javax.crypto.Cipher
import java.util.*
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.plugin.common.StandardMethodCodec.INSTANCE
import android.os.Build

class SecureEnclavePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var encryptionStrategy: EncryptionStrategy
    val apiLevel = Build.VERSION.SDK_INT
   
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_shield")
        channel.setMethodCallHandler(this)
        encryptionStrategy = EncryptionContext.create(apiLevel, context)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "storeServerPrivateKey" -> {
                try {
                    val param = call.arguments as? Map<String, Any>
                    val tag = param?.get("tag") as? String ?: ""
                    val privateKeyDataBytes = (param?.get("privateKeyData") as? ByteArray) ?: byteArrayOf()
                    val isSuccess = encryptionStrategy.storeServerPrivateKey(tag, privateKeyDataBytes)
                    result.success(mapOf("status" to "success", "data" to isSuccess))
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage, null)
                }
            },
            "generateKeyPair" -> {
                try {
                    val param = call.arguments as? Map<String, Any?>
                    if(param != null){
                        val accessControlValue = param["accessControl"] as? Map<String, Any?>
                        if(accessControlValue != null){
                            val accessControlParam = AccessControlFactory(accessControlValue).build()
                            encryptionStrategy.generateKeyPair(accessControlParam)
                            result.success(mapOf("status" to "success", "data" to true))
                        }                        
                    }else{
                        result.error("ERROR", "accessControl is empty", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage, null)
                }
            }
            "removeKey" -> {
                try {
                    val param = call.arguments as? Map<String, Any>
                    val tag = param?.get("tag") as? String ?: ""
                    encryptionStrategy.removeKey(tag)
                    result.success(mapOf("status" to "success", "data" to true))
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage, null)
                }
            }
            "isKeyCreated" -> {
                try {
                    val param = call.arguments as? Map<String, Any>
                    val tag = param?.get("tag") as? String ?: ""
                    val isCreated = encryptionStrategy.isKeyCreated(tag)
                    result.success(mapOf("status" to "success", "data" to isCreated))
                } catch (e: Exception) {
                    result.success(mapOf("status" to "success", "data" to false))
                }
            }
            "getPublicKey" -> {
                try {
                    val param = call.arguments as? Map<String, Any>
                    val tag = param?.get("tag") as? String ?: ""
                    val publicKey = encryptionStrategy.getPublicKey(tag)
                    result.success(mapOf("status" to "success", "data" to publicKey))
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage, null)
                }
            }
            "encrypt" -> {
                try {
                    val param = call.arguments as? Map<String, Any>
                    val tag = param?.get("tag") as? String ?: ""
                    val message = param?.get("message") as? String ?: ""
                    val encrypted = encryptionStrategy.encrypt(message, tag)
                    result.success(mapOf("status" to "success", "data" to encrypted))
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage, null)
                }
            }
            "decrypt" -> {
                try {
                    val param = call.arguments as? Map<String, Any>
                    val tag = param?.get("tag") as? String ?: ""
                    val messageBytes = (param?.get("message") as? ByteArray) ?: byteArrayOf()
                    val decrypted = encryptionStrategy.decrypt(messageBytes, tag)
                    result.success(mapOf("status" to "success", "data" to decrypted))
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage, null)
                }
            }
            "sign" -> {
                try {
                    val param = call.arguments as? Map<String, Any>
                    val tag = param?.get("tag") as? String ?: ""
                    val messageBytes = (param?.get("message") as? ByteArray) ?: byteArrayOf()
                    val signature = encryptionStrategy.sign(tag, messageBytes)
                    result.success(mapOf("status" to "success", "data" to signature))
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage, null)
                }
            }
            "verify" -> {
                try {
                    val param = call.arguments as? Map<String, Any>
                    val tag = param?.get("tag") as? String ?: ""
                    val signatureText = param?.get("signature") as? String ?: ""
                    val plainText = param?.get("plainText") as? String ?: ""
                    val isValid = encryptionStrategy.verify(tag, plainText, signatureText)
                    result.success(mapOf("status" to "success", "data" to isValid))
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage, null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
