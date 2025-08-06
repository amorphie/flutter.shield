import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_shield/secure_enclave.dart';
import 'package:flutter_shield_example/DeviceInfoProvider.dart';
import 'package:provider/provider.dart';

class AESDecryptTest extends StatefulWidget {
  const AESDecryptTest({Key? key}) : super(key: key);

  @override
  State<AESDecryptTest> createState() => _AESDecryptTestState();
}

class _AESDecryptTestState extends State<AESDecryptTest> {
  final TextEditingController _encryptedKeyController = TextEditingController();
  final TextEditingController _encryptedDataController = TextEditingController();
  
  String _decryptedResult = '';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Örnek veriler
    _encryptedKeyController.text = '''
{
  "transactionId": "fca8b941-535b-41f6-b8e1-7d53196c5651",
  "encryptedKey": "ZLMek7BYRNuZCTeF4Mp/jW/ANRCiAeQk4DC0rPhDjkcrQ9nGbipM6M65gXkJVmgfN+zqVuaWa5pF2xc1igJ2VgbIh6ur1ifG8BGxZAIKAW2flO0Qmi/c/TWaDloC7zPiuD1PFzUxrFc8VygxrxvKx8vAJb+opv6KSmdhTMW+tKtZasU6pe34zswILUdNOa8jIvOrmwVWTs/emJoLxT3ux/22DV/ra1trjZB5xksCm9Qe8yFc3bZPl3jsRJSTNhW2dX9iUCTikI94eex/Xx66MqSYWo/GtR/rldeK4I0hrO/TK/UIooRBhxRKnjZpsBoYDzQrwl45ou7qq6O1TEHxBA==",
  "encryptData": "YSYGXsKaxG9BdTO/OMEYB5R4JRaa+GmTgzCMMhAhqolX47ACx6CV8CWymURGtHLwmg4HEG6GIFr5lF2h5CLhACimyhuZc/NsAn4KoO1VDoCOrrbbbCIOKPE4N8LkugUJD3nLCSpEUEoODksKDW/C3S7esDzROtdPXdJzjO9MufesG43FW11lsVeAOr0QeWKW5bSTMrFFIbjEIIFUWp2MPjAmqWzqq8iTuQJ5y7UbOG06hqtHM6CQNwI0taMeP1P9Pzkv2VwI4pYsrQhBpA/ClPjAKZHoavRb8eOaATEjJmIVnYiSSd0Rf6P7L3duj0XMZiKx97TWfYZHSRKoYV1rjd7IpF5ik0DT1fLtNmWGjlRh6WkMI3c28hBSAg6wCxVk2/BV8BNenkX4GOMrEWtgz0/KnCpR5Fjsaj5w9kC/vi+mpkn+YBYfUxxGY8c+khvHzjfAkbrw1GALpn+voQUaASsdhDmR7UVNe03Y1BGznY+a/L83TsEYJqsxxnfPlljBA2aWfR9dDQPRzYbuWbsReQqU6XK63zLV+LYOc39E3chEfVgAqQORT0ciCQshqY36kOShpTQ7keOjK7kxIiHeoyaRCdTQv6aLRT5aFwx8n8yy3olbNSCmwHTwUfQZdIkSu1z0OjUbGatFrp87tHOotit9ekRol3jhCuCt3miahvk4y3MYroeWXOvwj2k41fnUrELrQkw/IM/20R2IsIWYgQ=="
}
''';
  }

  Future<void> _testAESDecrypt() async {
    final deviceInfoProvider = Provider.of<DeviceInfoProvider>(context, listen: false);
    final tag = deviceInfoProvider.clientKey;
    
    if (tag.isEmpty) {
      setState(() {
        _decryptedResult = 'Error: Tag is empty. Please generate a certificate first.';
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _decryptedResult = 'Starting AES decrypt test...\nUsing tag: $tag';
    });

    try {
      // Check if server key exists for this tag
      final serverKeyResult = await SecureEnclave().getServerKey(tag: tag);
      
      setState(() {
        _decryptedResult += '\n\nChecking server key...';
        _decryptedResult += '\nServer key exists: ${serverKeyResult.error == null && serverKeyResult.value != null}';
        if (serverKeyResult.error != null) {
          _decryptedResult += '\nServer key error: ${serverKeyResult.error!.desc}';
        }
      });
      
      if (serverKeyResult.error != null || serverKeyResult.value == null) {
        setState(() {
          _decryptedResult += '\n\n❌ ERROR: No server private key found for tag "$tag".\n\nPlease go to "Generate Cert" and create a certificate first.';
          _isLoading = false;
        });
        return;
      }

      // Parse JSON input
      final jsonData = json.decode(_encryptedKeyController.text) as Map<String, dynamic>;
      final encryptedKey = jsonData['encryptedKey'] as String;
      final encryptedData = jsonData['encryptData'] as String;
      
      setState(() {
        _decryptedResult += '\n\nParsing JSON... ✅';
        _decryptedResult += '\nEncrypted key length: ${encryptedKey.length}';
        _decryptedResult += '\nEncrypted data length: ${encryptedData.length}';
      });
      
      // Step 1: Decrypt the AES key using RSA (existing method)
      final encryptedKeyBytes = base64.decode(encryptedKey);
      
      setState(() {
        _decryptedResult += '\n\nStarting RSA decrypt...';
        _decryptedResult += '\nEncrypted key bytes: ${encryptedKeyBytes.length}';
      });
      
      final rsaDecryptResult = await SecureEnclave().decrypt(
        tag: tag,
        message: Uint8List.fromList(encryptedKeyBytes),
      );

      if (rsaDecryptResult.error != null || rsaDecryptResult.value == null) {
        setState(() {
          _decryptedResult += '\n\n❌ RSA Decrypt Failed!';
          _decryptedResult += '\nError: ${rsaDecryptResult.error?.desc ?? "Unknown error"}';
          _decryptedResult += '\n\n💡 Possible solutions:';
          _decryptedResult += '\n1. Generate a new certificate in "Generate Cert"';
          _decryptedResult += '\n2. Use real encrypted data from your server';
          _decryptedResult += '\n3. This sample data might not match your private key';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _decryptedResult += '\n\n✅ RSA Decrypt Success!';
      });

      // The decrypted AES key is now base64 encoded by our decrypt method
      final aesKeyString = rsaDecryptResult.value!;
      final aesKeyBytes = base64.decode(aesKeyString);

      setState(() {
        _decryptedResult += '\nAES Key length: ${aesKeyBytes.length} bytes';
        _decryptedResult += '\nAES Key (base64): ${aesKeyString.substring(0, 20)}...';
        _decryptedResult += '\n\n🔍 Starting AES decrypt with optimized logic...';
        _decryptedResult += '\n• Server updated: IV + encrypted data format';
        _decryptedResult += '\n• Expected format: [IV 16 bytes][Encrypted Data]';
      });

      // Step 2: Decrypt the payload using AES
      final encryptedDataBytes = base64.decode(encryptedData);
      
      setState(() {
        _decryptedResult += '\nEncrypted data bytes length: ${encryptedDataBytes.length}';
        _decryptedResult += '\nFirst 16 bytes (IV hex): ${encryptedDataBytes.take(16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}';
        _decryptedResult += '\nNext 16 bytes (data hex): ${encryptedDataBytes.skip(16).take(16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}';
      });
      
      final aesDecryptResult = await SecureEnclave().decryptWithAES(
        encryptedData: Uint8List.fromList(encryptedDataBytes),
        aesKey: Uint8List.fromList(aesKeyBytes),
      );

      if (aesDecryptResult.error == null && aesDecryptResult.value != null) {
        final decryptedText = aesDecryptResult.value!;
        setState(() {
          _decryptedResult += '\n\n✅ AES Decrypt Success!';
          _decryptedResult += '\n🔓 IV Successfully Extracted and Used';
          _decryptedResult += '\nDecrypted length: ${decryptedText.length} characters';
          _decryptedResult += '\nFirst 50 chars: ${decryptedText.length > 50 ? decryptedText.substring(0, 50) + '...' : decryptedText}';
          _decryptedResult += '\n\n🎉 COMPLETE SUCCESS!';
          _decryptedResult += '\n\n📋 Results:';
          _decryptedResult += '\n• Used Tag: $tag';
          _decryptedResult += '\n• IV + Data Format: Confirmed ✅';
          _decryptedResult += '\n• Decrypted AES Key: ${aesKeyString.substring(0, 20)}...';
          _decryptedResult += '\n\n• Full Decrypted Payload:';
          _decryptedResult += '\n${decryptedText}';
        });
      } else {
        setState(() {
          _decryptedResult += '\n\n❌ AES Decrypt Failed!';
          _decryptedResult += '\nError: ${aesDecryptResult.error?.desc ?? "Unknown error"}';
        });
      }
    } catch (e) {
      setState(() {
        _decryptedResult += '\n\n💥 Exception caught: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AES Decrypt Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display current tag from DeviceInfoProvider
            Consumer<DeviceInfoProvider>(
              builder: (context, deviceInfoProvider, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Tag:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deviceInfoProvider.tag.isEmpty 
                          ? 'No tag available. Generate certificate first.' 
                          : deviceInfoProvider.tag,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: deviceInfoProvider.tag.isEmpty 
                            ? Colors.red 
                            : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _encryptedKeyController,
                decoration: const InputDecoration(
                  labelText: 'Encrypted JSON Response',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAESDecrypt,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Decrypt AES Data'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _decryptedResult.isEmpty ? 'Result will appear here...' : _decryptedResult,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _encryptedKeyController.dispose();
    _encryptedDataController.dispose();
    super.dispose();
  }
}