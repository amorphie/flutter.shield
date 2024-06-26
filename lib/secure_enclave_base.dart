import 'dart:typed_data';

import 'src/models/access_control_model.dart';
import 'src/models/result_model.dart';

abstract class SecureEnclaveBase {
  Future<ResultModel<bool>> generateKeyPair({
    required AccessControlModel accessControl,
  });

  Future<ResultModel<bool>> removeKey(String tag);

  Future<ResultModel<String?>> getPublicKey(String tag);

  Future<ResultModel<bool?>> isKeyCreated(String tag);

  Future<ResultModel<Uint8List?>> encrypt({
     required String tag,
    required String message
  });

  Future<ResultModel<String?>> decrypt({
    required String tag,
    required Uint8List message
  });

  Future<ResultModel<String?>> sign({
    required String tag,
    required Uint8List message
  });

  Future<ResultModel<bool?>> verify({
    required String tag,
    required String plainText,
    required String signature
  });
}

//
