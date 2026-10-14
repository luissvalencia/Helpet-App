import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  bool _googleSignInInitialized = false;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    String? telefono,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'telefono': telefono,
      'ciudad': null,
      'direccionReferencia': null,
      'rol': 'ciudadano',
      'fcmToken': null,
      'notifCoincidencias': true,
      'notifReportesCercanos': true,
      'creadoEn': FieldValue.serverTimestamp(),
    });

    // No bloqueante: si falla el envío, el usuario igual queda registrado y
    // puede reenviarlo después desde Perfil.
    await credential.user!.sendEmailVerification();
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> resendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<bool> reloadAndCheckEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    if (!_googleSignInInitialized) {
      await googleSignIn.initialize();
      _googleSignInInitialized = true;
    }

    final account = await googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'No se pudo obtener el token de Google',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'nombre': user.displayName ?? account.displayName ?? 'Usuario',
        'telefono': null,
        'ciudad': null,
        'direccionReferencia': null,
        'rol': 'ciudadano',
        'fcmToken': null,
        'notifCoincidencias': true,
        'notifReportesCercanos': true,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> logout() async {
    // Sin esto, el token del dispositivo se queda en el doc de la cuenta
    // que cierra sesión — si luego otra cuenta inicia sesión en el mismo
    // dispositivo, un push dirigido a la cuenta anterior igual llega aquí
    // (el token identifica al dispositivo/instalación, no a la sesión
    // activa), mostrando una notificación que no le correspondía a quien
    // la ve.
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).update({'fcmToken': null});
      } catch (_) {
        // Best-effort: no bloquea el logout si falla (ej. sin conexión) — el
        // próximo login sobrescribe el token de todas formas.
      }
    }
    await _auth.signOut();
  }
}
