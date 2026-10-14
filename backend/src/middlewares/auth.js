const { auth } = require("../config/firebase");

async function verifyToken(req, res, next) {
  const header = req.headers.authorization || "";
  const [scheme, token] = header.split(" ");

  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({ error: "Token de autenticación faltante" });
  }

  try {
    const decodedToken = await auth.verifyIdToken(token, true);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      rol: decodedToken.rol || null,
    };
    next();
  } catch (_err) {
    return res.status(401).json({ error: "Token de autenticación inválido" });
  }
}

function requireAdmin(req, res, next) {
  if (req.user?.rol !== "admin") {
    return res.status(403).json({ error: "Requiere rol de administrador" });
  }
  next();
}

module.exports = { verifyToken, requireAdmin };
