// CommonJS version (no import/export)
const BlockType = require('../../extension-support/block-type');
// const ArgumentType = require('../../extension-support/argument-type'); // not used



class BenBackgroundRemover {
  constructor (runtime) {
    this.runtime = runtime;
    this.proxyURL = 'http://localhost:3001/erase';
  }

  getInfo () {
    return {
      id: 'benbg',
      name: 'Background Remover',
      color1: '#00B894',
      blocks: [
        {
          opcode: 'eraseCurrentCostume',
          blockType: BlockType.COMMAND,
          text: 'remove background of current costume'
        }
      ]
    };
  }


async eraseCurrentCostume (args, util) {
  const runtime = this.runtime;
  const target = util.target;
  const costume = target.getCostumes()[target.currentCostume];

  console.group('[benbg]');
  console.log('target id:', target.id);
  console.log('costume:', {
    name: costume.name,
    assetId: costume.assetId,
    dataFormat: costume.dataFormat,
    hasAssetProp: !!costume.asset
  });

  // Guard: only bitmap formats
  const fmt = (costume.dataFormat || '').toLowerCase();
  if (fmt === 'svg') {
    console.warn('[benbg] SVG costume; please Convert to Bitmap first.');
    console.groupEnd();
    return;
  }

  const storage = runtime.storage;
  let imgBytes = null;

  // helper: timeout wrapper
  const withTimeout = (p, ms, label) => Promise.race([
    p,
    new Promise((_, rej) => setTimeout(() => rej(new Error(`timeout: ${label} after ${ms}ms`)), ms))
  ]);

  // 0) Try the inline costume.asset (typical for freshly uploaded images)
  try {
    if (costume.asset && costume.asset.data) {
      console.time('[benbg] costume.asset');
      const d = costume.asset.data;
      imgBytes = d instanceof Uint8Array ? d :
        (d && d.buffer) ? new Uint8Array(d.buffer) :
        new Uint8Array(d); // ArrayBuffer
      console.timeEnd('[benbg] costume.asset');
      console.log('[benbg] got bytes from costume.asset:', imgBytes.length);
    } else {
      console.log('[benbg] costume.asset missing; trying storage cache…');
    }
  } catch (e) {
    console.warn('[benbg] reading costume.asset failed:', e);
  }

  // 1) Storage cache by assetId
  if (!imgBytes) {
    try {
      console.time('[benbg] storage.get(assetId)');
      const cached = storage.get(costume.assetId);
      console.timeEnd('[benbg] storage.get(assetId)');
      if (cached && cached.data) {
        const d = cached.data;
        imgBytes = d instanceof Uint8Array ? d :
          (d && d.buffer) ? new Uint8Array(d.buffer) :
          new Uint8Array(d);
        console.log('[benbg] got bytes from storage cache:', imgBytes.length);
      } else {
        console.log('[benbg] not in storage cache.');
      }
    } catch (e) {
      console.warn('[benbg] storage.get failed:', e);
    }
  }

  // 2) storage.load using computed md5ext  <assetId>.<ext>
  if (!imgBytes) {
    const md5ext = (costume.assetId && costume.dataFormat)
      ? `${costume.assetId}.${costume.dataFormat}`
      : null;

    try {
      if (md5ext) {
        console.time('[benbg] storage.load(md5ext)');
        const asset = await withTimeout(
          storage.load(storage.AssetType.ImageBitmap, md5ext),
          4000,
          `storage.load(${md5ext})`
        );
        const d = asset.data;
        imgBytes = d instanceof Uint8Array ? d :
          (d && d.buffer) ? new Uint8Array(d.buffer) :
          new Uint8Array(d);
        console.timeEnd('[benbg] storage.load(md5ext)');
        console.log('[benbg] loaded via storage.load(md5ext):', imgBytes.length);
      } else {
        console.log('[benbg] md5ext unavailable; skipping storage.load.');
      }
    } catch (e) {
      console.warn('[benbg] storage.load(md5ext) failed:', e.message || e);
    }
  }

  // 3) Give up if we still don’t have bytes
  if (!imgBytes) {
    alert('Background Remover: could not read costume bytes.\nSee console for details.');
    // Useful state dump for you:
    try {
      const cache = storage._cache || storage.cache;
      console.log('[benbg] storage cache keys:',
        cache && (cache._assets ? Object.keys(cache._assets) :
                 cache._data ? Object.keys(cache._data) : Object.keys(cache)));
    } catch (_e) {}
    console.groupEnd();
    return;
  }

  // ----- call your proxy -----
  console.log('[benbg] sending bytes:', imgBytes.length);
  const mime = (fmt === 'jpg' || fmt === 'jpeg') ? 'image/jpeg' : 'image/png';
  const form = new FormData();
  // Use Blob instead of File for maximum compatibility
  form.append('image_file', new Blob([imgBytes], { type: mime }), `costume.${fmt || 'png'}`);

  console.time('[benbg] fetch');
  let resp;
  try {
    resp = await withTimeout(
      fetch(this.proxyURL, { method: 'POST', body: form, mode: 'cors' }),
      15000,
      'fetch to proxy'
    );
    console.timeEnd('[benbg] fetch');
    console.log('[benbg] proxy status:', resp.status);
  } catch (e) {
    console.error('[benbg] fetch error:', e.message || e);
    alert('Background Remover: network error (see console).');
    console.groupEnd();
    return;
  }

  if (!resp.ok) {
    console.error('[benbg] API failed:', resp.status, await resp.text().catch(()=>'')); 
    alert('Background Remover: API returned an error (see console).');
    console.groupEnd();
    return;
  }

// ----- create new costume from returned PNG -----
console.time('[benbg] build costume');
const out = new Uint8Array(await resp.arrayBuffer());

// 1) Register the PNG as a storage asset (so it has an assetId/md5)
const newAsset = storage.createAsset(
  storage.AssetType.ImageBitmap,
  'image/png',
  out,
  null,
  true
);

// 2) Decode bytes to an ImageBitmap and build a renderer skin
//    (Blob URL avoids extra copies; ImageBitmap is fast in Chrome/Edge)
let skinId;
try {
  const blob = new Blob([out], {type: 'image/png'});
  const bmp = await createImageBitmap(blob);
  const resolution = costume.bitmapResolution || 1;
  skinId = this.runtime.renderer.createBitmapSkin(bmp, resolution);
} catch (e) {
  console.error('[benbg] createBitmapSkin failed:', e);
  alert('Background Remover: could not decode PNG for renderer.');
  console.groupEnd();
  return;
}

// 3) Construct a *new* costume object (do not mutate the old one)
const newCostume = {
  assetId: newAsset.assetId,
  md5ext: `${newAsset.assetId}.png`,
  name: `${costume.name} (bg)`,
  dataFormat: 'png',
  bitmapResolution: costume.bitmapResolution || 1,
  rotationCenterX: costume.rotationCenterX,
  rotationCenterY: costume.rotationCenterY,
  asset: newAsset,      // so the paint editor / exporter can read bytes
  skinId                // so setCostume() has a ready skin
};

// 4) Append it and select it (no in‑place edits, no skin destruction)
const sprite = target && target.sprite;
if (sprite && Array.isArray(sprite.costumes)) {
  const idx = sprite.costumes.length;
  sprite.costumes.push(newCostume);

  // If sprite has a helper to refresh skins, call it (exists in some builds)
  if (typeof sprite.updateAllDrawableSkins === 'function') {
    try { sprite.updateAllDrawableSkins(); } catch (e) {
      console.warn('[benbg] updateAllDrawableSkins failed:', e);
    }
  }

  target.setCostume(idx);
  this.runtime.requestRedraw();
  console.timeEnd('[benbg] build costume');
  console.groupEnd();
  return;
}

// 5) Fallback (rare): direct selection without pushing (still non‑destructive)
console.warn('[benbg] sprite.costumes missing; applying skin directly to drawable.');
this.runtime.renderer.updateDrawableSkinId(target.drawableID, skinId);
this.runtime.requestRedraw();
console.timeEnd('[benbg] build costume');
console.groupEnd();



}


}

module.exports = BenBackgroundRemover;
