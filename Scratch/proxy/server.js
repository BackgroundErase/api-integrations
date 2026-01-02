const express = require('express');
const multer = require('multer');
const cors = require('cors');
const fs = require('node:fs/promises');      // ⬅️ add
const path = require('node:path');           // ⬅️ add

const app = express();
const upload = multer();

app.use(cors({
  origin: [/^http:\/\/localhost:8601$/, /^http:\/\/127\.0\.0\.1:8601$/],
  methods: ['GET','POST','OPTIONS'],
  credentials: false
}));
app.options('/erase', cors());
app.options('/ping', cors());

app.use((req, _res, next) => {
  console.log(new Date().toISOString(), req.method, req.path);
  next();
});

app.get('/ping', (_req, res) => res.json({ ok: true }));

const API_URL = 'https://api.backgrounderase.net/v2';
const API_KEY = process.env.BEN_API_KEY;

app.post('/erase', upload.single('image_file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).send('image_file required');

    const filename = req.file.originalname || 'input.jpg';
    const mimetype = req.file.mimetype || 'application/octet-stream';

    const form = new FormData();
    const blob = new Blob([req.file.buffer], { type: mimetype });
    form.append('image_file', blob, filename);

    const r = await fetch(API_URL, {
      method: 'POST',
      headers: { 'x-api-key': API_KEY },
      body: form
    });
    if (!r.ok) return res.status(r.status).send(await r.text());

    // get the result as a Buffer
    const ab = await r.arrayBuffer();
    const buf = Buffer.from(ab);

    // --- save a server-side copy (awaited; may add a bit of time) ---
    const dir = path.join(process.cwd(), 'saved');
    await fs.mkdir(dir, { recursive: true });

    // derive a safe name (timestamp + original base)
    const base = (filename || 'image').replace(/\.[^.]+$/, ''); // strip ext
    const safeBase = base.replace(/\W+/g, '_') || 'image';
    const outPath = path.join(dir, `${Date.now()}_${safeBase}.png`);
    await fs.writeFile(outPath, buf);
    console.log('Saved copy to', outPath);
    // --- end save ---

    // return EXACTLY the PNG as before
    res.set('Content-Type', 'image/png');
    res.send(buf);


  } catch (e) {
    console.error(e);
    res.status(500).send(String(e));
  }
});

app.listen(3001, () => console.log('Proxy on http://localhost:3001/erase'));
