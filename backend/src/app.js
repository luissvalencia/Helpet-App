const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");

const healthRoutes = require("./routes/health.routes");
const usersRoutes = require("./routes/users.routes");
const adminRoutes = require("./routes/admin.routes");
const reportesRoutes = require("./routes/reportes.routes");
const coincidenciasRoutes = require("./routes/coincidencias.routes");
const mascotasRoutes = require("./routes/mascotas.routes");
const notificacionesRoutes = require("./routes/notificaciones.routes");
const errorHandler = require("./middlewares/errorHandler");
const logger = require("./utils/logger");

const app = express();

// Cloud Run corre detrás de un proxy — sin esto, express-rate-limit y
// req.ip identifican al proxy en vez del cliente real.
app.set("trust proxy", 1);

const corsOrigin = process.env.CORS_ORIGIN;
if (corsOrigin) {
  const whitelist = corsOrigin.split(",").map((origin) => origin.trim());
  app.use(cors({ origin: whitelist }));
} else {
  // Sin CORS_ORIGIN seteada, se mantiene abierto (comportamiento histórico):
  // el cliente principal es la app Flutter, que no envía Origin y no aplica
  // política CORS. Restringir aquí solo importa si se agrega un cliente web.
  logger.warn("CORS_ORIGIN no está seteada — aceptando cualquier origen");
  app.use(cors());
}

app.use(helmet());
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 300,
    standardHeaders: true,
    legacyHeaders: false,
  })
);

app.use(express.json());
app.use(morgan("dev"));

app.use(healthRoutes);
app.use("/users", usersRoutes);
app.use("/admin", adminRoutes);
app.use("/reportes", reportesRoutes);
app.use("/coincidencias", coincidenciasRoutes);
app.use("/mascotas", mascotasRoutes);
app.use("/notificaciones", notificacionesRoutes);

app.use((req, res) => {
  res.status(404).json({ error: "Ruta no encontrada" });
});

app.use(errorHandler);

module.exports = app;
