import 'tomo_share_platform_interface.dart';

class TomoShare {
  TomoShare._();

  static final TomoShare instance = TomoShare._();

  Future<void> shareTelegram({required String text, String? imageFile}) {
    final normalizedText = text.trim();
    final normalizedImageFile = imageFile?.trim();

    if (normalizedText.isEmpty) {
      throw ArgumentError.value(text, 'text', 'text must not be empty');
    }

    return TomoSharePlatform.instance.shareTelegram(
      text: normalizedText,
      imageFile: normalizedImageFile == null || normalizedImageFile.isEmpty
          ? null
          : normalizedImageFile,
    );
  }
}
