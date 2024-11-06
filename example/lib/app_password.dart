import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_shield/secure_enclave.dart';
import 'package:convert/convert.dart';
import 'package:flutter_shield_example/DeviceInfoProvider.dart';
import 'package:flutter_shield_example/utils.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class AppPassword extends StatefulWidget {
  const AppPassword({Key? key}) : super(key: key);

  @override
  State<AppPassword> createState() => _AppPasswordState();
}

class _AppPasswordState extends State<AppPassword> {
  TextEditingController tag = TextEditingController();
  TextEditingController plainText = TextEditingController();
  TextEditingController decryptPlainText = TextEditingController();
  TextEditingController cipherText = TextEditingController();

  final _secureEnclavePlugin = SecureEnclave();
  final uuid = const Uuid();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final deviceInfoProvider = Provider.of<DeviceInfoProvider>(context);

    Future encrypt() async {
      final instanceId = uuid.v4();
      final tokenId = uuid.v4();
      var url = Uri.parse(
          'https://dev-amorphie-workflow.burgan.com.tr/workflow/instance/$instanceId/transition/encrypt-transaction-start');
      var encryptData = {"data": json.decode(plainText.text)};
      final creationResponse = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'user_reference': deviceInfoProvider.tag,
            'X-Device-Id': deviceInfoProvider.deviceId,
            'X-Token-Id': tokenId,
            'X-Request-Id': uuid.v4(),
            'User': uuid.v4(),
            'Behalf-Of-User': uuid.v4()
          },
          body: json.encode(encryptData));

      if (creationResponse.statusCode == 200) {
        //For Longpooling
        await Future.delayed(Duration(seconds: 3));
        url = Uri.parse(
            "https://dev-amorphie-workflow-hub.burgan.com.tr/longpooling/EncryptTransactionSubFlow?instanceId=$instanceId");
        final createdResponse = await http.get(url, headers: {
          'Content-Type': 'application/json',
          'user_reference': deviceInfoProvider.tag,
          'X-Device-Id': deviceInfoProvider.deviceId,
          'X-Token-Id': tokenId,
          'X-Request-Id': uuid.v4(),
          'User': uuid.v4(),
          'Behalf-Of-User': uuid.v4()
        });

        if (createdResponse.statusCode == 200) {
          final responseBody = json.decode(createdResponse.body);
          final encryptResult =
              responseBody["data"]["additionalData"]["encryptResult"]["data"];

          print(encryptResult);

          cipherText.text = json.encode(encryptResult);
          setState(() {});

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Encryption successful.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'ERROR. No response received from encryption request.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('ERROR. Encryption request could not be sent.')));
      }
    }

    Future dencrypt() async {
      final jsonData = json.decode(cipherText.text);
      final encryptData = jsonData["encryptData"];

      ResultModel response = await _secureEnclavePlugin.decrypt(
          tag: deviceInfoProvider.serverKey,
          message: base64Decode(encryptData));
      if (response.value != null) {
        decryptPlainText.text = response.value;
        setState(() {});
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error!.desc.toString())));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Encrypt & Decrypt')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plain Data'),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: plainText,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  maxLines: null,
                  minLines: 5,
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  setState(() {
                    isLoading = true;
                  });
                  await encrypt();
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                  log(e.toString());
                } finally {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Encrypt'),
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cipher Text (Hex)'),
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: cipherText,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  maxLines: null,
                  minLines: 5,
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                if (cipherText.text.isNotEmpty) {
                  try {
                    setState(() {
                      isLoading = true;
                    });
                    await dencrypt();
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                    log(e.toString());
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                }
              },
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Decrypt'),
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plain Text'),
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: decryptPlainText,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  maxLines: null,
                  minLines: 5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
