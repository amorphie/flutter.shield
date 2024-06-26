// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_shield/backup/secure_enclave.dart';
// import 'package:flutter_shield/src/secure_enclave_method_channel.dart';

// void main() {
//   MethodChannelSecureEnclave platform = MethodChannelSecureEnclave();
//   const MethodChannel channel = MethodChannel('flutter_shield');

//   TestWidgetsFlutterBinding.ensureInitialized();

//   setUp(() {
//     channel.setMockMethodCallHandler((MethodCall methodCall) async {
//       return '42';
//     });
//   });

//   tearDown(() {
//     channel.setMockMethodCallHandler(null);
//   });

//   test('test AppPassword', () async {
//     AccessControl accessControl =  AppPasswordAccessControl(
//       options: [],
//       tag: "coba"
//     );

//     print(accessControl.toJson());
//     expect(accessControl.tag, "coba");
//   });
// }
