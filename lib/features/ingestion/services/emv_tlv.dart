/// EMVCo / BOT TLV helpers used by Thai QR Payment and slip-verify Mini-QR.
///
/// Wire format is `ID(2) + LEN(2) + VALUE(len)` repeated. Length is a
/// character count, matching Thai bank app implementations (promptparse).
class EmvTag {
  final String id;
  final String value;

  const EmvTag(this.id, this.value);

  int get length => value.length;
}

class EmvTlv {
  EmvTlv._();

  static List<EmvTag> decode(String payload) {
    final tags = <EmvTag>[];
    var idx = 0;
    while (idx + 4 <= payload.length) {
      final id = payload.substring(idx, idx + 2);
      final len = int.tryParse(payload.substring(idx + 2, idx + 4));
      if (len == null || len < 0) break;
      final start = idx + 4;
      final end = start + len;
      if (end > payload.length) break;
      tags.add(EmvTag(id, payload.substring(start, end)));
      idx = end;
    }
    return tags;
  }

  static String encode(List<EmvTag> tags) {
    final buffer = StringBuffer();
    for (final tag in tags) {
      buffer.write(tag.id);
      buffer.write(tag.length.toString().padLeft(2, '0'));
      buffer.write(tag.value);
    }
    return buffer.toString();
  }

  static String? valueOf(List<EmvTag> tags, String id) {
    for (final tag in tags) {
      if (tag.id == id) return tag.value;
    }
    return null;
  }

  static List<EmvTag> nested(List<EmvTag> tags, String id) {
    final value = valueOf(tags, id);
    if (value == null || value.length < 4) return const [];
    return decode(value);
  }

  static String nestedValue(List<EmvTag> tags, String id, String subId) {
    return valueOf(nested(tags, id), subId) ?? '';
  }

  /// CRC-16/XMODEM (poly 0x1021, init 0xFFFF) — used by EMVCo QR tag 63
  /// and BOT slip-verify tag 91.
  static String checksum(String payload, {bool upperCase = true}) {
    var crc = 0xFFFF;
    for (final unit in payload.codeUnits) {
      crc ^= (unit << 8);
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    final hex = crc.toRadixString(16).padLeft(4, '0');
    return upperCase ? hex.toUpperCase() : hex.toLowerCase();
  }

  /// Appends `{crcTagId}04{crc}` where CRC covers the payload plus that header.
  static String withCrc(String payload, String crcTagId, {bool upperCase = true}) {
    final withHeader = '$payload$crcTagId'
        '04';
    return '$withHeader${checksum(withHeader, upperCase: upperCase)}';
  }

  /// Returns true when the trailing CRC tag matches. Banks sometimes emit a
  /// truncated CRC — those payloads still parse, they just fail this check.
  static bool validateCrc(String payload, {String crcTagId = '63'}) {
    final marker = '${crcTagId}04';
    final idx = payload.lastIndexOf(marker);
    if (idx < 0 || idx + 6 > payload.length) return false;
    final given = payload.substring(idx + 4);
    if (given.length != 4) return false;
    final expected = checksum(payload.substring(0, idx + 4), upperCase: false);
    return given.toLowerCase() == expected.toLowerCase();
  }
}
