package id.my.burganbank.flutter_shield

import java.security.KeyPair
import id.my.burganbank.flutter_shield.model.*

interface EncryptionStrategy {
    @Throws(Exception::class)
    fun generateKeyPair(accessControlParam: AccessControlParam): KeyPair

    @Throws(Exception::class)
    fun removeKey(tag: String): Boolean

    @Throws(Exception::class)
    fun isKeyCreated(tag: String): Boolean?

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
}