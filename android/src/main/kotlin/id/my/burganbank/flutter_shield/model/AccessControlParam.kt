package id.my.burganbank.flutter_shield.model

import java.util.*

enum class SecAccessControlCreateFlags {
    DEVICE_PASSCODE,
    BIOMETRY_ANY,
    BIOMETRY_CURRENT_SET,
    USER_PRESENCE,
    PRIVATE_KEY_USAGE,
    APPLICATION_PASSWORD,
    OR,
    AND
}

class AccessControlParam(value: Map<String, Any?>) {
    val tag: String = value["tag"] as String
    var option: EnumSet<SecAccessControlCreateFlags> = EnumSet.noneOf(SecAccessControlCreateFlags::class.java)

    init {
        println(value)
        buildOption(value["options"] as List<String>)
    }

    private fun buildOption(optionsParam: List<String>) {
        for (opt in optionsParam) {
            when (opt) {
                "devicePasscode" -> option.add(SecAccessControlCreateFlags.DEVICE_PASSCODE)
                "biometryAny" -> option.add(SecAccessControlCreateFlags.BIOMETRY_ANY)
                "biometryCurrentSet" -> option.add(SecAccessControlCreateFlags.BIOMETRY_CURRENT_SET)
                "userPresence" -> option.add(SecAccessControlCreateFlags.USER_PRESENCE)
                "privateKeyUsage" -> option.add(SecAccessControlCreateFlags.PRIVATE_KEY_USAGE)
                "applicationPassword" -> option.add(SecAccessControlCreateFlags.APPLICATION_PASSWORD)
                "or" -> option.add(SecAccessControlCreateFlags.OR)
                "and" -> option.add(SecAccessControlCreateFlags.AND)
                else -> {
                    // No-op, ignore unknown options
                }
            }
        }
    }
}