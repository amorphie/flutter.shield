package id.my.burganbank.flutter_shield.model

class ResultModel(val error: ErrorModel?, val data: Any?) : BaseModel {
    override fun build(): Map<String, Any?> {
        return mapOf(
            "error" to error?.build(),
            "data" to data
        )
    }
}

fun resultSuccess(data: Any?): Map<String, Any?> {
    val result = ResultModel(null, data)
    return result.build()
}

fun resultError(error: Throwable): Map<String, Any?> {
    val result = ResultModel(ErrorModel(error), null)
    return result.build()
}
