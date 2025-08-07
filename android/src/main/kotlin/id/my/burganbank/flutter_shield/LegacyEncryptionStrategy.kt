package id.my.burganbank.flutter_shield

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.annotation.RequiresApi
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import id.my.burganbank.flutter_shield.model.AccessControlParam
import java.security.*
import java.security.KeyStore.*
import java.security.spec.ECGenParameterSpec
import java.security.spec.PKCS8EncodedKeySpec
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec
import javax.crypto.spec.IvParameterSpec

class LegacyEncryptionStrategy(private val context: Context) : EncryptionStrategy {

    private val sharedPreferences: SharedPreferences
    private val editor: SharedPreferences.Editor

    init {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        sharedPreferences = EncryptedSharedPreferences.create(
            context,
            "shield_secret_prefs",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )

        editor = sharedPreferences.edit();
    }

    fun getServerPrivateKey(tag: String): PrivateKey? {
        return try {
            val privateKeyString = sharedPreferences.getString(tag + "_ss", "") ?: return null
            val privateKeyData = Base64.decode(privateKeyString, Base64.NO_WRAP)

            val keyFactory = KeyFactory.getInstance("RSA")
            val pkcs8KeySpec = PKCS8EncodedKeySpec(privateKeyData)
            val privateKey = keyFactory.generatePrivate(pkcs8KeySpec)
            privateKey
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun String.chunked(size: Int): List<String> {
        val chunks = mutableListOf<String>()
        var i = 0
        while (i < this.length) {
            chunks.add(this.substring(i, Math.min(i + size, this.length)))
            i += size
        }
        return chunks
    }

    override fun storeCertificate(
        tag: String,
        certificateData: ByteArray
    ): Boolean {
        return try {
            removeCertificate(tag)
            val pemString = String(certificateData)
            editor.putString(tag + "_cert", pemString).apply()

            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    override fun getCertificate(tag: String): String? {
        return try {
            val pemString = sharedPreferences.getString("${tag}_cert", null) ?: return null
            pemString
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    override fun removeCertificate(tag: String): Boolean {
        if (sharedPreferences.contains(tag + "_cert")) {
            sharedPreferences.edit().remove(tag + "_cert").apply()
        }
        return true
    }

    override fun storeServerPrivateKey(tag: String, privateKeyData: ByteArray): Boolean {
       return try {
           removeKey(tag, "S")
           val pemString = String(privateKeyData)

           val base64Encoded = pemString
               .replace("-----BEGIN PRIVATE KEY-----", "")
               .replace("-----END PRIVATE KEY-----", "")
               .replace("-----BEGIN RSA PRIVATE KEY-----", "")
               .replace("-----END RSA PRIVATE KEY-----", "")
               .replace("\n", "")

           val derData = Base64.decode(base64Encoded, Base64.NO_WRAP)

           val privateKeyString = Base64.encodeToString(derData, Base64.NO_WRAP)
           editor.putString(tag + "_ss", privateKeyString).apply()

            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    override fun getServerKey(tag: String): String? {
        return try {
            val privateKeyString = sharedPreferences.getString("${tag}_ss", null) ?: return null
            val privateKeyData = Base64.decode(privateKeyString, Base64.NO_WRAP)

            val keyFactory = KeyFactory.getInstance("RSA")
            val pkcs8KeySpec = PKCS8EncodedKeySpec(privateKeyData)
            val privateKey = keyFactory.generatePrivate(pkcs8KeySpec)

            val base64EncodedKey = Base64.encodeToString(privateKeyData, Base64.NO_WRAP)

            val pemKey = "-----BEGIN RSA PRIVATE KEY-----\n" +
                    base64EncodedKey.chunked(64).joinToString("\n") +
                    "\n-----END RSA PRIVATE KEY-----"

            pemKey
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    override fun generateKeyPair(accessControlParam: AccessControlParam): KeyPair {
        removeKey(accessControlParam.tag, "C")
        val keyPairGenerator = KeyPairGenerator.getInstance("EC", "AndroidKeyStore")
        val parameterSpec = KeyGenParameterSpec.Builder(
            accessControlParam.tag,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .build()

        keyPairGenerator.initialize(parameterSpec)
        return keyPairGenerator.generateKeyPair()
    }

    override fun removeKey(tag: String, flag: String): Boolean {
        if(flag == "C"){
            val keyStore = getInstance("AndroidKeyStore")
            keyStore.load(null)
            keyStore.deleteEntry(tag)
            return true
        }else{
            var tagValue = tag
            if (flag == "S") {
                tagValue += "_ss"
            }
            if (sharedPreferences.contains(tagValue)) {
                sharedPreferences.edit().remove(tagValue).apply()
            }
            return true
        }
    }

    override fun isKeyCreated(tag: String, flag: String): Boolean? {
        if(flag == "C"){
            val keyStore = getInstance("AndroidKeyStore")
                    keyStore.load(null)
            return keyStore.containsAlias(tag)
        } else {
            var tagValue = tag
            if (flag == "S") {
                tagValue += "_ss"
            }
            return  sharedPreferences.contains(tagValue)
        }        
    }

    override fun getPublicKey(tag: String): String? {
        val keyStore = getInstance("AndroidKeyStore")
        keyStore.load(null)
        val publicKey = keyStore.getCertificate(tag)?.publicKey
        return publicKey?.let { Base64.encodeToString(it.encoded, Base64.NO_WRAP) }
    }

    override fun encrypt(message: String, tag: String): ByteArray? {
        val keyStore = getInstance("AndroidKeyStore")
        keyStore.load(null)
        val publicKey = keyStore.getCertificate(tag)?.publicKey ?: return null

        val cipher = Cipher.getInstance("ECIES")
        cipher.init(Cipher.ENCRYPT_MODE, publicKey)
        return cipher.doFinal(message.toByteArray())
    }

    override fun decrypt(message: ByteArray, tag: String): String? {
        val privateKey = getServerPrivateKey(tag) ?: return null
        val cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding") //RSA/ECB/PKCS1Padding
        cipher.init(Cipher.DECRYPT_MODE, privateKey)
        val decryptedBytes = cipher.doFinal(message)
        // Server returns raw AES key bytes, convert to base64 for consistent handling
        return Base64.encodeToString(decryptedBytes, Base64.NO_WRAP)
    }

    override fun sign(tag: String, message: ByteArray): String? {
        val keyStore = getInstance("AndroidKeyStore")
        keyStore.load(null)
        val privateKey = keyStore.getKey(tag, null) as? PrivateKey ?: return null

        val signature = Signature.getInstance("SHA256withECDSA")
        signature.initSign(privateKey)
        signature.update(message)
        return Base64.encodeToString(signature.sign(), Base64.NO_WRAP)
    }

    override fun verify(tag: String, plainText: String, signature: String): Boolean {
        val keyStore = getInstance("AndroidKeyStore")
        keyStore.load(null)
        val publicKey = keyStore.getCertificate(tag)?.publicKey ?: return false

        val signatureInstance = Signature.getInstance("SHA256withECDSA")
        signatureInstance.initVerify(publicKey)
        signatureInstance.update(plainText.toByteArray())
        return signatureInstance.verify(Base64.decode(signature, Base64.NO_WRAP))
    }

    override fun decryptWithAES(encryptedData: ByteArray, aesKey: ByteArray): String? {
        return try {
            // Server updated: IV is now prepended to encrypted data
            // Format: [IV (16 bytes)][Encrypted Data (remaining bytes)]
            
            if (encryptedData.size < 16) {
                throw IllegalArgumentException("Encrypted data too short - must contain at least 16 bytes for IV")
            }
            
            val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding")
            val secretKeySpec = SecretKeySpec(aesKey, "AES")
            
            // Extract IV from first 16 bytes
            val iv = encryptedData.sliceArray(0..15)
            val actualEncryptedData = encryptedData.sliceArray(16 until encryptedData.size)
            
            val ivParameterSpec = IvParameterSpec(iv)
            cipher.init(Cipher.DECRYPT_MODE, secretKeySpec, ivParameterSpec)
            
            val decryptedData = cipher.doFinal(actualEncryptedData)
            String(decryptedData, Charsets.UTF_8)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
