import 'package:flutter/material.dart';

class DeviceInfoProvider extends ChangeNotifier {
  String _deviceId = '';
  String _tag = '';

  String get deviceId => _deviceId;
  String get tag => _tag;
  String get clientKey => "$_deviceId$_tag";

  void setDeviceId(String deviceId) {
    _deviceId = deviceId;
    notifyListeners(); // State değişikliğini dinleyen widget'ları günceller
  }

  void setTag(String tag) {
    _tag = tag;
    notifyListeners();
  }
}