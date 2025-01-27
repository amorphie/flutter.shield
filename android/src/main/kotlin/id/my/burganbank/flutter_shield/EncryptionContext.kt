package id.my.burganbank.flutter_shield

import android.content.Context

class EncryptionContext(private val apiLevel: Int) {
    companion object {
        fun create(apiLevel: Int, context: Context): EncryptionStrategy {
            val hasStrongBox = context.packageManager.hasSystemFeature("android.hardware.strongbox_keystore")
            return if (apiLevel >= 18 && hasStrongBox) {
                ModernEncryptionStrategy(context)
            } else {
                LegacyEncryptionStrategy(context)
            }
        }
    }
}
