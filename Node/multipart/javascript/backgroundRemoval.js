// background_removal.js
const https = require('https');
const fs = require('fs');

const API_KEY = 'YOUR_API_KEY'; // Replace with your API key

function backgroundRemoval(srcPath, dstPath) {
  return new Promise((resolve, reject) => {
    const boundary = '----' + Date.now().toString(16);

    const options = {
      hostname: 'api.backgrounderase.com',
      path: '/v2',
      method: 'POST',
      headers: {
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'x-api-key': API_KEY
      }
    };

    const req = https.request(options, (res) => {
      const isImage = /^image\//.test(res.headers['content-type'] || '');

      if (!isImage) {
        let errMsg = '';
        res.on('data', (chunk) => errMsg += chunk);
        res.on('end', () => reject(new Error(`❌ Error: ${errMsg}`)));
        return;
      }

      const fileStream = fs.createWriteStream(dstPath);
      res.pipe(fileStream);

      fileStream.on('finish', () => {
        console.log(`✅ File saved: ${dstPath}`);
        resolve(dstPath);
      });
      fileStream.on('error', reject);
    });

    req.on('error', reject);

    req.write(`--${boundary}\r\n`);
    req.write(`Content-Disposition: form-data; name="image_file"; filename="${srcPath.split('/').pop()}"\r\n`);
    req.write('Content-Type: application/octet-stream\r\n\r\n');

    const upload = fs.createReadStream(srcPath);
    upload.on('end', () => {
      req.write('\r\n');
      req.write(`--${boundary}--\r\n`);
      req.end();
    });
    upload.pipe(req, { end: false });
  });
}


// Usage: node background_removal.js input.jpg output.png

if (require.main === module) {
  const [,, src, dst] = process.argv;

  if (!src || !dst) {
    console.error('Usage: node background_removal.js <input> <output>');
    process.exit(1);
  }

  backgroundRemoval(src, dst)
    .then(() => console.log('✅ Background removed successfully!'))
    .catch(err => console.error(err.message));
}





