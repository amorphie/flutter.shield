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
    final result = await sendMessage(
      'storeServerPrivateKey',
      {"tag": tag, "privateKeyData": privateKeyData},
    );

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool? ?? false;
      },
    );
  }

  @override
  Future<ResultModel<String?>> getServerKey({required String tag}) async {
    final result = await sendMessage('getServerKey', {"tag": tag});

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as String?;
      },
    );
  }

  /// Generetes a new private/public key pair
  @override
  Future<ResultModel<bool>> generateKeyPair({required AccessControlModel accessControl}) async {
    final result = await sendMessage(
      'generateKeyPair',
      {
        "accessControl": accessControl.toJson(),
      },
    );

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool? ?? false;
      },
    );
  }

  /// remove key pair
  @override
  Future<ResultModel<bool>> removeKey(String tag, String flag) async {
    final result = await sendMessage('removeKey', {"tag": tag, "flag": flag});

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool? ?? false;
      },
    );
  }

  /// get public key representation, this method will return Base64 encode
  /// you can share this public key to others device for sending encrypted data
  /// to your device
  @override
  Future<ResultModel<String?>> getPublicKey(String tag) async {
    final result = await sendMessage('getPublicKey', {"tag": tag});

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as String?;
      },
    );
  }

  /// encryption with secure enclave key pair
  @override
  Future<ResultModel<Uint8List?>> encrypt({required String tag, required String message}) async {
    final result = await sendMessage(
      'encrypt',
      {"tag": tag, "message": message},
    );

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as Uint8List?;
      },
    );
  }

  /// decryption with secure enclave key pair
  @override
  Future<ResultModel<String?>> decrypt({required String tag, required Uint8List message}) async {
    final result = await sendMessage(
      'decrypt',
      {"tag": tag, "message": message},
    );

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as String?;
      },
    );
  }

  /// check status is tag available or not
  @override
  Future<ResultModel<bool?>> isKeyCreated(String tag, String flag) async {
    final result = await sendMessage('isKeyCreated', {"tag": tag, "flag": flag});

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool?;
      },
    );
  }

  /// generate signature from data
  @override
  Future<ResultModel<String?>> sign({required String tag, required Uint8List message}) async {
    final result = await sendMessage(
      'sign',
      {"tag": tag, "message": message},
    );

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as String?;
      },
    );
  }

  /// verify signature
  @override
  Future<ResultModel<bool?>> verify({required String tag, required String plainText, required String signature}) async {
    final result = await sendMessage(
      'verify',
      {"tag": tag, "plainText": plainText, "signature": signature},
    );

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool?;
      },
    );
  }

  @override
  Future<ResultModel<String?>> getCertificate({required String tag}) async {
    final result = await sendMessage('getCertificate', {"tag": tag});

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as String?;
      },
    );
  }

  @override
  Future<ResultModel<bool>> removeCertificate({required String tag}) async {
    final result = await sendMessage('removeCertificate', {"tag": tag});

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool;
      },
    );
  }

  @override
  Future<ResultModel<bool>> storeCertificate({required String tag, required Uint8List certificateData}) async {
    final result = await sendMessage('storeCertificate', {"tag": tag, "certificateData": certificateData});

    return ResultModel.fromMap(
      map: Map<String, dynamic>.from(result),
      decoder: (rawData) {
        return rawData as bool;
      },
    );
  }

  Future<dynamic> sendMessage(String method, dynamic arguments) async {
    final result = await methodChannel.invokeMethod<dynamic>(method, arguments);

    if (log != null) {
      await log!(
        SecureEnclaveLogData(
          method: method,
          args: arguments,
          result: result,
        ),
      );
    }

    return result;
  }
}
