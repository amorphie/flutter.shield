package id.my.burganbank.flutter_shield

import id.my.burganbank.flutter_shield.model.AccessControlParam
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.annotation.RequiresApi
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.PublicKey
import java.security.Signature
import android.util.Base64
import javax.crypto.Cipher

class ModernEncryptionStrategy : EncryptionStrategy {
    private val KEYSTORE_PROVIDER = "AndroidKeyStore"

    @RequiresApi(Build.VERSION_CODES.M)
    override fun generateKeyPair(accessControlParam: AccessControlParam): KeyPair {
        val keyPairGenerator = KeyPairGenerator.getInstance("RSA", KEYSTORE_PROVIDER)

        val alias = accessControlParam.tag
        val parameterSpecBuilder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT or KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1)
            .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
            .setKeySize(2048)

        val parameterSpec = parameterSpecBuilder.build()
        keyPairGenerator.initialize(parameterSpec)
        val keyPair = keyPairGenerator.generateKeyPair()

        return keyPair
    }

    override fun removeKey(tag: String): Boolean {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        keyStore.deleteEntry(tag)
        return true
    }

    internal fun getSecKey(tag: String): KeyPair? {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        val privateKey = keyStore.getKey(tag, null) as PrivateKey
        val publicKey = keyStore.getCertificate(tag)?.publicKey
        return if (publicKey != null) KeyPair(publicKey, privateKey) else null
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

    @RequiresApi(Build.VERSION_CODES.O)
    override fun verify(tag: String, plainText: String, signatureText: String): Boolean {
        val publicKey = getPublicKeyFromKeyStore(tag)
        val signature = Signature.getInstance("SHA256withRSA")
        signature.initVerify(publicKey)
        signature.update(plainText.toByteArray())
        val signatureBytes = Base64.decode(signatureText, Base64.DEFAULT)
        return signature.verify(signatureBytes)
    }

    private fun getPublicKeyFromKeyStore(tag: String): PublicKey {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        return keyStore.getCertificate(tag).publicKey
    }

    private fun getPrivateKeyFromKeyStore(tag: String): PrivateKey {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        return keyStore.getKey(tag, null) as PrivateKey
    }
}
