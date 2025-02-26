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

      final instanceId = uuid.v4();
      final tokenId = uuid.v4();
      var url = Uri.parse(
          'https://test-amorphie-workflow.burgan.com.tr/workflow/instance/$instanceId/transition/cert-management-start');
      final publicKeyBase64 = base64Encode(utf8.encode(publicKey!));
      var certData = {
        "clientCert": {
          "publicKey": publicKeyBase64,
          "serialNumber": "2d6e2d768e260e690b537198d06d5e8115365c42",
          "commonName": "${tagController.text}.burgan.com.tr",
          "thumbprint": "0eeace74f9a2807d6761cb6072485ec51b8db574",
          "expirationDate": "2024-12-27T11:50:57.080Z"
        }
      };
      final creationResponse = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'user_reference': tagController.text,
            'X-Device-Id': deviceId,
            'X-Installation-Id': tokenId,
            'X-Request-Id': uuid.v4(),
            'User': uuid.v4(),
            'Behalf-Of-User': uuid.v4()
          },
          body: json.encode(certData));

      if (creationResponse.statusCode == 200) {
        //For Longpooling
        // await Future.delayed(Duration(seconds: 8));
        // url = Uri.parse(
        //     "https://test-amorphie-workflow-hub.burgan.com.tr/longpooling/CertManagementSubFlow?instanceId=$instanceId");
        // final createdResponse = await http.get(url, headers: {
        //   'Content-Type': 'application/json',
        //   'user_reference': tagController.text,
        //   'X-Device-Id': deviceId,
        //   'X-Installation-Id': tokenId,
        //   'X-Request-Id': uuid.v4(),
        //   'User': uuid.v4(),
        //   'Behalf-Of-User': uuid.v4()
        // });

        // if (createdResponse.statusCode == 200) {
        final createdResponse = json.encode({
  "data": {
    "certificate": "-----BEGIN CERTIFICATE-----\nMIID0zCCArugAwIBAgIUD7S0Ona5SpKGsoS8w5aioqRUHSQwDQYJKoZIhvcNAQEL\nBQAwKjEoMCYGA1UEAxMfdGVzdC5ub25wcm9kLm10bHMuYnVyZ2FuLmNvbS50cjAe\nFw0yNTAyMjYxMTMyNDRaFw0zNTAxMjAwNDI5MzFaMFMxUTBPBgNVBAMTSDIzMi1h\nMDAwMGY2NC01NzE3LTAwMDAtYjNmYy0yZDk2M2Y2NjAwMDQudGVzdC5ub25wcm9k\nLm10bHMuYnVyZ2FuLmNvbS50cjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC\nggEBAM6FurK9LNUksTxDDD46xOtqYj6ErzDoVKjg2dk/hZCGnjqlWswSwquXhfUr\nc/9VxH0h9m3Mj/JWlneCveT9goJCjBfkzQiuTFGYNtR/WJVNxeVMdp/0Kz6SZmDZ\nnZr75Ea7AjmILrYpphMO3XuMUGKjI1f6xQl5aD/F5hiME0E47ptm+PD6hCd3UYnR\nogbvFLkUPKPKCUeIPwBnItpzLEY8Tqe6LpdCvC4s6fVc6srOWou/3dgU6dAMeymZ\npZDP6OtD4rcdbZ/4kd0Mn/o4cnrKfUXRh0AtuokGcKfeQ88j1Fxw1DMtUQO/lhoj\nlu5X7Gmc69IOBIpmDERBZ917pGcCAwEAAaOBxzCBxDAOBgNVHQ8BAf8EBAMCA6gw\nHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMB0GA1UdDgQWBBRgfvBSUEs4\nmK8hZbQw0kEIzGjtiDAfBgNVHSMEGDAWgBQFj6Rk3yemNa3vk8A232L+x3veZzBT\nBgNVHREETDBKgkgyMzItYTAwMDBmNjQtNTcxNy0wMDAwLWIzZmMtMmQ5NjNmNjYw\nMDA0LnRlc3Qubm9ucHJvZC5tdGxzLmJ1cmdhbi5jb20udHIwDQYJKoZIhvcNAQEL\nBQADggEBAKZUk88u6KdCFmXFSDe1EAOuUmY1d8an5uCVJnh+dAnmzNj9ixhFhxGf\na7nz9qFvuqHCnFphze7PYruDp6U2VH4ibBG1HccPm67Ao/kAnZa1KcHW8vjgkfcp\nSXGVlPZTQ+tfaTrhfJoCtbiaMU1hiRQdejuntc75JwFADR/C8NGQJYRhngmRbX+G\n8U84OU8/gZf9VkMvXakriKyKezg/+VcpHOhMTvqhILRUf8JrztRT5j75CJxdeNev\npT2jXxGgJGc7zEAAebpeFr1IPJDCG0h1J0m9nw1MMARyHBE1oEzaw7WoJwjNZGtj\nFq6dk2YE00aU9i63n94NOfmvQsq9uwM=\n-----END CERTIFICATE-----",
    "expirationDate": "2035-01-20T04:29:31Z",
    "id": "a4ac1c4d-80c4-45ea-9398-9010573ad4c9",
    "privateKey": "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcFFJQkFBS0NBUUVBem9XNnNyMHMxU1N4UEVNTVBqckU2MnBpUG9Tdk1PaFVxT0RaMlQrRmtJYWVPcVZhCnpCTENxNWVGOVN0ei8xWEVmU0gyYmN5UDhsYVdkNEs5NVAyQ2drS01GK1ROQ0s1TVVaZzIxSDlZbFUzRjVVeDIKbi9RclBwSm1ZTm1kbXZ2a1Jyc0NPWWd1dGltbUV3N2RlNHhRWXFNalYvckZDWGxvUDhYbUdJd1RRVGp1bTJiNAo4UHFFSjNkUmlkR2lCdThVdVJROG84b0pSNGcvQUdjaTJuTXNSanhPcDdvdWwwSzhMaXpwOVZ6cXlzNWFpNy9kCjJCVHAwQXg3S1ptbGtNL282MFBpdHgxdG4vaVIzUXlmK2poeWVzcDlSZEdIUUMyNmlRWndwOTVEenlQVVhIRFUKTXkxUkE3K1dHaU9XN2xmc2FaenIwZzRFaW1ZTVJFRm4zWHVrWndJREFRQUJBb0lCQUNleW1md2drLzBXbEFEKwo3RndMNU8xUm9qZmRQbVc2eXdjNVRYYk9tSWg2Ny9CYTk1U1JxSnplUC9Bc0haeC9xb2paSGVybUx1ZEkwSnlCClk2b2dOdFYrSURxNWp0WHoxeFM2R3hRR3RJcmlpNzh6VHZ3WkxiVFY1RnNLaVpxUWY4VSt6a01yMDdyTlQ3Q0wKSTNUTHVHbjFiT1pNL0ZJQlpkSVlZczNtSXc5ZW4weVA5VUUwMzkvbkY0NVpiZmpFaWg4b0xyeXM4ekREbU9DMgpscEJuN1lvZEY1eEg4VUwrUzlNSVo4ck1IQmE0b3lXZTUyV211aW9aRUh5NHc2ZEhlZGdUSXgyMThsYnN5U1IrClc3S0k2eTdIaW9OSHJwUTRpTnozRVI4MFJBQnNBT05FeWVHMStDY2I5M21ubHFyaEJsNDhaUXczUFpCUjZ2MkgKQUZTSDBwVUNnWUVBNTliR1lkcFVadi9ReFMvc2tONVVxQWpxY2dua1ZLbC9Pb3BsdHJsVzBBZVNFQ1JzdEVGVQp1eVlTSlBYNi9RMEFkWkFNVS92MDRLVjNXU2duSjMzUTIxSXppRzJ1MlRiOFB1ejEvZHUzbmlUYllDaXB2SmtvCkJDZTNGNlk4ekJaZUJsZEF6RjM5bGtFRWVLWVRFUUNJRnY2TW5UN2hENHEyM25IRW1uZkg0OTBDZ1lFQTVBdUkKcjRncGdEZHVUekhmTlRtcHNzc1ZRam44ZCtSeGYxdnAyQVFwdVFyQzRTTmlWa2JIWXdGS3pZeC9PWFBjSkh1TgpqcW91dTJPdWFUb0cvb3U1UWFaL0xBeGlpY2paaUQ3ZjlGVDQvd1JXdE8zaU9VNFFDMUJWTURjelVpeUxTdnRUCi95QUF4NDByMDVVUXV1Q1VJbDdUSjE5Y01FdXY0a25RdzNNQ2R4TUNnWUVBbW9YVFNlczhjRDQzUndhUE5XdUsKbjBqNkFqSkhwb29taTcwczJDSW1FNWZJS2N3dFMrTnpkeDJENEhDMjdpelpUb0pKUlR6YzFWSlQvdSs5VVJ3Ugp0ZXpPL2pLazVKQTZoakpvTHVCZ1BSNnh2U0M5S1VBbnBNVlh5b0o1YVVuTE40eTJXc0NXd2F2cU1BUDVGMDcwClplY1pqOEVXUHNhazVoU01CcXlwWlYwQ2dZRUFrN0NVbVhvSnhxd2ZtTktueUlUTHpxdVAzUkJJM2l6cEJKNjIKVjl4NldRa0xKVndSTitjbkFvdTNzbCtubGNIZmRSRS9vSUcvT2tWWWszV3RTZldieVZUWFQrUEZmWTdDczJabApESXhycGwxYytsaUdCcTd6M1IvdHpBZzBDS2dvbmlzZlB6K3V3WTVBTUF0K2hra2tKdzVhbWtrOEgxc2xVZHlVCmc4QmNmRmtDZ1lFQTNnM242aXVXZ243S3c5djd5VDJtVWxpUEhwaGtVek1taEQ0RE13Nk8zZXVnZjRuVkJ0WGwKZTl5UXJsSzNKcmpvNWZPdVpEWE1SZWIrVk4wbTU4a1JHTmVHZzBSNzNUdXlmZUpjRXQ3L2ZQS1dHdE1XaXczUQo5aUIyenI2TWc2Zk4yd25iWGhNR0xMWVNpNGcxaGpkWkl2Q1FTdEZVL0FrUzY5WjB4WWhYcDVVPQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQ=="
  }
});
          final certResponse = json.decode(createdResponse);
          final privateKeyEncode = certResponse["data"]["privateKey"];
          final privateKey = base64Decode(privateKeyEncode);
          final storedPrivateKey = await _secureEnclavePlugin.storeServerPrivateKey(
              tag: "$deviceId${tagController.text}",
              privateKeyData: privateKey);

          final certificateDataRaw = certResponse["data"]["certificate"];


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
        // } else {
        //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //       content: Text(
        //           'ERROR. No response received from create certificate request.')));
        // }
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
