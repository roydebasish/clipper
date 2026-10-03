import 'dart:convert';

enum TransformationType {
  uppercase('Uppercase', 'CONVERT ALL TO UPPERCASE'),
  lowercase('Lowercase', 'convert all to lowercase'),
  trim('Trim Whitespace', 'Remove leading and trailing spaces'),
  removeEmptyLines('Remove Empty Lines', 'Strip out blank empty lines'),
  removeLineBreaks('Remove Line Breaks', 'Combine all lines into one single line'),
  sortLines('Sort Lines A-Z', 'Sort lines alphabetically'),
  jsonFormat('JSON Format (Beautify)', 'Prettify and indent JSON'),
  jsonMinify('JSON Minify', 'Compress and compact JSON'),
  urlEncode('URL Encode', 'Percent-encode special characters'),
  urlDecode('URL Decode', 'Decode percent-encoded URL'),
  base64Encode('Base64 Encode', 'Encode UTF-8 string to Base64'),
  base64Decode('Base64 Decode', 'Decode Base64 string to plain text');

  final String title;
  final String subtitle;
  const TransformationType(this.title, this.subtitle);
}

class TextTransformations {
  static String apply(String input, TransformationType type) {
    switch (type) {
      case TransformationType.uppercase:
        return input.toUpperCase();

      case TransformationType.lowercase:
        return input.toLowerCase();

      case TransformationType.trim:
        return input.trim();

      case TransformationType.removeEmptyLines:
        return input
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .join('\n');

      case TransformationType.removeLineBreaks:
        return input
            .replaceAll('\r\n', ' ')
            .replaceAll('\n', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

      case TransformationType.sortLines:
        final lines = input.split('\n');
        lines.sort();
        return lines.join('\n');

      case TransformationType.jsonFormat:
        try {
          final dynamic parsed = jsonDecode(input);
          const encoder = JsonEncoder.withIndent('  ');
          return encoder.convert(parsed);
        } catch (_) {
          return input; // Return original if not valid JSON
        }

      case TransformationType.jsonMinify:
        try {
          final dynamic parsed = jsonDecode(input);
          return jsonEncode(parsed);
        } catch (_) {
          return input;
        }

      case TransformationType.urlEncode:
        return Uri.encodeComponent(input);

      case TransformationType.urlDecode:
        try {
          return Uri.decodeComponent(input);
        } catch (_) {
          return input;
        }

      case TransformationType.base64Encode:
        try {
          return base64Encode(utf8.encode(input));
        } catch (_) {
          return input;
        }

      case TransformationType.base64Decode:
        try {
          return utf8.decode(base64Decode(input.trim()));
        } catch (_) {
          return input;
        }
    }
  }
}
