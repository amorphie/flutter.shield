import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shield/src/models/secure_enclave_log_data.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../../secure_enclave_base.dart';
import '../models/access_control_model.dart';
import '../models/result_model.dart';

abstract class SecureEnclavePlatform extends PlatformInterface implements SecureEnclaveBase {
  /// Constructs a SecureEnclavePlatform.
  SecureEnclavePlatform() : super(token: _token);

  static final Object _token = Object();

  static SecureEnclavePlatform _instance = SecureEnclaveSwift();

  /// The default instance of [SecureEnclavePlatform] to use.
  ///
  /// Defaults to [MethodChannelSecureEnclave].
  static SecureEnclavePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SecureEnclavePlatform] when
  /// they register themselves.
  static set instance(SecureEnclavePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}

class SecureEnclaveSwift extends SecureEnclavePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_shield');
  @override
  Future<void> Function(SecureEnclaveLogData logData)? log;

  /// Store sever private key
  @override
  Future<ResultModel<bool>> storeServerPrivateKey({required String tag, required Uint8List privateKeyData}) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'storeServerPrivateKey',
      {"tag": tag, "privateKeyData": privateKeyData},
    );

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool? ?? false;
      },
    );

    // if (log != null) {
    //   await log!(
    //     SecureEnclaveLogData(
    //       method: 'storeServerPrivateKey',
    //       args: {"tag": tag, "privateKeyData": privateKeyData.length > 5 ? privateKeyData.getRange(0, 5) : []},
    //       result: resultModel.value,
    //       tag: tag,
    //       error: resultModel.error,
    //     ),
    //   );
    // }

    return resultModel;
  }

  @override
  Future<ResultModel<String?>> getServerKey({required String tag}) async {
    final result = await methodChannel.invokeMethod<dynamic>('getServerKey', {"tag": tag});

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as String?;
      },
    );

    // if (log != null) {
    //   await log!(
    //     SecureEnclaveLogData(
    //       method: 'getServerKey',
    //       args: {"tag": tag},
    //       result: resultModel.value,
    //       tag: tag,
    //       error: resultModel.error,
    //     ),
    //   );
    // }

    return resultModel;
  }

  /// Generetes a new private/public key pair
  @override
  Future<ResultModel<bool>> generateKeyPair({required AccessControlModel accessControl}) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'generateKeyPair',
      {
        "accessControl": accessControl.toJson(),
      },
    );

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool? ?? false;
      },
    );

    if (log != null) {
      await log!(
        SecureEnclaveLogData(
          method: 'generateKeyPair',
          args: {"accessControl": accessControl.toJson()},
          result: resultModel.value,
          tag: accessControl.tag,
          error: resultModel.error,
        ),
      );
    }

    return resultModel;
  }

  /// remove key pair
  @override
  Future<ResultModel<bool>> removeKey(String tag, String flag) async {
    final result = await methodChannel.invokeMethod<dynamic>('removeKey', {"tag": tag, "flag": flag});

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool? ?? false;
      },
    );

    if (log != null) {
      await log!(
        SecureEnclaveLogData(
          method: 'removeKey',
          args: {"tag": tag, "flag": flag},
          result: resultModel.value,
          tag: tag,
          error: resultModel.error,
        ),
      );
    }

    return resultModel;
  }

  /// get public key representation, this method will return Base64 encode
  /// you can share this public key to others device for sending encrypted data
  /// to your device
  @override
  Future<ResultModel<String?>> getPublicKey(String tag) async {
    final result = await methodChannel.invokeMethod<dynamic>('getPublicKey', {"tag": tag});

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as String?;
      },
    );

    if (log != null) {
      String maskedResult = resultModel.value ?? '';
      if (maskedResult.isNotEmpty && maskedResult.length > 20) {
        maskedResult = '${maskedResult.substring(0, 10)}...${maskedResult.substring(maskedResult.length - 10)}';
      }

      await log!(
        SecureEnclaveLogData(
          method: 'getPublicKey',
          args: {"tag": tag},
          result: maskedResult,
          tag: tag,
          error: resultModel.error,
        ),
      );
    }

    return resultModel;
  }

  /// encryption with secure enclave key pair
  @override
  Future<ResultModel<Uint8List?>> encrypt({required String tag, required String message}) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'encrypt',
      {"tag": tag, "message": message},
    );

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as Uint8List?;
      },
    );

    if (log != null) {
      await log!(
        SecureEnclaveLogData(
          method: 'encrypt',
          args: {"tag": tag, "message": message},
          result: resultModel.value,
          tag: tag,
          error: resultModel.error,
        ),
      );
    }

    return resultModel;
  }

  /// decryption with secure enclave key pair
  @override
  Future<ResultModel<String?>> decrypt({required String tag, required Uint8List message}) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'decrypt',
      {"tag": tag, "message": message},
    );

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as String?;
      },
    );

    if (log != null) {
      await log!(
        SecureEnclaveLogData(
          method: 'decrypt',
          args: {"tag": tag, "message": message},
          result: resultModel.value,
          tag: tag,
          error: resultModel.error,
        ),
      );
    }

    return resultModel;
  }

  /// check status is tag available or not
  @override
  Future<ResultModel<bool?>> isKeyCreated(String tag, String flag) async {
    final result = await methodChannel.invokeMethod<dynamic>('isKeyCreated', {"tag": tag, "flag": flag});

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool?;
      },
    );

    if (log != null) {
      await log!(
        SecureEnclaveLogData(
          method: 'isKeyCreated',
          args: {"tag": tag, "flag": flag},
          result: resultModel.value,
          tag: tag,
          error: resultModel.error,
        ),
      );
    }

    return resultModel;
  }

  /// generate signature from data
  @override
  Future<ResultModel<String?>> sign({required String tag, required Uint8List message}) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'sign',
      {"tag": tag, "message": message},
    );

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as String?;
      },
    );

    if (log != null) {
      await log!(
        SecureEnclaveLogData(
          method: 'sign',
          args: {"tag": tag, "message": message},
          result: resultModel.value,
          tag: tag,
          error: resultModel.error,
        ),
      );
    }

    return resultModel;
  }

  /// verify signature
  @override
  Future<ResultModel<bool?>> verify({required String tag, required String plainText, required String signature}) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'verify',
      {"tag": tag, "plainText": plainText, "signature": signature},
    );

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool?;
      },
    );

    if (log != null) {
      await log!(
        SecureEnclaveLogData(
          method: 'verify',
          args: {"tag": tag, "plainText": plainText, "signature": signature},
          result: resultModel.value,
          tag: tag,
          error: resultModel.error,
        ),
      );
    }

    return resultModel;
  }

  @override
  Future<ResultModel<String?>> getCertificate({required String tag}) async {
    final result = await methodChannel.invokeMethod<dynamic>('getCertificate', {"tag": tag});

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as String?;
      },
    );

    if (log != null) {
      String maskedResult = resultModel.value ?? '';
      if (maskedResult.isNotEmpty) {
        // Remove "-----BEGIN CERTIFICATE-----" and "-----END CERTIFICATE-----" parts
        maskedResult = maskedResult.replaceAll('-----BEGIN CERTIFICATE-----', '');
        maskedResult = maskedResult.replaceAll('-----END CERTIFICATE-----', '');
        maskedResult = maskedResult.trim();

        // Remove \n characters from beginning and end
        maskedResult = maskedResult.replaceAll(RegExp(r'^\n+'), '');
        maskedResult = maskedResult.replaceAll(RegExp(r'\n+$'), '');

        if (maskedResult.length > 20) {
          maskedResult = '${maskedResult.substring(0, 10)}...${maskedResult.substring(maskedResult.length - 10)}';
        }
      }

      await log!(
        SecureEnclaveLogData(
          method: 'getCertificate',
          args: {"tag": tag},
          result: maskedResult,
          tag: tag,
          error: resultModel.error,
        ),
      );
    }

    return resultModel;
  }

  @override
  Future<ResultModel<bool>> removeCertificate({required String tag}) async {
    final result = await methodChannel.invokeMethod<dynamic>('removeCertificate', {"tag": tag});

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool;
      },
    );

    if (log != null) {
      await log!(
        SecureEnclaveLogData(
          method: 'removeCertificate',
          args: {"tag": tag},
          result: resultModel.value,
          tag: tag,
          error: resultModel.error,
        ),
      );
    }

    return resultModel;
  }

  @override
  Future<ResultModel<bool>> storeCertificate({required String tag, required Uint8List certificateData}) async {
    final result =
        await methodChannel.invokeMethod<dynamic>('storeCertificate', {"tag": tag, "certificateData": certificateData});

    final resultModel = ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool;
      },
    );

    if (log != null) {
      await log!(
        SecureEnclaveLogData(
          method: 'storeCertificate',
          args: {"tag": tag, "certificateData": "MASKED_DATA!"},
          result: resultModel.value,
          tag: tag,
          error: resultModel.error,
        ),
      );
    }

    return resultModel;
  }

  @override
  Future<ResultModel<String?>> decryptWithAES({
    required Uint8List encryptedData,
    required Uint8List aesKey
  }) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'decryptWithAES',
      {
        "encryptedData": encryptedData,
        "aesKey": aesKey
      },
    );

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as String?;
      },
    );
  }
}
