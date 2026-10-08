const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require("sharp");

const s3 = new S3Client({});

exports.handler = async (event) => {
  const batchItemFailures = [];

  for (const record of event.Records) {
    try {
      const body = JSON.parse(record.body);

      if (!body.Records) {
        console.log("Evento ignorado (posible s3:TestEvent o formato no soportado).");
        continue;
      }

      for (const s3Record of body.Records) {
        const rawKey = s3Record.s3.object.key;
        const key = decodeURIComponent(rawKey.replace(/\+/g, " "));

        if (!key.startsWith("uploads/")) {
          console.log(`Clave ignorada por no tener el prefijo de subida: ${key}`);
          continue;
        }

        const bucket = s3Record.s3.bucket.name;

        const getObjectResponse = await s3.send(
          new GetObjectCommand({
            Bucket: bucket,
            Key: key
          })
        );

        const chunks = [];
        for await (const chunk of getObjectResponse.Body) {
          chunks.push(chunk);
        }
        const imageBuffer = Buffer.concat(chunks);

        const circleSvg = Buffer.from(
          '<svg width="40" height="40"><circle cx="20" cy="20" r="20" fill="#fff"/></svg>'
        );

        const processedBuffer = await sharp(imageBuffer)
          .resize(40, 40, { fit: "cover" })
          .ensureAlpha()
          .composite([
            {
              input: circleSvg,
              blend: "dest-in"
            }
          ])
          .png()
          .toBuffer();

        const fileNameWithExt = key.replace(/^uploads\//, "");
        const fileNameWithoutExt = fileNameWithExt.substring(0, fileNameWithExt.lastIndexOf("."));
        const processedPrefix = process.env.PROCESSED_PREFIX || "processed/";
        const targetKey = `${processedPrefix}${fileNameWithoutExt}_circular.png`;

        await s3.send(
          new PutObjectCommand({
            Bucket: bucket,
            Key: targetKey,
            Body: processedBuffer,
            ContentType: "image/png"
          })
        );

        console.log(`Imagen procesada con exito: ${targetKey}`);
      }
    } catch (error) {
      console.error(`Error procesando el mensaje ID ${record.messageId}:`, error);
      batchItemFailures.push({ itemIdentifier: record.messageId });
    }
  }

  return { batchItemFailures };
};