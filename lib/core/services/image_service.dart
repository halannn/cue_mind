import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum ImageSourceType { camera, gallery }

class ImageService {
  final _picker = ImagePicker();

  Future<String?> pickAndSave() async {
    return pickFromSource(ImageSourceType.gallery);
  }

  Future<String?> pickFromSource(ImageSourceType source) async {
    final imageSource = source == ImageSourceType.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    final xfile = await _picker.pickImage(
      source: imageSource,
      imageQuality: 85,
    );
    if (xfile == null) return null;

    final dir = await getApplicationDocumentsDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = p.extension(xfile.path);
    final name = 'photo_$timestamp$ext';
    final dest = File(p.join(dir.path, name));

    await File(xfile.path).copy(dest.path);
    return dest.path;
  }
}
