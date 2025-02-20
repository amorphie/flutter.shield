import 'dart:convert';
import 'package:crypto/crypto.dart';

class CanonicalJsonSerializer {
  static String serialize(Object? obj) {
    return _serializeObject(obj);
  }

  static String hashData(String jsonData) {
     final dataObject = json.decode(jsonData);
      final dataRawSerialize = _serializeObject(dataObject);
      final digest = sha256.convert(utf8.encode(dataRawSerialize));
      return digest.toString();
    }

  static String _serializeObject(Object? obj) {
    if (obj == null) {
      return 'null';
    } else if (obj is bool) {
      return obj ? 'true' : 'false';
    } else if (obj is String) {
      return obj;
    } else if (obj is num) {
      return obj.toString();
    } else if (obj is List) {
      return _serializeArray(obj);
    } else if (obj is Map<String, dynamic>) {
      return _serializeDictionary(obj);
    } else {
      throw UnsupportedError('Unsupported data type');
    }
  }

  static String _serializeArray(List array) {
    List<String> items = array.map((item) => _serializeObject(item)).toList();
    return '[${items.join(',')}]';
  }

  static String _serializeDictionary(Map<String, dynamic> dictionary) {
    var sortedKeys = dictionary.keys.toList()..sort();
    List<String> entries = [];

    for (var key in sortedKeys) {
      var value = dictionary[key];
      entries.add('$key:${_serializeObject(value)}');
    }

    return '{${entries.join(',')}}';
  }
}