import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  StorageRepository(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadFotoReporte({required File file, required String uid}) async {
    return _upload(carpeta: 'reportes', file: file, uid: uid);
  }

  Future<String> uploadFotoMascota({required File file, required String uid}) async {
    return _upload(carpeta: 'mascotas', file: file, uid: uid);
  }

  Future<String> uploadFotoPerfil({required File file, required String uid}) async {
    return _upload(carpeta: 'perfiles', file: file, uid: uid);
  }

  Future<String> _upload({required String carpeta, required File file, required String uid}) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('$carpeta/$uid/$fileName');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }
}
