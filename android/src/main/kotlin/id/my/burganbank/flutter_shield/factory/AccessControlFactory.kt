package id.my.burganbank.flutter_shield.factory

import id.my.burganbank.flutter_shield.model.AccessControlParam

class AccessControlFactory(private val value: Map<String, Any?>) {

    fun build(): AccessControlParam {
        return AccessControlParam(value)
    }
}
