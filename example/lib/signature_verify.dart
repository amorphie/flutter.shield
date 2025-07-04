import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shield/CanonicalJsonSerializer.dart';
import 'package:flutter_shield/secure_enclave.dart';
import 'package:flutter_shield_example/DeviceInfoProvider.dart';
import 'package:flutter_shield_example/constants.dart';
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

    Future sign() async {
      ResultModel response = await _secureEnclavePlugin.sign(
          tag: deviceInfoProvider.clientKey,
          message: utf8.encode(plainText.text)
          );

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

      var url = Uri.parse(
          '${AppConstants.baseUrl}/jws/verify');
      final dataObject = json.decode(plainText.text);
      try {
        final dataRaw = CanonicalJsonSerializer.hashData(plainText.text);
        final clientverifyRes = await _secureEnclavePlugin.verify(
          tag: deviceInfoProvider.clientKey, plainText: dataRaw, signature: signatureText.text
          );

        if (clientverifyRes.value == true) {

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('CLIENT Verification successful.')));
        } else {

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('ERROR. Verification failed.')));
        }

        // final verifyResponse = await http.post(url,
        //   headers: {
        //     'Content-Type': 'application/json',
        //     'user_reference': deviceInfoProvider.tag,
        //     'x_device_id': deviceInfoProvider.deviceId,
        //     'x_installation_id': deviceInfoProvider.deviceId,
        //     'x_request_id': uuid.v4(),
        //     'x_jws_signature': signatureText.text
        //   },
        //   body: json.encode(dataObject)); 
        // final responseBody = jsonDecode(verifyResponse.body);
        // if (verifyResponse.statusCode == 200) {
        //     try {
        //       verifyText.text = "true";
        //       setState(() {});

        //       ScaffoldMessenger.of(context)
        //           .showSnackBar(SnackBar(content: Text('Verify successful.')));
        //     } catch (e) {
        //       verifyText.text = "false";
        //       setState(() {});
        //       ScaffoldMessenger.of(context)
        //           .showSnackBar(SnackBar(content: Text('Verify failed.')));
        //     }
        // } else {
        //   verifyText.text = "false";
        //       setState(() {});
        //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //       content: Text('ERROR. ' + responseBody["error"]["message"].toString())));
        // }
      } catch (e) {
        log(e.toString());
         ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString())));
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
