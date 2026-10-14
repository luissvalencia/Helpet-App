const AppError = require("../utils/AppError");

function validate(schema, source = "body") {
  return (req, res, next) => {
    const result = schema.safeParse(req[source]);
    if (!result.success) {
      const message = result.error.issues[0]?.message || "Datos inválidos";
      return next(new AppError(400, message));
    }
    req[source] = result.data;
    next();
  };
}

module.exports = validate;
