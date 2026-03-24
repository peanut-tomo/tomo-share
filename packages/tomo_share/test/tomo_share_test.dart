import 'package:flutter_test/flutter_test.dart';
import 'package:tomo_share/tomo_share.dart';
import 'package:tomo_share/tomo_share_platform_interface.dart';
import 'package:tomo_share/tomo_share_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTomoSharePlatform
    with MockPlatformInterfaceMixin
    implements TomoSharePlatform {
  bool shareTelegramCalled = false;
  String? lastText;
  String? lastImageFile;

  @override
  Future<void> shareTelegram({required String text, String? imageFile}) async {
    shareTelegramCalled = true;
    lastText = text;
    lastImageFile = imageFile;
  }
}

void main() {
  final TomoSharePlatform initialPlatform = TomoSharePlatform.instance;

  test('$MethodChannelTomoShare is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTomoShare>());
  });

  test('shareTelegram delegates to the active platform', () async {
    MockTomoSharePlatform fakePlatform = MockTomoSharePlatform();
    TomoSharePlatform.instance = fakePlatform;

    await TomoShare.instance.shareTelegram(
      text: 'hello telegram',
      imageFile: '/tmp/share.png',
    );

    expect(fakePlatform.shareTelegramCalled, isTrue);
    expect(fakePlatform.lastText, 'hello telegram');
    expect(fakePlatform.lastImageFile, '/tmp/share.png');
  });
}
