// main.ts
import axios, { AxiosResponse } from "axios";
import sharp from "sharp";
import cv from "@techstark/opencv-js";

const apiUrl = "https://api.backgrounderase.com/v2";

type PostProcessResult = {
  maskBuffer: Buffer;
  rgbaBuffer: Buffer;
};

type PredictResult = {
  mask: Buffer;
  foreground: Buffer;
} | null;

type ApiResponseBody = {
  mask: string; 
};

async function postProcess(maskMat: cv.Mat, originalBuffer: Buffer): Promise<PostProcessResult> {
  const {
    data: origData,
    info: { width: origWidth, height: origHeight },
  } = await sharp(originalBuffer)
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const resized = new cv.Mat();
  cv.resize(
    maskMat,
    resized,
    new cv.Size(origWidth, origHeight),
    0,
    0,
    cv.INTER_LINEAR
  );

  const { minVal, maxVal } = cv.minMaxLoc(resized);
  const range = maxVal - minVal;

  if (range > 1e-5) {
    resized.convertTo(
      resized,
      cv.CV_8UC1,
      255.0 / range,
      (-minVal * 255.0) / range
    );
  }

  const newData = Buffer.alloc(origWidth * origHeight * 4);
  const maskData = new Uint8Array(resized.data as ArrayLike<number>);

  for (let i = 0, j = 0; i < newData.length; i += 4, j++) {
    newData[i] = origData[i];
    newData[i + 1] = origData[i + 1];
    newData[i + 2] = origData[i + 2];
    newData[i + 3] = maskData[j];
  }

  const [rgbaBuffer, maskBuffer] = await Promise.all([
    sharp(newData, {
      raw: { width: origWidth, height: origHeight, channels: 4 },
    })
      .png()
      .toBuffer(),

    sharp(maskData, {
      raw: { width: origWidth, height: origHeight, channels: 1 },
    })
      .png()
      .toBuffer(),
  ]);

  return { maskBuffer, rgbaBuffer };
}

export async function predictImage(originalBuffer: Buffer, apiKey: string): Promise<PredictResult> {
  try {
    const resizedBuffer = await sharp(originalBuffer)
      .resize(1024, 1024, { fit: "inside" })
      .jpeg({ quality: 85 })
      .toBuffer();

    const imageBase64 = resizedBuffer.toString("base64");

    const headers = {
      "x-api-key": apiKey,
      "Content-Type": "application/json",
    };

    const payload = { image: imageBase64 };

    const response: AxiosResponse<ApiResponseBody> = await axios.post(apiUrl, payload, { headers });

    if (response.status !== 200) {
      console.error(`Error: ${response.status}`);
      console.error("Response:", response.data);
      return null;
    }

    const { mask: maskB64 } = response.data;
    const maskBytes = Buffer.from(maskB64, "base64");

    const maskInfo = await sharp(maskBytes).raw().toBuffer({ resolveWithObject: true });
    const {
      data: maskData,
      info: { width, height, channels },
    } = maskInfo;

    const maskMat = new cv.Mat(height, width, cv.CV_8UC1);

    let idx = 0;
    for (let r = 0; r < height; r++) {
      for (let c = 0; c < width; c++) {
        maskMat.ucharPtr(r, c)[0] = maskData[idx];
        idx += channels; // in case mask PNG decodes as RGBA, etc.
      }
    }

    const { maskBuffer, rgbaBuffer } = await postProcess(maskMat, originalBuffer);

    return {
      mask: maskBuffer,
      foreground: rgbaBuffer,
    };
  } catch (err: unknown) {
    console.error("Error in predictImage:", err);
    return null;
  }
}
