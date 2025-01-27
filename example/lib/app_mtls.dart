import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_shield/secure_enclave.dart';
import 'package:flutter_shield_example/DeviceInfoProvider.dart';
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

    List<int> convertDerToPem(Uint8List derBytes) {
      // DER formatındaki byte verisini Base64 olarak encode etme
      String base64Encoded = base64Encode(derBytes);

      // PEM formatındaki veriyi satırlara ayırma (64 karakter uzunluğunda satırlar)
      final chunkedBase64 = base64Encoded.replaceAllMapped(
        RegExp(r'.{1,64}'), 
        (match) => '${match.group(0)}\n'
      );

      // PEM başlık ve bitiş satırlarını ekleme
      String pemString = '-----BEGIN RSA PRIVATE KEY-----\n$chunkedBase64-----END RSA PRIVATE KEY-----\n';

      // PEM string'ini List<int> formatına çevirme
      return utf8.encode(pemString);
    }

    Future mtlsCall() async {
      final certificateResult = await _secureEnclavePlugin.getCertificate(tag: deviceInfoProvider.clientKey);

      final privateKeyResult = await _secureEnclavePlugin.getServerKey(tag: deviceInfoProvider.clientKey);
      final privateKeyPem = privateKeyResult.value!;

      final certificatePem = certificateResult.value!;

      SecurityContext securityContext = SecurityContext(withTrustedRoots: false)
        ..useCertificateChainBytes(utf8.encode(certificatePem))
        ..usePrivateKeyBytes(utf8.encode(privateKeyPem));
        
      HttpClient client = HttpClient(context: securityContext);
      final tokenId = uuid.v4();
      var url = Uri.parse(
          'https://test-mtls-pubagw6.burgan.com.tr/dev/ebanking/shield/transactions');

      try {
        HttpClientRequest request = await client.getUrl(url);

        request.headers.set("Content-Type", "application/json");
        request.headers.set("user_reference", deviceInfoProvider.tag);
        request.headers.set("X-DeviceId", deviceInfoProvider.deviceId);
        request.headers.set("X-Token", tokenId);
        request.headers.set("X-Request-Id", uuid.v4());
        request.headers.set("User",uuid.v4());
        request.headers.set("Behalf-Of-User", uuid.v4());

        HttpClientResponse creationResponse = await request.close();

        if (creationResponse.statusCode == 200) {        
            responseText.text = await creationResponse.transform(utf8.decoder).join();
            setState(() {});

            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('MTLS call successful.')));
          } 
          else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('ERROR. MTLS call request could not be sent.')));
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
