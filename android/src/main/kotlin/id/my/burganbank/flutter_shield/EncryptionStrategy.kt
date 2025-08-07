package id.my.burganbank.flutter_shield

import java.security.KeyPair
import android.content.Context
import id.my.burganbank.flutter_shield.model.*

interface EncryptionStrategy {

    @Throws(Exception::class)
    fun storeCertificate(tag: String, certificateData: ByteArray): Boolean

    @Throws(Exception::class)
    fun getCertificate(tag: String): String?

    fun removeCertificate(tag: String): Boolean
    
    @Throws(Exception::class)
    fun storeServerPrivateKey(tag: String, privateKeyData: ByteArray): Boolean

    @Throws(Exception::class)
    fun getServerKey(tag: String): String?

    @Throws(Exception::class)
    fun generateKeyPair(accessControlParam: AccessControlParam): KeyPair

    fun removeKey(tag: String, flag: String): Boolean

    @Throws(Exception::class)
    fun isKeyCreated(tag: String, flag: String): Boolean?

    @Throws(Exception::class)
    fun getPublicKey(tag: String): String?

    @Throws(Exception::class)
    fun encrypt(message: String, tag: String): ByteArray?

    @Throws(Exception::class)
    fun decrypt(message: ByteArray, tag: String): String?

    @Throws(Exception::class)
    fun sign(tag: String, message: ByteArray): String?

    @Throws(Exception::class)
    fun verify(tag: String, plainText: String, signature: String): Boolean

    @Throws(Exception::class)
    fun decryptWithAES(encryptedData: ByteArray, aesKey: ByteArray): String?
}