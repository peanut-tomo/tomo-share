import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tomo_share_platform_interface.dart';

/// An implementation of [TomoSharePlatform] that uses method channels.
class MethodChannelTomoShare extends TomoSharePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tomo_share');

  @override
  Future<void> shareTelegram({required String text, String? imageFile}) {
    return methodChannel.invokeMethod<void>('shareTelegram', <String, Object?>{
      'text': text,
      'imageFile': imageFile,
    });
  }
}
