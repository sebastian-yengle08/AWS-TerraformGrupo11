const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const Busboy = require("busboy");
const { v4: uuidv4 } = require("uuid");

const s3 = new S3Client({});

const MAX_UPLOAD_MB = Number(process.env.MAX_UPLOAD_MB || 4);
const MAX_UPLOAD_BYTES = MAX_UPLOAD_MB * 1024 * 1024;

function jsonResponse(statusCode, data) {
  return {
    statusCode,
    headers: {
      "content-type": "application/json"
    },
    body: JSON.stringify(data)
  };
}

function detectImageType(buffer) {
  if (!Buffer.isBuffer(buffer)) {
    return null;
  }

  if (
    buffer.length >= 3 &&
    buffer.subarray(0, 3).equals(Buffer.from([0xff, 0xd8, 0xff]))
  ) {
    return { extension: "jpg", contentType: "image/jpeg" };
  }

  if (
    buffer.length >= 8 &&
    buffer.subarray(0, 8).equals(
      Buffer.from("89504e470d0a1a0a", "hex")
    )
  ) {
    return { extension: "png", contentType: "image/png" };
  }

  if (
    buffer.length >= 6 &&
    ["GIF87a", "GIF89a"].includes(buffer.toString("ascii", 0, 6))
  ) {
    return { extension: "gif", contentType: "image/gif" };
  }

  if (
    buffer.length >= 12 &&
    buffer.toString("ascii", 0, 4) === "RIFF" &&
    buffer.toString("ascii", 8, 12) === "WEBP"
  ) {
    return { extension: "webp", contentType: "image/webp" };
  }

  return null;
}

function readImageFromForm(body, contentType) {
  return new Promise((resolve) => {
    let parser;

    try {
      parser = Busboy({
        headers: {
          "content-type": contentType
        },
        limits: {
          files: 1,
          fileSize: MAX_UPLOAD_BYTES,
          fields: 5,
          parts: 6
        }
      });
    } catch {
      resolve({ statusCode: 400, message: "Formulario invalido" });
      return;
    }

    let imageBuffer = null;
    let tooLarge = false;
    let invalidForm = false;

    parser.on("file", (fieldname, file) => {
      const chunks = [];

      file.on("data", (chunk) => {
        chunks.push(chunk);
      });

      file.on("limit", () => {
        tooLarge = true;
      });

      file.on("end", () => {
        imageBuffer = Buffer.concat(chunks);
      });

      file.on("error", () => {
        invalidForm = true;
      });
    });

    parser.on("filesLimit", () => {
      invalidForm = true;
    });

    parser.on("fieldsLimit", () => {
      invalidForm = true;
    });

    parser.on("partsLimit", () => {
      invalidForm = true;
    });

    parser.on("error", () => {
      resolve({ statusCode: 400, message: "Formulario invalido" });
    });

    parser.on("close", () => {
      if (tooLarge) {
        resolve({ statusCode: 413, message: "Imagen demasiado grande" });
        return;
      }

      if (invalidForm || !imageBuffer || imageBuffer.length === 0) {
        resolve({ statusCode: 400, message: "Imagen no encontrada o formulario invalido" });
        return;
      }

      resolve({ buffer: imageBuffer });
    });

    parser.end(body);
  });
}

exports.handler = async (event) => {
  try {
    const headers = event?.headers || {};

    const contentType = Object.entries(headers).find(
      ([key]) => key.toLowerCase() === "content-type"
    )?.[1];

    if (
      !contentType ||
      !/^multipart\/form-data(?:;|$)/i.test(contentType) ||
      !event.body
    ) {
      return jsonResponse(400, {
        message: "Solicitud invalida. Envia una imagen usando multipart/form-data"
      });
    }

    const body = event.isBase64Encoded
      ? Buffer.from(event.body, "base64")
      : Buffer.from(event.body, "utf8");

    const result = await readImageFromForm(body, contentType);

    if (result.statusCode) {
      return jsonResponse(result.statusCode, {
        message: result.message
      });
    }

    const imageType = detectImageType(result.buffer);

    if (!imageType) {
      return jsonResponse(415, {
        message: "Formato no permitido. Usa JPEG, PNG, GIF o WebP"
      });
    }

    const bucket = process.env.S3_BUCKET;

    if (!bucket) {
      throw new Error("No se configuro S3_BUCKET");
    }

    const prefix = process.env.UPLOAD_PREFIX || "uploads/";
    const normalizedPrefix = prefix.endsWith("/") ? prefix : `${prefix}/`;

    const key = `${normalizedPrefix}${uuidv4()}.${imageType.extension}`;

    await s3.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: key,
        Body: result.buffer,
        ContentType: imageType.contentType
      })
    );

    return jsonResponse(200, {
      message: "Imagen recibida",
      key,
      bucket
    });
  } catch (error) {
    console.error("Error al subir la imagen:", error);

    return jsonResponse(500, {
      message: "Ocurrio un error al procesar la imagen"
    });
  }
};
