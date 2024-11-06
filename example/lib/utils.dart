import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
// import 'package:uuid/uuid.dart';


Future<String> getDeviceId() async {
  String deviceId = '';
  try {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      deviceId = androidInfo.id ?? ''; // Cihazın benzersiz Android kimliği
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? ''; // Cihazın benzersiz iOS kimliği
    }
  } catch (e) {
    // var uuid = const Uuid();
    // deviceId = uuid.v4();
    deviceId = "9b3e10a7-d11b-410d-b609-5a5c7a4a5eda";
  }
  

  return deviceId;
}