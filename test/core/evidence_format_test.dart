import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/features/activities/evidence_picker.dart';

void main() {
  test('only PNG JPEG and WebP signatures pass the format guard', () {
    for (final signature in [
      [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
      [0xff, 0xd8, 0xff],
      [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50],
    ]) {
      expect(isSupportedEvidenceImage(Uint8List.fromList(signature)), isTrue);
    }
    for (final signature in [
      <int>[],
      [1, 2, 3],
      'GIF89a'.codeUnits,
      'not an image'.codeUnits,
    ]) {
      expect(isSupportedEvidenceImage(Uint8List.fromList(signature)), isFalse);
    }
  });
}
