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

  /// Borra una foto ya subida que no se va a usar (ej. el backend la rechazó
  /// por no mostrar un perro o un gato). Best-effort: si falla, solo queda
  /// un archivo huérfano en Storage, no hay nada que mostrarle al usuario.
  Future<void> eliminarPorUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }

  Future<String> _upload({required String carpeta, required File file, required String uid}) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('$carpeta/$uid/$fileName');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }
}
