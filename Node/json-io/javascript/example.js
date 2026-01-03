const fs = require('fs');
const path = require('path');
const { predictImage } = require('./main');

async function main() {
  try {
    const apiKey = 'YOUR_API_KEY'; // Replace with your API key
    const inputPath = path.join(__dirname, 'image.jpg'); 
    const originalBuffer = fs.readFileSync(inputPath);
    const result = await predictImage(originalBuffer, apiKey);
    
    if (!result) {
      console.error('Failed to get a valid result from predictImage.');
      return;
    }
    
    const { mask, foreground } = result;
    fs.writeFileSync(path.join(__dirname, 'result.png'), foreground);
    fs.writeFileSync(path.join(__dirname, 'mask.png'), mask);
    
  } catch (err) {
    console.error('Error:', err);
  }
}

main();
