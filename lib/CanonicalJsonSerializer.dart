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

  static String _escapeString(String input) {
    return jsonEncode(input).replaceAll('"', ''); // sadece escape'li halini döner
  }

  static int _asciiComparator(String a, String b) {
    final aBytes = ascii.encode(a);
    final bBytes = ascii.encode(b);
    final len = aBytes.length < bBytes.length ? aBytes.length : bBytes.length;

    for (var i = 0; i < len; i++) {
      if (aBytes[i] != bBytes[i]) {
        return aBytes[i] - bBytes[i];
      }
    }
    return aBytes.length - bBytes.length;
  }

  static String _serializeObject(Object? obj) {
    if (obj == null) {
      return 'null';
    } else if (obj is bool) {
      return obj ? 'true' : 'false';
    } else if (obj is String) {
      return _escapeString(obj);
    } else if (obj is num) {
      return obj.toString();
    } else if (obj is List) {
      return _serializeArray(obj);
    } else if (obj is Map<String, dynamic>) {
      return _serializeDictionary(obj);
    }
    else if (obj is Map) {
      return _serializeDictionary(Map<String, dynamic>.from(obj));
    } else {
      throw UnsupportedError('Unsupported data type');
    }
  }

  static String _serializeArray(List array) {
    List<String> items = array.map((item) => _serializeObject(item)).toList();
    return '[${items.join(',')}]';
  }

  static String _serializeDictionary(Map<String, dynamic> dictionary) {
    var sortedKeys = dictionary.keys.toList()..sort((a, b) => _asciiComparator(a, b));
    List<String> entries = [];

    for (var key in sortedKeys) {
      var value = dictionary[key];
      entries.add('$key:${_serializeObject(value)}');
    }

    return '{${entries.join(',')}}';
  }
}