const crypto = require("crypto");

function verifyInternalKey(req, res, next) {
  const expected = process.env.INTERNAL_API_KEY || "";
  const received = req.headers["x-internal-api-key"] || "";

  const expectedBuf = Buffer.from(expected);
  const receivedBuf = Buffer.from(received);

  const coincide =
    expected.length > 0 &&
    expectedBuf.length === receivedBuf.length &&
    crypto.timingSafeEqual(expectedBuf, receivedBuf);

  if (!coincide) {
    return res.status(401).json({ error: "No autorizado" });
  }
  next();
}

module.exports = { verifyInternalKey };
