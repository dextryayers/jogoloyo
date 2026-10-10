// F4.1 Foto kamera wajib plus kompresi maks 2 MB.
// Aturan: pengajuan awal wajib dari kamera, bukan galeri, agar asli.
// Kompresi: max sisi 1280, JPG 85, tolak jika hasil di bawah 20 KB (buram) atau di atas 2 MB.
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class PhotoError implements Exception {
  final String message;
  PhotoError(this.message);
  @override
  String toString() => message;
}

class PhotoService {
  final _picker = ImagePicker();

  Future<String> takeProfilePhoto() async {
    final x = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if (x == null) throw PhotoError('Pengambilan foto dibatalkan.');
    return _process(File(x.path), prefix: 'profil');
  }

  Future<String> takeIdPhoto() async {
    final x = await _picker.pickImage(source: ImageSource.camera);
    if (x == null) throw PhotoError('Pengambilan foto identitas dibatalkan.');
    return _process(File(x.path), prefix: 'identitas');
  }

  Future<String> _process(File src, {required String prefix}) async {
    final bytes = await src.readAsBytes();
    final dec = img.decodeImage(bytes);
    if (dec == null) throw PhotoError('File rusak. Ulangi di cahaya terang.');
    if (dec.width < 400 || dec.height < 400) {
      throw PhotoError('Foto buram atau terlalu kecil. Ulangi di cahaya terang dengan jilbab menutup rambut.');
    }
    var out = dec;
    if (out.width > 1280 || out.height > 1280) {
      out = img.copyResize(out, width: out.width >= out.height ? 1280 : null, height: out.width < out.height ? 1280 : null);
    }
    final jpg = img.encodeJpg(out, quality: 85);
    if (jpg.length < 20000) {
      throw PhotoError('Foto buram. Ulangi di cahaya terang dengan jilbab menutup rambut.');
    }
    if (jpg.length > 2 * 1024 * 1024) {
      final jpg70 = img.encodeJpg(out, quality: 70);
      if (jpg70.length > 2 * 1024 * 1024) {
        throw PhotoError('Foto terlalu besar. Mendekat dan ulangi tanpa latar ramai.');
      }
      return _save(jpg70, prefix);
    }
    return _save(jpg, prefix);
  }

  Future<String> _save(List<int> bytes, String prefix) async {
    final d = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(d.path, 'teacher_photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = '${prefix}_${const Uuid().v4()}.jpg';
    final f = File(p.join(dir.path, name));
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }
}
