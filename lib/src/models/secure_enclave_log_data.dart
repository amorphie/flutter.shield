import 'package:json_annotation/json_annotation.dart';

part 'secure_enclave_log_data.g.dart';

@JsonSerializable(createFactory: false)
class SecureEnclaveLogData {
  late DateTime date;
  String method;
  dynamic args;
  dynamic result;

  SecureEnclaveLogData({
    required this.method,
    required this.args,
    required this.result,
  }) {
    date = DateTime.now();
  }
  Map<String, dynamic> toJson() => _$SecureEnclaveLogDataToJson(this);
}
