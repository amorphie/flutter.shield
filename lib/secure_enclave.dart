library flutter_shield;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_shield/secure_enclave_base.dart';
import 'package:flutter_shield/src/models/access_control_model.dart';
import 'package:flutter_shield/src/models/result_model.dart';

import 'CanonicalJsonSerializer.dart';
import 'src/platform/secure_encalve_swift.dart';

export 'src/constants/access_control_option.dart';
export 'src/models/access_control_model.dart';
export 'src/models/result_model.dart';
export 'src/models/error_model.dart';

class SecureEnclave implements SecureEnclaveBase {
  
  @override
  Future<ResultModel<String?>> decrypt(
      {required String tag, required Uint8List message}) {
    return SecureEnclavePlatform.instance.decrypt(
      tag: tag,
      message: message
    );
  }

  @override
  Future<ResultModel<Uint8List?>> encrypt(
      { required String tag, required String message}) {
    return SecureEnclavePlatform.instance.encrypt(
      tag: tag,
      message: message
    );
  }

  @override
  Future<ResultModel<bool>> storeServerPrivateKey(
    { required String tag, required Uint8List privateKeyData }) {
    return SecureEnclavePlatform.instance
    .storeServerPrivateKey(tag: tag, privateKeyData: privateKeyData);
  }

  @override
  Future<ResultModel<String?>> getServerKey(
    { required String tag }) {
    return SecureEnclavePlatform.instance
      .getServerKey(tag: tag);
  }

  @override
  Future<ResultModel<bool>> generateKeyPair(
      {required AccessControlModel accessControl}) {
    return SecureEnclavePlatform.instance
        .generateKeyPair(accessControl: accessControl);
  }

  @override
  Future<ResultModel<String?>> getPublicKey(String tag) {
    return SecureEnclavePlatform.instance.getPublicKey(tag);
  }

  @override
  Future<ResultModel<bool>> removeKey(String tag, String flag) {
    return SecureEnclavePlatform.instance.removeKey(tag, flag);
  }

  @override
  Future<ResultModel<String?>> sign(
      { required String tag, required Uint8List message}) {
      final String hashString = CanonicalJsonSerializer.hashData(jsonEncode(utf8.decode(message)));
       final Uint8List hashBytes = Uint8List.fromList(utf8.encode(hashString));
      return SecureEnclavePlatform.instance.sign(
        tag: tag,
        message: hashBytes
      );

      // final String? base64Result = result.value != null ? base64Encode(utf8.encode(result.toString())) : null;

      // return ResultModel.fromMap(
      //   map: Map<String, dynamic>.from({"data": base64Result}),
      //   decoder: (rawData) {
      //     return rawData as String?;
      //   },
      // );
  }

  @override
  Future<ResultModel<bool?>> verify(
      {required String tag,
      required String plainText,
      required String signature}) {
    return SecureEnclavePlatform.instance.verify(
      tag: tag,
      plainText: plainText,
      signature: signature
    );
  }

  @override
  Future<ResultModel<bool?>> isKeyCreated(String tag, String flag) {
    return SecureEnclavePlatform.instance.isKeyCreated(tag, flag);
  }
  
  @override
  Future<ResultModel<String?>> getCertificate({required String tag}) {
    return SecureEnclavePlatform.instance.getCertificate(tag: tag);
  }
  
  @override
  Future<ResultModel<bool>> removeCertificate({required String tag}) {
   return SecureEnclavePlatform.instance.removeCertificate(tag: tag);
  }
  
  @override
  Future<ResultModel<bool>> storeCertificate({required String tag, required Uint8List certificateData}) {
    return SecureEnclavePlatform.instance.storeCertificate(tag: tag, certificateData: certificateData);
  }
}
