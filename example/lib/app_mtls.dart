import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_shield/secure_enclave.dart';
import 'package:flutter_shield_example/DeviceInfoProvider.dart';
import 'package:flutter_shield_example/constants.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart';
import 'dart:typed_data';


class AppMtls extends StatefulWidget {
  const AppMtls({Key? key}) : super(key: key);

  @override
  State<AppMtls> createState() => _AppMtlsState();
}

class _AppMtlsState extends State<AppMtls> {
  TextEditingController tag = TextEditingController();
  TextEditingController requestTest = TextEditingController();
  TextEditingController responseText = TextEditingController();

  final _secureEnclavePlugin = SecureEnclave();
  final uuid = const Uuid();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final deviceInfoProvider = Provider.of<DeviceInfoProvider>(context);

    Future<String?> sign(String input) async {
      ResultModel response = await _secureEnclavePlugin.sign(
          tag: deviceInfoProvider.clientKey,
          message: utf8.encode(input)
          );

      if (response.error == null) {
       return response.value.toString();
      }
      return null;
    }

    Future mtlsCall() async {
      final certificateResult = await _secureEnclavePlugin.getCertificate(tag: deviceInfoProvider.clientKey);
      final privateKeyResult = await _secureEnclavePlugin.getServerKey(tag: deviceInfoProvider.clientKey);
      final privateKeyPem = privateKeyResult.value!;
      final certificatePem = certificateResult.value!;

      print('certificatePem: $certificatePem');
      print('privateKeyPem: $privateKeyPem');

      SecurityContext securityContext = SecurityContext(withTrustedRoots: false)
        ..useCertificateChainBytes(utf8.encode(certificatePem))
        ..usePrivateKeyBytes(utf8.encode(privateKeyPem));
        
      HttpClient client = HttpClient(context: securityContext);
      var url = Uri.parse(
          '${AppConstants.dmzBaseUrl}/ebanking/bffapi/dashboard/addorupdatecustomercard');
      
      HttpClientRequest request = await client.putUrl(url);
      try {
        final requestId = uuid.v4();
        print('requestId: $requestId');
        request.headers.set("Content-Type", "application/json");
        request.headers.set("user_reference", deviceInfoProvider.tag);
        request.headers.set("X-Device-Id", deviceInfoProvider.deviceId);
        request.headers.set("X-Installation-Id", deviceInfoProvider.deviceId);
        request.headers.set("X-Request-Id", requestId);

        // final signData = await sign(requestTest.text);
        // if (signData != null) {
        //    request.headers.set("X-Jws-Signature", signData);
        // }

        request.add(utf8.encode(jsonEncode(requestTest.text)));

        HttpClientResponse response = await request.close();

        if (response.statusCode == 200) {        
            responseText.text = await response.transform(utf8.decoder).join();
            setState(() {});

            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('MTLS call successful.')));
          } 
          else {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('MTLS call successful.')));
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('ERROR. MTLS call request could not be sent.')));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('MTLS Call')),
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
                const Text('Request Data'),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: requestTest,
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
                  await mtlsCall();
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
                  : const Text('Submit'),
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Response'),
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: responseText,
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
