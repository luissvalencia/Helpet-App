import firebase_admin
from firebase_admin import credentials


class _FakeCredential(credentials.Base):
    """Evita que importar app.firebase_client dispare ApplicationDefault()
    (que busca credenciales reales) al correr los tests. Ninguna prueba de
    este paquete habla con un Firestore real: donde hace falta, se mockea
    `db` directamente."""

    def get_credential(self):
        import google.auth.credentials as gac

        return gac.AnonymousCredentials()


if not firebase_admin._apps:
    firebase_admin.initialize_app(credential=_FakeCredential(), options={"projectId": "demo-helpet-tests"})
