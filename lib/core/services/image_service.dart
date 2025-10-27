import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// service sederhana untuk ambil & simpan gambar lokal
class ImageService {
  final _picker = ImagePicker();

  Future<String?> pickAndSave() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final name = p.basename(xfile.path);
    final dest = File(p.join(dir.path, name));

    await File(xfile.path).copy(dest.path);
    return dest.path;
  }
}
