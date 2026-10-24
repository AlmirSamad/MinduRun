import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Fingerprint of the evidence image bytes, used to block the same
/// screenshot from being submitted twice in a competition.
String evidenceHash(Uint8List bytes) => sha256.convert(bytes).toString();
