import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/services/activity_input.dart';

void main() {
  test('distance accepts dot and comma with surrounding whitespace', () {
    for (final input in ['5.23', '5,23', ' 5,23 ']) {
      expect(ActivityInput.parseDistance(input), 5.23);
    }
  });
  test(
    'distance rejects empty, zero, negative, nonfinite and malformed values',
    () {
      for (final input in [
        '',
        '0',
        '-1',
        'NaN',
        'Infinity',
        '1,2.3',
        'abc',
        '1e309',
      ]) {
        expect(ActivityInput.parseDistance(input), isNull, reason: input);
      }
    },
  );
  test('duration supports MM:SS and HH:MM:SS', () {
    expect(ActivityInput.parseDuration('31:45'), 1905);
    expect(ActivityInput.parseDuration('00:31:45'), 1905);
    expect(ActivityInput.parseDuration('01:01:01'), 3661);
    expect(ActivityInput.parseDuration('60:00'), 3600);
  });
  test('duration rejects invalid minutes, seconds and formats', () {
    for (final input in [
      '',
      '00:00',
      '00:00:00',
      '-1:00',
      '31:60',
      '00:60:00',
      '31',
      '1:2',
      'abc',
    ]) {
      expect(ActivityInput.parseDuration(input), isNull, reason: input);
    }
  });
  test('pace supports MM:SS and rejects invalid input', () {
    expect(ActivityInput.parsePace('06:04'), 364);
    for (final input in ['', '00:00', '06:60', '-6:04', '00:06:04', 'abc']) {
      expect(ActivityInput.parsePace(input), isNull, reason: input);
    }
  });
  test('formats metric values consistently', () {
    expect(ActivityInput.formatDistance(5.23), '5,23 km');
    expect(ActivityInput.formatDuration(1905), '31:45');
    expect(ActivityInput.formatDuration(3661), '01:01:01');
    expect(ActivityInput.formatPace(364), '06:04/km');
  });
}
