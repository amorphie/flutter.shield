// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'error_model.dart';

part 'secure_enclave_log_data.g.dart';

@JsonSerializable(createFactory: false)
class SecureEnclaveLogData {
  late DateTime date;
  String method;
  dynamic args;
  dynamic result;
  String? tag;
  ErrorModel? error;

  SecureEnclaveLogData({
    required this.method,
    required this.args,
    required this.result,
    this.tag,
    this.error,
  }) {
    date = DateTime.now();
  }
  Map<String, dynamic> toJson() => _$SecureEnclaveLogDataToJson(this);

  @override
  String toString() {
    return 'SecureEnclave(${jsonEncode(toJson())}))';
  }
}
