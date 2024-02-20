part of 'app.dart';

class ImageInfo {
  final Uint8List data;
  final Size size;

  const ImageInfo({
    required this.data,
    required this.size,
  });

  @override
  bool operator ==(covariant ImageInfo other) {
    if (identical(this, other)) return true;

    return other.data == data && other.size == size;
  }

  @override
  int get hashCode => data.hashCode ^ size.hashCode;

  ImageInfo copyWith({
    Uint8List? data,
    Size? size,
  }) {
    return ImageInfo(
      data: data ?? this.data,
      size: size ?? this.size,
    );
  }

  static Future<ImageInfo> fromFile(File file) async {
    final Uint8List bytes = await file.readAsBytes();

    final ui.Image image = await decodeImageFromList(bytes);

    return ImageInfo(
      data: bytes,
      size: Size(
        image.width.toDouble(),
        image.height.toDouble(),
      ),
    );
  }

  static Future<List<ImageInfo>> listFromFiles(List<File> files) async {
    final List<ImageInfo> result = [
      for (final File x in files) await ImageInfo.fromFile(x),
    ];

    return result;
  }
}
