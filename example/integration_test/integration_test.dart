import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_shield/secure_enclave.dart';

void main(){
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const String tagNormal = "app.privateKey";

  group('create delete key', () {
    group('reset key', () {

      testWidgets('normal key', (widgetTester) async{

        blankApp('Test delete normal key');
        await widgetTester.pumpAndSettle();

        SecureEnclave secureEnclave = SecureEnclave();
        await secureEnclave.removeKey(tagNormal, "C").then((result){

        });
      });

    });

    group("Create all key", () {

      testWidgets("create Normal Key", (widgetTester) async {

        blankApp("Test create normal key");
        await widgetTester.pumpAndSettle();

        SecureEnclave secureEnclave = SecureEnclave();
        await secureEnclave.generateKeyPair(accessControl: AccessControlModel(options: [AccessControlOption.privateKeyUsage], tag: tagNormal)).then((result){
          checkResult(
              result: result,
              onSuccess: (){
                expect(result.value, true);
              });
        });
      });

    });

    group('delete key', () {

      testWidgets('normal key', (widgetTester) async{

        blankApp('Test delete normal key');
        await widgetTester.pumpAndSettle();

        SecureEnclave secureEnclave = SecureEnclave();
        await secureEnclave.removeKey(tagNormal, "C").then((result){
          checkResult(result: result, onSuccess: (){
            expect(result.value, true);
          });
        });
      });

      testWidgets('unknown key', (widgetTester) async{

        blankApp('Test delete unknown key');
        await widgetTester.pumpAndSettle();

        SecureEnclave secureEnclave = SecureEnclave();
        await secureEnclave.removeKey('dasdasdas', "C").then((result){
          checkResult(result: result, onSuccess: (){
            expect(result.value, false);
          });
        });
      });

    });
  });

  group('encrypt - decrypt', () {

    requireSetup(tagNormal);

    group('Normal Encrypt Decrypt', () {
      const String cleartext = "Lorem Ipsum";
      Uint8List? encrypted;

      testWidgets('encrypt', (widgetTester) async {

        blankApp("Test normal encrypt...");
        await widgetTester.pumpAndSettle();

        SecureEnclave secureEnclave = SecureEnclave();
        await secureEnclave.encrypt(message: cleartext, tag: tagNormal).then((result){
          checkResult(result: result, onSuccess: (){
            encrypted = result.value;

            expect(encrypted != null, true);
            expect(encrypted!.isEmpty, false);
          });
        });
      });


      testWidgets("decrypt", (widgetTester) async{
        if(encrypted == null || encrypted!.isEmpty){
          throw("Encrypted Text null or empty. abort...");
        }

        blankApp("Test normal decrypt...");
        await widgetTester.pumpAndSettle();

        SecureEnclave secureEnclave = SecureEnclave();
        await secureEnclave.decrypt(message: encrypted!, tag: tagNormal).then((result) {
          checkResult(result: result, onSuccess: (){
            expect(result.value == cleartext, true);
          });
        });
      });

    });

  });

  group("signing - verify", () {

    requireSetup(tagNormal);

    group('normal signing verify', () {

      const clearText = "Lorem Ipsum";
      String? signature;

      testWidgets('sign', (widgetTester) async{

        blankApp("Test normal signing");
        await widgetTester.pumpAndSettle();

        SecureEnclave secureEnclave = SecureEnclave();
        await secureEnclave.sign(tag: tagNormal, message: Uint8List.fromList(clearText.codeUnits)).then((result){
          checkResult(result: result, onSuccess: (){
            signature = result.value;
            expect(signature != null, true);
            expect(signature!.isEmpty, false);
          });
        });
      });

      testWidgets('verify', (widgetTester) async{

        if(signature == null || signature!.isEmpty){
          throw('signature null or empty. abort...');
        }

        blankApp('Test normal verify');
        await widgetTester.pumpAndSettle();

        SecureEnclave secureEnclave = SecureEnclave();
        await secureEnclave.verify(plainText: clearText, signature: signature!, tag: tagNormal).then((result) async{
          checkResult(result: result, onSuccess: (){
            expect(result.value, true);
          });
        });
      });

      testWidgets('verify wrong', (widgetTester) async{

        if(signature == null || signature!.isEmpty){
          throw('signature null or empty. abort...');
        }

        blankApp('Test normal verify wrong');
        await widgetTester.pumpAndSettle();

        SecureEnclave secureEnclave = SecureEnclave();
        await secureEnclave.verify(plainText: 'asdfghjkl', signature: signature!, tag: tagNormal).then((result) async{
          checkResult(result: result, onSuccess: (){
            expect(result.value, false);
          });
        });
      });
    });

  });

}

Future<void> requireSetup(String tagNormal) async {
  setUpAll(() async{

        SecureEnclave secureEnclave = SecureEnclave();

        await secureEnclave.removeKey(tagNormal, "C");

        await secureEnclave.generateKeyPair(accessControl: AccessControlModel(options: [AccessControlOption.privateKeyUsage], tag: tagNormal));

  });

  tearDownAll(() async{

        SecureEnclave secureEnclave = SecureEnclave();
        await secureEnclave.removeKey(tagNormal, "C");
  });
}

void checkResult({required ResultModel result, required Function() onSuccess, Function()? onFail}) {
  if(result.error == null){
    onSuccess();
  } else {
    if(onFail == null) {
      throw(result.error!.desc);
    } else {
      onFail.call();
    }
  }
}

void blankApp(String title){
  runApp(MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.white,
      body:  Center(
        child: Text(title, style: const TextStyle(fontSize: 24),),
      ),
    ),
  ));
}