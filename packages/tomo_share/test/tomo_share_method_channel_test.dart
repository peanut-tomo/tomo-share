import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo_share/tomo_share_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = <MethodCall>[];
  MethodChannelTomoShare platform = MethodChannelTomoShare();
  const MethodChannel channel = MethodChannel('tomo_share');

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('shareTelegram sends a platform method call', () async {
    await platform.shareTelegram(
      text: 'hello telegram',
      imageFile: '/tmp/share.png',
    );

    expect(log, <Matcher>[
      isMethodCall(
        'shareTelegram',
        arguments: <String, Object?>{
          'text': 'hello telegram',
          'imageFile': '/tmp/share.png',
        },
      ),
    ]);
  });
}
