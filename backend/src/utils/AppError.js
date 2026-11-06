class AppError extends Error {
  // `codigo` (opcional) permite que la app distinga casos que debe manejar
  // distinto de un error genérico, ej. "especie_distinta" (preguntar y
  // reenviar) vs. "foto_sin_mascota" (pedir otra foto).
  constructor(status, message, codigo) {
    super(message);
    this.status = status;
    this.codigo = codigo;
    this.isOperational = true;
  }
}

module.exports = AppError;
