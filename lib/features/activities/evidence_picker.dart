import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bound at bootstrap; widget tests provide image bytes through this seam.
final evidencePickerProvider = Provider<Future<Uint8List?> Function()>(
  (ref) =>
      () => Future.error(
        UnsupportedError('O seletor de imagens não foi inicializado.'),
      ),
);

const maxEvidenceBytes = 10 * 1024 * 1024;

/// Check the actual container signature; picker filters alone are not validation.
bool isSupportedEvidenceImage(Uint8List bytes) {
  bool startsWith(List<int> signature, [int offset = 0]) {
    if (bytes.length < offset + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[offset + i] != signature[i]) return false;
    }
    return true;
  }

  return startsWith(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]) ||
      startsWith(const [0xff, 0xd8, 0xff]) ||
      (startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
          startsWith(const [0x57, 0x45, 0x42, 0x50], 8));
}
