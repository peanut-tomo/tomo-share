import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tomo_share_method_channel.dart';

abstract class TomoSharePlatform extends PlatformInterface {
  /// Constructs a TomoSharePlatform.
  TomoSharePlatform() : super(token: _token);

  static final Object _token = Object();

  static TomoSharePlatform _instance = MethodChannelTomoShare();

  /// The default instance of [TomoSharePlatform] to use.
  ///
  /// Defaults to [MethodChannelTomoShare].
  static TomoSharePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TomoSharePlatform] when
  /// they register themselves.
  static set instance(TomoSharePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> shareTelegram({required String text, String? imageFile}) {
    throw UnimplementedError('shareTelegram() has not been implemented.');
  }
}
