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
                  .isKeyCreated("$deviceId${tagController.text}"))
              .value ??
          false;

      if (!status) {
        ResultModel res = await _secureEnclavePlugin.generateKeyPair(
          accessControl: AccessControlModel(
            options: [
              // AccessControlOption.or,
              // AccessControlOption.devicePasscode,
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
          const SnackBar(content: Text('Key already exists!')),
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
                  .isKeyCreated("$deviceId${tagController.text}_ss"))
              .value ??
          false;
      if (status == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server Key already exists!')),
        );
        return;
      }

      final instanceId = uuid.v4();
      final tokenId = uuid.v4();
      var url = Uri.parse(
          'https://dev-amorphie-workflow.burgan.com.tr/workflow/instance/$instanceId/transition/cert-management-start');
      final publicKeyBase64 = base64Encode(utf8.encode(publicKey!));
      var certData = {
        "clientCert": {
          "publicKey": publicKeyBase64,
          "serialNumber": "2d6e2d768e260e690b537198d06d5e8115365c42",
          "commonName": "${tagController.text}.burgan.com",
          "thumbprint": "0eeace74f9a2807d6761cb6072485ec51b8db574",
          "expirationDate": "2024-12-27T11:50:57.080Z"
        }
      };
      final creationResponse = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'user_reference': tagController.text,
            'X-Device-Id': deviceId,
            'X-Token-Id': tokenId,
            'X-Request-Id': uuid.v4(),
            'User': uuid.v4(),
            'Behalf-Of-User': uuid.v4()
          },
          body: json.encode(certData));

      if (creationResponse.statusCode == 200) {
        //For Longpooling
        await Future.delayed(Duration(seconds: 3));
        url = Uri.parse(
            "https://dev-amorphie-workflow-hub.burgan.com.tr/longpooling/CertManagementSubFlow?instanceId=$instanceId");
        final createdResponse = await http.get(url, headers: {
          'Content-Type': 'application/json',
          'user_reference': tagController.text,
          'X-Device-Id': deviceId,
          'X-Token-Id': tokenId,
          'X-Request-Id': uuid.v4(),
          'User': uuid.v4(),
          'Behalf-Of-User': uuid.v4()
        });

        if (createdResponse.statusCode == 200) {
          final certResponse = json.decode(createdResponse.body);
          final privateKeyEncode = certResponse["data"]["additionalData"]
              ["serverCertCreateResult"]["data"]["privateKey"];
          final privateKey = base64Decode(privateKeyEncode);
          final storedKey = await _secureEnclavePlugin.storeServerPrivateKey(
              tag: "$deviceId${tagController.text}",
              privateKeyData: privateKey);
          if (storedKey.value) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Create cerfiticate successful.')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text('ERROR. Server private key could not be stored.')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'ERROR. No response received from create certificate request.')));
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

                  if (!createClientResponse) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Client cert creating error!')),
                    );
                  }

                  final publicKeyResponse = await _secureEnclavePlugin
                      .getPublicKey("$deviceId${tagController.text}");
                  await _generateServerCert(deviceId, publicKeyResponse.value!);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Key generated successfully!')),
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
                      .removeKey("$deviceId${tagController.text}");

                  await _secureEnclavePlugin
                      .removeKey("$deviceId${tagController.text}_ss");

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Key remove successfully!')),
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
