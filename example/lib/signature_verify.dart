import 'dart:convert';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shield/secure_enclave.dart';
import 'package:flutter_shield_example/CanonicalJsonSerializer.dart';
import 'package:flutter_shield_example/DeviceInfoProvider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class SignatureVerify extends StatefulWidget {
  const SignatureVerify({Key? key}) : super(key: key);

  @override
  State<SignatureVerify> createState() => _SignatureVerifyState();
}

class _SignatureVerifyState extends State<SignatureVerify> {
  TextEditingController tag = TextEditingController();
  TextEditingController plainText = TextEditingController();
  TextEditingController verifyText = TextEditingController();
  TextEditingController signatureText = TextEditingController();

  final _secureEnclavePlugin = SecureEnclave();
  final uuid = const Uuid();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final deviceInfoProvider = Provider.of<DeviceInfoProvider>(context);

    String hashData(String jsonData) {
      final dataObject = json.decode(jsonData);
      final dataRawSerialize = CanonicalJsonSerializer.serialize(dataObject);
      final digest = sha256.convert(utf8.encode(dataRawSerialize));
      return digest.toString();
    }

    Future sign() async {
      final dataRaw = hashData(plainText.text);
      ResultModel response = await _secureEnclavePlugin.sign(
          tag: deviceInfoProvider.clientKey,
          message: utf8.encode(dataRaw)); //utf8.encode(json.encode(dataRaw))

      if (response.error == null) {
        signatureText.text = response.value.toString();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("ERROR. Sign")));
      }
    }

    Future verify() async {
      //Clear
      verifyText.text = "";
      setState(() {});

      final instanceId = uuid.v4();
      final tokenId = uuid.v4();
      var url = Uri.parse(
          'https://dev-amorphie-workflow.burgan.com.tr/workflow/instance/$instanceId/transition/verify-transaction-send-sign');
      final dataObject = json.decode(plainText.text);

      var verifyData = {"signData": signatureText.text, "rawData": dataObject};

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
          body: json.encode(verifyData));

      if (creationResponse.statusCode == 200) {
        //For Longpooling
        await Future.delayed(Duration(seconds: 3));
        url = Uri.parse(
            "https://dev-amorphie-workflow-hub.burgan.com.tr/longpooling/VerifyTransactionSubFlow?instanceId=$instanceId");
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
          try {
            final verifyResult =
                responseBody["data"]["additionalData"]["verifyResult"]["data"];

            verifyText.text = json.encode(verifyResult);
            setState(() {});

            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Verify successful.')));
          } catch (e) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Verify failed.')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('ERROR. No response received from verify request.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('ERROR. Verify request could not be sent.')));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signature & Verify')
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plain Text'),
                const SizedBox(
                  height: 5,
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
                  await sign();
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
                  : const Text('Sign'),
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Signature Text'),
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: signatureText,
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
                if (signatureText.text.isNotEmpty) {
                  try {
                    setState(() {
                      isLoading = true;
                    });
                    await verify();
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
                  : const Text('Verify'),
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Is Verify?'),
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: verifyText,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
