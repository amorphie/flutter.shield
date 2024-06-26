library flutter_shield;

import 'dart:typed_data';

import 'package:flutter_shield/secure_enclave_base.dart';
import 'package:flutter_shield/src/models/access_control_model.dart';
import 'package:flutter_shield/src/models/result_model.dart';

import 'src/platform/secure_encalve_swift.dart';

export 'src/constants/access_control_option.dart';
export 'src/models/access_control_model.dart';
export 'src/models/result_model.dart';
export 'src/models/error_model.dart';

class SecureEnclave implements SecureEnclaveBase {
  
  /// decryption with secure enclave key pair
  @override
  Future<ResultModel<String?>> decrypt(
      {required String tag, required Uint8List message}) {
    return SecureEnclavePlatform.instance.decrypt(
      tag: tag,
      message: message
    );
  }

  /// encryption with secure enclave key pair
  @override
  Future<ResultModel<Uint8List?>> encrypt(
      { required String tag, required String message}) {
    return SecureEnclavePlatform.instance.encrypt(
      tag: tag,
      message: message
    );
  }

  /// Generetes a new private/public key pair
  @override
  Future<ResultModel<bool>> generateKeyPair(
      {required AccessControlModel accessControl}) {
    return SecureEnclavePlatform.instance
        .generateKeyPair(accessControl: accessControl);
  }

  /// get public key representation, this method will return Base64 encode
  /// you can share this public key to others device for sending encrypted data
  /// to your device
  @override
  Future<ResultModel<String?>> getPublicKey(String tag) {
    return SecureEnclavePlatform.instance.getPublicKey(tag);
  }

  /// remove key pair
  @override
  Future<ResultModel<bool>> removeKey(String tag) {
    return SecureEnclavePlatform.instance.removeKey(tag);
  }

  /// generate signature from data
  @override
  Future<ResultModel<String?>> sign(
      { required String tag, required Uint8List message}) {
    return SecureEnclavePlatform.instance.sign(
      tag: tag,
      message: message
    );
  }

  /// verify signature
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

  /// check status is tag available or not
  @override
  Future<ResultModel<bool?>> isKeyCreated(String tag) {
    return SecureEnclavePlatform.instance.isKeyCreated(tag);
  }
}
