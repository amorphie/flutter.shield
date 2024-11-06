package id.my.burganbank.flutter_shield

import android.content.Context
import android.util.Base64
import id.my.burganbank.flutter_shield.model.AccessControlParam
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.PublicKey
import java.security.Signature
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.X509EncodedKeySpec
import javax.crypto.Cipher

class LegacyEncryptionStrategy(private val context: Context) : EncryptionStrategy {
    private val KEYSTORE_PROVIDER = "BurganKeyStore"
    private lateinit var keyPair: KeyPair
    private val publicKeyStorageKey = "brgnPubKey_";
    private val privateKeyStorageKey = "brgnPvtKey_";

    override fun storeServerPrivateKey(tag: String, privateKeyData: ByteArray): Boolean {
       return try {
            // Convert the byte array to a PrivateKey object
            val keyFactory = KeyFactory.getInstance("RSA")
            val privateKeySpec = PKCS8EncodedKeySpec(privateKeyData)
            val privateKey = keyFactory.generatePrivate(privateKeySpec)

            // Store the private key in shared preferences
            val sharedPreferences = context.getSharedPreferences(KEYSTORE_PROVIDER, Context.MODE_PRIVATE)
            val editor = sharedPreferences.edit()
            editor.putString(privateKeyStorageKey + tag + "_ss", Base64.encodeToString(privateKey.encoded, Base64.DEFAULT))
            editor.apply()

            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    override fun generateKeyPair(accessControlParam: AccessControlParam): KeyPair {
         val keyGen = KeyPairGenerator.getInstance("RSA")
        keyGen.initialize(2048)
        keyPair = keyGen.generateKeyPair()
        storeKeyPair(accessControlParam.tag, keyPair)
        return keyPair
    }

    override fun removeKey(tag: String): Boolean {
        val sharedPreferences = context.getSharedPreferences(KEYSTORE_PROVIDER, Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()
        editor.remove(publicKeyStorageKey + tag)
        editor.remove(privateKeyStorageKey + tag)
        editor.apply()
        return true
    }

    internal fun getSecKey(tag: String): KeyPair? {
        val sharedPreferences = context.getSharedPreferences(KEYSTORE_PROVIDER, Context.MODE_PRIVATE)
        val publicKeyString = sharedPreferences.getString(publicKeyStorageKey + tag, null)
        val privateKeyString = sharedPreferences.getString(privateKeyStorageKey + tag, null)

        if (publicKeyString != null && privateKeyString != null) {
            val publicKeyBytes = Base64.decode(publicKeyString, Base64.DEFAULT)
            val privateKeyBytes = Base64.decode(privateKeyString, Base64.DEFAULT)

            val keyFactory = KeyFactory.getInstance("RSA")
            val publicKeySpec = X509EncodedKeySpec(publicKeyBytes)
            val privateKeySpec = PKCS8EncodedKeySpec(privateKeyBytes)

            val publicKey = keyFactory.generatePublic(publicKeySpec)
            val privateKey = keyFactory.generatePrivate(privateKeySpec)

            return KeyPair(publicKey, privateKey)
        }
        return null
    }

    override fun isKeyCreated(tag: String): Boolean? {
        val secKey = getSecKey(tag)
        return secKey != null
    }

    override fun getPublicKey(tag: String): String? {
        val publicKey = getPublicKeyFromKeyStore(tag)
        return Base64.encodeToString(publicKey.encoded, Base64.DEFAULT)
    }

    override fun encrypt(message: String, tag: String): ByteArray? {
         val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
        cipher.init(Cipher.ENCRYPT_MODE, getPublicKeyFromKeyStore(tag))
        val encryptedBytes = cipher.doFinal(message.toByteArray())
        return encryptedBytes;
    }

    override fun decrypt(message: ByteArray, tag: String): String? {
        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
        cipher.init(Cipher.DECRYPT_MODE, getPrivateKeyFromKeyStore(tag))
        val decryptedBytes = cipher.doFinal(message)
        return String(decryptedBytes)
    }

    override fun sign(tag: String, message: ByteArray): String? {
        val privateKey = getPrivateKeyFromKeyStore(tag)
        val signatureInstance = Signature.getInstance("SHA256withRSA")
        signatureInstance.initSign(privateKey)
        signatureInstance.update(message)
        val signatureBytes = signatureInstance.sign()
        return Base64.encodeToString(signatureBytes, Base64.DEFAULT)
    }

    override fun verify(tag: String, plainText: String, signature: String): Boolean {
        val publicKey = getPublicKeyFromKeyStore(tag)
        val signatureInstance = Signature.getInstance("SHA256withRSA")
        signatureInstance.initVerify(publicKey)
        signatureInstance.update(plainText.toByteArray())
        val signatureBytes = Base64.decode(signature, Base64.DEFAULT)
        return signatureInstance.verify(signatureBytes)
    }

    private fun getPublicKeyFromKeyStore(tag: String): PublicKey {
        val sharedPreferences = context.getSharedPreferences(KEYSTORE_PROVIDER, Context.MODE_PRIVATE)
        val publicKeyString = sharedPreferences.getString(publicKeyStorageKey + tag, null)
        val keyBytes = Base64.decode(publicKeyString, Base64.DEFAULT)
        val keySpec = java.security.spec.X509EncodedKeySpec(keyBytes)
        return KeyFactory.getInstance("RSA").generatePublic(keySpec)
    }

    private fun getPrivateKeyFromKeyStore(tag: String): PrivateKey {
        val sharedPreferences = context.getSharedPreferences(KEYSTORE_PROVIDER, Context.MODE_PRIVATE)
        val privateKeyString = sharedPreferences.getString(privateKeyStorageKey + tag, null)
        val keyBytes = Base64.decode(privateKeyString, Base64.DEFAULT)
        val keySpec = java.security.spec.PKCS8EncodedKeySpec(keyBytes)
        return KeyFactory.getInstance("RSA").generatePrivate(keySpec)
    }

    private fun storeKeyPair(tag: String, keyPair: KeyPair) {
        val sharedPreferences = context.getSharedPreferences(KEYSTORE_PROVIDER, Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()
        editor.putString(publicKeyStorageKey + tag, Base64.encodeToString(keyPair.public.encoded, Base64.DEFAULT))
        editor.putString(privateKeyStorageKey + tag, Base64.encodeToString(keyPair.private.encoded, Base64.DEFAULT))
        editor.apply()
    }

}
