import 'dart:typed_data';

/// Whole seconds of an Ogg Vorbis file, rounded down.
///
/// [head] is the start of the file, enough to hold the identification
/// header. [tail] is the end of the file when the recording is longer than
/// [head]. A file that is not Vorbis returns null, and the caller leaves
/// the session cap alone.
int? oggVorbisDurationSeconds(List<int> head, {List<int>? tail}) {
  final rate = _vorbisSampleRate(head);
  if (rate == null || rate <= 0) return null;
  final pages = _oggPages(tail ?? head);
  int? samples;
  for (final page in pages) {
    if (page.granule >= 0) samples = page.granule;
  }
  if (samples == null || samples <= 0) return null;
  final whole = samples ~/ rate;
  return whole < 1 ? 1 : whole;
}

/// Reads only the identification header and the last pages.
int? oggVorbisDurationOf(Uint8List bytes) {
  if (bytes.length < 64) return null;
  if (bytes.length <= 65536) return oggVorbisDurationSeconds(bytes);
  final head = bytes.sublist(0, 65536);
  final tailStart = bytes.length - 80000;
  return oggVorbisDurationSeconds(
    head,
    tail: bytes.sublist(tailStart < 0 ? 0 : tailStart),
  );
}

int? _vorbisSampleRate(List<int> bytes) {
  final pages = _oggPages(bytes);
  if (pages.isEmpty) return null;
  final payload = pages.first.payload;
  if (payload.length < 16 || payload[0] != 1) return null;
  const mark = <int>[0x76, 0x6F, 0x72, 0x62, 0x69, 0x73];
  for (var i = 0; i < mark.length; i++) {
    if (payload[i + 1] != mark[i]) return null;
  }
  final rate = _u32(payload, 12);
  if (rate < 8000 || rate > 192000) return null;
  return rate;
}

class _OggPage {
  const _OggPage(this.granule, this.payload, this.size);

  final int granule;
  final List<int> payload;
  final int size;
}

List<_OggPage> _oggPages(List<int> bytes) {
  final pages = <_OggPage>[];
  var index = 0;
  while (index + 27 <= bytes.length) {
    final page = _pageAt(bytes, index);
    if (page == null) {
      index += 1;
      continue;
    }
    pages.add(page);
    index += page.size;
  }
  return pages;
}

_OggPage? _pageAt(List<int> bytes, int index) {
  if (index + 27 > bytes.length) return null;
  if (bytes[index] != 0x4F ||
      bytes[index + 1] != 0x67 ||
      bytes[index + 2] != 0x67 ||
      bytes[index + 3] != 0x53 ||
      bytes[index + 4] != 0) {
    return null;
  }
  final segments = bytes[index + 26];
  final header = 27 + segments;
  if (index + header > bytes.length) return null;
  var body = 0;
  for (var i = 0; i < segments; i++) {
    body += bytes[index + 27 + i];
  }
  final size = header + body;
  if (index + size > bytes.length) return null;
  final raw = Uint8List(size);
  for (var i = 0; i < size; i++) {
    raw[i] = bytes[index + i];
  }
  final expect = _u32(bytes, index + 22);
  raw[22] = 0;
  raw[23] = 0;
  raw[24] = 0;
  raw[25] = 0;
  if (_oggCrc(raw) != expect) return null;
  return _OggPage(
    _i64(bytes, index + 6),
    bytes.sublist(index + header, index + size),
    size,
  );
}

int _u32(List<int> bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

int _i64(List<int> bytes, int offset) {
  // Bit 63 marks the Ogg "no packet finished" granule, which is -1.
  // A recording long enough to set that bit is not a pack this app stores.
  if (bytes[offset + 7] >= 0x80) return -1;
  var value = 0;
  for (var i = 0; i < 8; i++) {
    value |= bytes[offset + i] << (8 * i);
  }
  return value;
}

final List<int> _crcTable = _buildCrcTable();

List<int> _buildCrcTable() {
  final table = List<int>.filled(256, 0);
  for (var i = 0; i < 256; i++) {
    var remainder = i << 24;
    for (var bit = 0; bit < 8; bit++) {
      if ((remainder & 0x80000000) != 0) {
        remainder = ((remainder << 1) ^ 0x04C11DB7) & 0xFFFFFFFF;
      } else {
        remainder = (remainder << 1) & 0xFFFFFFFF;
      }
    }
    table[i] = remainder;
  }
  return table;
}

int _oggCrc(Uint8List data) {
  var crc = 0;
  for (final byte in data) {
    final index = ((crc >> 24) & 0xFF) ^ byte;
    crc = ((crc << 8) & 0xFFFFFFFF) ^ _crcTable[index];
  }
  return crc;
}
