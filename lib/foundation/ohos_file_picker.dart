import 'package:flutter/services.dart';

import 'log.dart';
import 'platform_utils.dart';

class OhosFilePicker {
  static const MethodChannel _channel = MethodChannel('pica_comic/ohos_file_picker');

  static Future<String?> pickPicadataFile() async {
    if (!PlatformUtils.isOhos) {
      return null;
    }
    try {
      final path = await _channel.invokeMethod<String>('pickPicadata');
      return path;
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, 'FilePicker', 'Failed to pick file on OHOS\n$e\n$s');
      return null;
    }
  }
}
