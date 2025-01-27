import 'dart:typed_data';

import 'src/models/access_control_model.dart';
import 'src/models/result_model.dart';

abstract class SecureEnclaveBase {
  /// Stores the certificate securely with a given tag.
  ///
  /// The `tag` parameter is used to label or identify the certificate.
  /// The `certificateData` parameter contains the certificate in `Uint8List` format, which will be securely stored.
  ///
  /// Returns a [ResultModel] wrapping a `bool` value, indicating whether the storage operation was successful.
  Future<ResultModel<bool>> storeCertificate({
    required String tag,
    required Uint8List certificateData
  });

  /// Retrieves the certificate (PEM) stored with the specified tag.
  ///
  /// The `tag` parameter is used to locate and retrieve the certificate.
  /// If the certificate is found, it is returned as `Uint8List` wrapped in a [ResultModel].
  /// If the certificate is not found, the result will contain `null`.
  ///
  /// Returns a [ResultModel] containing the certificate data or `null` if not found.
  Future<ResultModel<String?>> getCertificate({
    required String tag
  });

  /// Removes the certificate stored with the specified tag.
  ///
  /// The `tag` parameter is used to locate the certificate to be removed.
  /// The operation returns a `bool` value wrapped in [ResultModel], indicating whether the certificate was successfully removed.
  ///
  /// Returns a [ResultModel] with a `bool` value: `true` if removal succeeded, `false` otherwise.
  Future<ResultModel<bool>> removeCertificate({
    required String tag
  });

  /// Stores the private key received from the server securely.
  ///
  /// The `tag` parameter is used to label or identify the private key.
  /// The `privateKeyData` parameter contains the private key in `Uint8List` format to be securely stored.
  /// The optional `context` parameter holds dynamic data specific to the environment (i.e., iOS, Android, or Web),
  /// allowing for platform-based variations.
  ///
  /// Returns a [ResultModel] wrapping a `bool` value, indicating success or failure of the storage operation.
  Future<ResultModel<bool>> storeServerPrivateKey({
    required String tag,
    required Uint8List privateKeyData
  });

  /// Retrieves the private key (PEM) for the specified server.
  ///
  /// The `tag` parameter is used to identify the key.
  /// Returns a [ResultModel] containing the public key as a `String` if found,
  /// or `null` if no key is associated with the given tag.
  Future<ResultModel<String?>> getServerKey({
    required String tag,
  });
  
  /// Creates keys on the client side
  ///
  /// The `accessControl` parameter contains key related settings
  ///
  /// Returns a [ResultModel] wrapping a `bool` value, indicating success or failure of the key removal.
  Future<ResultModel<bool>> generateKeyPair({
    required AccessControlModel accessControl,
  });
  
  /// Removes the generated keys based on the provided tag and flag.
  ///
  /// The `tag` parameter represents the key label or identifier.
  /// The `flag` parameter indicates whether the operation is for the server or client side:
  ///   - `C`: Client
  ///   - `S`: Server
  ///
  /// Returns a [ResultModel] wrapping a `bool` value, indicating success or failure of the key removal.
  Future<ResultModel<bool>> removeKey(String tag, String flag);

  /// Retrieves the public key for the specified client.
  ///
  /// The `tag` parameter is used to identify the key.
  /// Returns a [ResultModel] containing the public key as a `String` if found,
  /// or `null` if no key is associated with the given tag.
  Future<ResultModel<String?>> getPublicKey(String tag);
  
  /// Checks if a key has been created based on the specified tag and flag.
  ///
  /// The `tag` parameter represents the key identifier.
  /// The `flag` parameter specifies if the key is for the server or client side:
  ///   - `C`: Client
  ///   - `S`: Server
  ///
  /// Returns a [ResultModel] containing a `bool` value, where `true` indicates the key exists,
  /// `false` indicates it does not, or `null` if an error occurs.
  Future<ResultModel<bool?>> isKeyCreated(String tag, String flag);
  
  
  /// Encrypts the given message on the client side.
  ///
  /// The `tag` parameter is used to identify the encryption key.
  /// The `message` parameter is the plain text to be encrypted.
  ///
  /// Returns a [ResultModel] containing the encrypted message as a `Uint8List`,
  /// or `null` if encryption fails.
  Future<ResultModel<Uint8List?>> encrypt({
     required String tag,
     required String message
  });

  /// Decrypts the given message on the server side.
  ///
  /// The `tag` parameter is used to identify the decryption key.
  /// The `message` parameter is the encrypted data to be decrypted.
  ///
  /// Returns a [ResultModel] containing the decrypted plain text as a `String`,
  /// or `null` if decryption fails.
  Future<ResultModel<String?>> decrypt({
    required String tag,
    required Uint8List message
  });

  /// Signs the given message on the client side.
  ///
  /// The `tag` parameter is used to identify the signing key.
  /// The `message` parameter is the data to be signed.
  ///
  /// Returns a [ResultModel] containing the generated signature as a `String`,
  /// or `null` if signing fails.
  Future<ResultModel<String?>> sign({
    required String tag,
    required Uint8List message
  });

  /// Verifies the given signature against the plain text message on the client side.
  ///
  /// The `tag` parameter is used to identify the verification key.
  /// The `plainText` parameter is the original message.
  /// The `signature` parameter is the signature to verify.
  ///
  /// Returns a [ResultModel] containing a `bool` value indicating if the signature is valid (`true`)
  /// or invalid (`false`), or `null` if verification fails.
  Future<ResultModel<bool?>> verify({
    required String tag,
    required String plainText,
    required String signature
  });
}
