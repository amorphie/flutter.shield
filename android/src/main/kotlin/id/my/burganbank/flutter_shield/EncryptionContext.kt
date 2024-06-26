package id.my.burganbank.flutter_shield

import android.content.Context

class EncryptionContext(private val apiLevel: Int) {
    companion object {
        fun create(apiLevel: Int, context: Context): EncryptionStrategy {
            return if (apiLevel >= 18) {
                ModernEncryptionStrategy()
            } else {
                LegacyEncryptionStrategy(context)
            }
        }
    }
}
