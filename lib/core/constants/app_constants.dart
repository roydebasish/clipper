enum ClipboardType {
  text,
  url,
  image,
  file,
  color,
  richText,
  unknown;

  static ClipboardType fromString(String type) {
    switch (type.toUpperCase()) {
      case 'TEXT':
        return ClipboardType.text;
      case 'URL':
        return ClipboardType.url;
      case 'IMAGE':
        return ClipboardType.image;
      case 'FILE':
        return ClipboardType.file;
      case 'COLOR':
        return ClipboardType.color;
      case 'RICH_TEXT':
        return ClipboardType.richText;
      default:
        return ClipboardType.unknown;
    }
  }

  String get label {
    switch (this) {
      case ClipboardType.text:
        return 'Text';
      case ClipboardType.url:
        return 'Link';
      case ClipboardType.image:
        return 'Image';
      case ClipboardType.file:
        return 'File';
      case ClipboardType.color:
        return 'Color';
      case ClipboardType.richText:
        return 'Rich Text';
      case ClipboardType.unknown:
        return 'Other';
    }
  }
}

class AppConstants {
  static const String methodChannelName = 'com.clipper/methods';
  static const String eventChannelName = 'com.clipper/events';
  
  static const String appName = 'Clipper';
}
