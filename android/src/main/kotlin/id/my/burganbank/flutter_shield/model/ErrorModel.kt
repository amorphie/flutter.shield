package id.my.burganbank.flutter_shield.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
class ErrorModel(val code: Int, val desc: String) : BaseModel, Parcelable {
    constructor(error: Throwable) : this(
        if (error is CustomError) 0 else (error as? Exception)?.let { it.javaClass.simpleName.hashCode() } ?: 0,
        error.localizedMessage ?: ""
    )

    override fun build(): Map<String, Any?> {
        return mapOf(
            "code" to code,
            "desc" to desc
        )
    }
}

sealed class CustomError : Throwable(), Parcelable {
    abstract fun get(): String

    @Parcelize
    data class RuntimeError(val desc: String) : CustomError() {
        override fun get() = desc
    }
}

fun CustomError.localizedDescription(): String {
    return when (this) {
        is CustomError.RuntimeError -> desc
    }
}
