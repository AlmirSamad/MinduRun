import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import 'evidence_picker.dart';

/// Platform adapter: only bytes leave the picker, never a device file path.
Future<Uint8List?> pickScreenshotBytes() async {
  const images = XTypeGroup(
    label: 'Screenshots',
    extensions: ['png', 'jpg', 'jpeg', 'webp'],
    mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
    uniformTypeIdentifiers: [
      'public.png',
      'public.jpeg',
      'org.webmproject.webp',
    ],
  );
  final file = await openFile(acceptedTypeGroups: [images]);
  if (file == null) return null;
  if (await file.length() > maxEvidenceBytes) {
    throw const FormatException('Escolha uma imagem de até 10 MB.');
  }
  return file.readAsBytes();
}
