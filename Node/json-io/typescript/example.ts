// example.ts
import fs from "fs";
import path from "path";
import { predictImage } from "./main";

type PredictResult = {
  mask: Buffer;
  foreground: Buffer;
};

async function main(): Promise<void> {
  try {
    const apiKey = "YOUR_API_KEY"; // Replace with your API key
    const inputPath = path.join(__dirname, "image.jpg");

    const originalBuffer = fs.readFileSync(inputPath);

    const result = (await predictImage(originalBuffer, apiKey)) as
      | PredictResult
      | null
      | undefined;

    if (!result) {
      console.error("Failed to get a valid result from predictImage.");
      return;
    }

    const { mask, foreground } = result;

    fs.writeFileSync(path.join(__dirname, "result.png"), foreground);
    fs.writeFileSync(path.join(__dirname, "mask.png"), mask);
  } catch (err: unknown) {
    console.error("Error:", err);
  }
}

void main();
