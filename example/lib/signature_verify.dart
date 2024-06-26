import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_shield/secure_enclave.dart';

class SignatureVerify extends StatefulWidget {
  const SignatureVerify({Key? key}) : super(key: key);

  @override
  State<SignatureVerify> createState() => _SignatureVerifyState();
}

class _SignatureVerifyState extends State<SignatureVerify> {
  TextEditingController tag = TextEditingController();
  TextEditingController plainText = TextEditingController();
  TextEditingController plainText2 = TextEditingController();
  TextEditingController signatureText = TextEditingController();

  final _secureEnclavePlugin = SecureEnclave();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signature & Verify'),
        actions: [
          IconButton(
              onPressed: () {
                _secureEnclavePlugin.removeKey(tag.text);
              },
              icon: const Icon(Icons.delete))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tag'),
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: tag,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ],
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
                  controller: plainText,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                // if (tag.text.isNotEmpty &&
                //     plainText.text.isNotEmpty &&
                //     appPassword.text.isNotEmpty) {
                try {
                  /// check if tag already on keychain
                  final bool status =
                      (await _secureEnclavePlugin.isKeyCreated(tag.text))
                              .value ??
                          false;

                  if (status == false) {
                    /// create key on keychain
                    await _secureEnclavePlugin.generateKeyPair(
                      accessControl: AccessControlModel(
                        options: [
                          // AccessControlOption.or,
                          // AccessControlOption.devicePasscode,
                          AccessControlOption.privateKeyUsage,
                        ],
                        tag: tag.text
                      ),
                    );
                  }

                  /// sign with app password
                  String signature = (await _secureEnclavePlugin.sign(
                        tag: tag.text,  
                        message: Uint8List.fromList(plainText.text.codeUnits)
                      ))
                          .value ??
                      '';
                  signatureText.text = signature.toString();
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                  log(e.toString());
                }
                // }
              },
              child: const Text('Sign'),
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
                    /// verify with app password
                    bool res = (await _secureEnclavePlugin.verify(
                          tag: tag.text,
                          plainText: plainText.text,
                          signature: signatureText.text
                        ))
                            .value ??
                        false;
                    plainText2.text = res.toString();
                    setState(() {});
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                    log(e.toString());
                  }
                }
              },
              child: const Text('Verify'),
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
                  controller: plainText2,
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
