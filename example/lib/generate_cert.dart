import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_shield/secure_enclave.dart';
import 'package:flutter_shield_example/DeviceInfoProvider.dart';
import 'package:flutter_shield_example/dashboard.dart';
import 'package:flutter_shield_example/utils.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class AppGenerateCert extends StatefulWidget {
  const AppGenerateCert({Key? key}) : super(key: key);

  @override
  State<AppGenerateCert> createState() => _AppGenerateCertState();
}

class _AppGenerateCertState extends State<AppGenerateCert> {
  final TextEditingController tagController = TextEditingController();
  final _secureEnclavePlugin = SecureEnclave();
  final uuid = const Uuid();
  bool isLoading = false;

  Future<bool> _generateClientCert(String deviceId) async {
    try {
      final bool status = (await _secureEnclavePlugin
                  .isKeyCreated("$deviceId${tagController.text}", "C"))
              .value ??
          false;

      if (!status) {
        ResultModel res = await _secureEnclavePlugin.generateKeyPair(
          accessControl: AccessControlModel(
            options: [
              AccessControlOption.privateKeyUsage
            ],
            tag: "$deviceId${tagController.text}",
          ),
        );

        if (res.error != null) {
          if (!mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.error!.desc.toString())),
          );
          return false;
        } else {
          return true;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client Keys already exists!')),
        );
        return true;
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      log(e.toString());
      return false;
    }
  }

  Future _generateServerCert(String deviceId, String publicKey) async {
    try {
      final bool status = (await _secureEnclavePlugin
                  .isKeyCreated("$deviceId${tagController.text}", "S"))
              .value ??
          false;
      if (status == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server Key already exists!')),
        );
        return;
      }

  
      var url = Uri.parse(
          'http://localhost:5111/client-certificate/save');
      final publicKeyBase64 = base64Encode(utf8.encode(publicKey!));
      var clientCertData = {
        "publicKey": publicKeyBase64,
        "commonName": "${tagController.text}.burgan.com.tr",
        "identity": {
          "deviceId": deviceId,
          "installationId": deviceId,
          "requestId": uuid.v4(),
          "reference": tagController.text
        }
      };
      final clientSaveResponse = await http.post(url,
          headers: {
            'Content-Type': 'application/json'
          },
          body: json.encode(clientCertData));

      if (clientSaveResponse.statusCode == 200) {
        url = Uri.parse(
            'http://localhost:5111/certificate/create');
        var serverCertData = {
          "identity": {
            "deviceId": deviceId,
            "installationId": deviceId,
            "requestId": uuid.v4(),
            "reference": tagController.text
          }
        };
        final serverCreateResponse = await http.post(url,
            headers: {
              'Content-Type': 'application/json'
            },
            body: json.encode(serverCertData));
          
          if (serverCreateResponse.statusCode == 200) {

            final serverBody = jsonDecode(serverCreateResponse.body);
            print(serverBody);
            final privateKeyEncode = serverBody["data"]["privateKey"];
            final privateKey = base64Decode(privateKeyEncode);
            final storedPrivateKey = await _secureEnclavePlugin.storeServerPrivateKey(
              tag: "$deviceId${tagController.text}",
              privateKeyData: privateKey);

            final certificateDataRaw = serverBody["data"]["certificate"];


            final certificateData = utf8.encode(certificateDataRaw);

            final storedCertificate = await _secureEnclavePlugin.storeCertificate(
              tag: "$deviceId${tagController.text}", 
              certificateData: certificateData);

            print('Certificate stored successful');

             if (storedPrivateKey.value) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Server create cerfiticate successful.')));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('ERROR. Server private key could not be stored.')));
            }

          }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('ERROR. Create certificate request could not be sent.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate & Remove')),
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
                TextField(
                  controller: tagController,
                  decoration: const InputDecoration(labelText: 'Tag'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  setState(() {
                    isLoading = true;
                  });
                  String deviceId = await getDeviceId();
                  Provider.of<DeviceInfoProvider>(context, listen: false)
                      .setDeviceId(deviceId);
                  Provider.of<DeviceInfoProvider>(context, listen: false)
                      .setTag(tagController.text);

                  final createClientResponse =
                      await _generateClientCert(deviceId);

                  if (createClientResponse) {
                    final publicKeyResponse = await _secureEnclavePlugin
                      .getPublicKey("$deviceId${tagController.text}");
                     await _generateServerCert(deviceId, publicKeyResponse.value!);

                      // Diğer sayfaya geçiş
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Dashboard()),
                      );
                  }
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
                  : const Text('Generate'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  setState(() {
                    isLoading = true;
                  });
                  String deviceId = await getDeviceId();

                  await _secureEnclavePlugin
                      .removeKey("$deviceId${tagController.text}", "C");

                  await _secureEnclavePlugin
                      .removeKey("$deviceId${tagController.text}", "S");

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Server and Client keys remove successfully!')),
                  );
                  // Diğer sayfaya geçiş
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Dashboard()),
                  );
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
                  : const Text('Remove'),
            )
          ],
        ),
      ),
    );
  }
}
