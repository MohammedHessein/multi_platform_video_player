const fs = require('fs');
const path = require('path');

const webRoot = path.join(__dirname, 'build', 'web');
const filePath = path.join(webRoot, 'flutter_bootstrap.js');

// 0. Smart TV file:// needs relative base href (Chrome/Edge dev uses "/" in web/index.html)
const indexPath = path.join(webRoot, 'index.html');
// Sync TV-aware index.html (bootTvFlutter + on-screen errors) into build/web
const srcIndexPath = path.join(__dirname, 'web', 'index.html');
if (fs.existsSync(srcIndexPath) && fs.existsSync(path.dirname(indexPath))) {
  let indexHtml = fs.readFileSync(srcIndexPath, 'utf8');
  indexHtml = indexHtml.replace(/<base href="[^"]*"\s*>/, '<base href="./">');
  fs.writeFileSync(indexPath, indexHtml);
  console.log('✅ Synced TV index.html → build/web/index.html (base href="./")');
} else if (fs.existsSync(indexPath)) {
  let indexHtml = fs.readFileSync(indexPath, 'utf8');
  if (!indexHtml.includes('<base href="./">')) {
    indexHtml = indexHtml.replace(/<base href="[^"]*"\s*>/, '<base href="./">');
    fs.writeFileSync(indexPath, indexHtml);
    console.log('✅ Set base href="./" in build/web/index.html for Smart TV');
  }
}

if (!fs.existsSync(filePath)) {
    console.error('flutter_bootstrap.js not found. Please run flutter build web first.');
    process.exit(1);
}

let content = fs.readFileSync(filePath, 'utf8');

// Repair syntax error from previous run if any
content = content.replace(',let u;', ';let u;');

console.log('Original content length:', content.length);

const bootstrapAlreadyPatched = content.includes('_tvFileProto');

if (!bootstrapAlreadyPatched) {
// 1. Replace a??=l=>{l.initializeEngine(t).then(u=>u.runApp())}
content = content.replace(
  /a\?\?=l=>\{l\.initializeEngine\(t\)\.then\(u=>u\.runApp\(\)\)\}/g,
  'if(a===undefined||a===null){a=function(l){return l.initializeEngine(t).then(function(u){return u.runApp()})}}'
);

// 2. Replace r??={}
content = content.replace(/r\?\?=\{\}/g, 'if(r===undefined||r===null){r={}}');

// 3. Replace e.mainJsPath??"main.dart.js"
content = content.replace(/e\.mainJsPath\?\?"main\.dart\.js"/g, '((e.mainJsPath!==undefined&&e.mainJsPath!==null)?e.mainJsPath:"main.dart.js")');

// 4. Replace r.wasmAllowList?.[w.browserEngine]??_[w.browserEngine]
content = content.replace(/r\.wasmAllowList\?\?_\[w\.browserEngine\]/g, '((r.wasmAllowList!==undefined&&r.wasmAllowList!==null)?r.wasmAllowList:_[w.browserEngine])');
content = content.replace(/r\.wasmAllowList\?\.\[w\.browserEngine\]\?\?_\[w\.browserEngine\]/g, '((r.wasmAllowList&&r.wasmAllowList[w.browserEngine]!==undefined)?r.wasmAllowList[w.browserEngine]:_[w.browserEngine])');

// 5. Remove dart2wasm from builds to prevent loading/trying Wasm on old TVs
content = content.replace(/"builds":\[\{"compileTarget":"dart2wasm"[^\}]+\},/, '"builds":[');
content = content.replace(/"builds":\[\{\},/, '"builds":['); // Clean up if it was already patched with an empty object

// 6. Replace CanvasKit dynamic import with script injection fallback for file:// protocol support
const canvaskitDynamicImportRegex = /,u=await import\(o\);return window\.flutterCanvasKit=await u\.default\(\{instantiateWasm:l\}\),window\.flutterCanvasKit/g;
const canvaskitFallbackReplacement = `;let u;
var _tvFileProto=typeof location!=="undefined"&&location.protocol==="file:";
if(!_tvFileProto){try{u=await import(o);window.flutterCanvasKit=await u.default({instantiateWasm:l})}catch(err){console.warn("CanvasKit import failed, using script tag fallback...",err)}}
if(!window.flutterCanvasKit){await new Promise(function(resolve,reject){var script=document.createElement("script");script.src=o;script.onload=function(){resolve()};script.onerror=function(e){reject(e)};document.head.appendChild(script)});if(window.CanvasKitInit){window.flutterCanvasKit=await window.CanvasKitInit({instantiateWasm:l})}else{throw new Error("CanvasKitInit not found after script injection fallback")}}
return window.flutterCanvasKit;`;

content = content.replace(canvaskitDynamicImportRegex, canvaskitFallbackReplacement);

// 6b. file:// cannot fetch() wasm — use XHR + WebAssembly.compile for TV containers
const wasmLoaderRegex = /var k=i=>\{let e=WebAssembly\.compileStreaming\(fetch\(i\)\);return\(n,t\)=>\(\(async\(\)=>\{let r=await e,a=await WebAssembly\.instantiate\(r,n\);t\(a,r\)\}\)\(\),\{\}\)\};/;
const wasmLoaderReplacement = `var k=i=>{let e=(async()=>{var f=typeof location!=="undefined"&&location.protocol==="file:";if(!f){try{return WebAssembly.compileStreaming(await fetch(i))}catch(x){console.warn("wasm fetch failed, trying XHR...",x)}}return new Promise(function(res,rej){var x=new XMLHttpRequest();x.open("GET",i,true);x.responseType="arraybuffer";x.onload=function(){if(x.status===0||x.status>=200&&x.status<300)res(WebAssembly.compile(x.response));else rej(new Error("wasm XHR status "+x.status))};x.onerror=function(){rej(new Error("wasm XHR network error"))};x.send()})})();return(n,t)=>((async()=>{let r=await e,a=await WebAssembly.instantiate(r,n);t(a,r)})(),{})};`;
content = content.replace(wasmLoaderRegex, wasmLoaderReplacement);

// 7. TV CanvasKit: local bundle + full variant (avoids chromium ||= on old webOS)
if (!content.includes('canvasKitVariant:"full"')) {
  content = content.replace(
    /_flutter\.loader\.load\(\{\s*serviceWorkerSettings:/,
    '_flutter.loader.load({ config: { canvasKitBaseUrl: "canvaskit/", canvasKitVariant: "full" }, serviceWorkerSettings:'
  );
}

fs.writeFileSync(filePath, content);
console.log('✅ Successfully patched flutter_bootstrap.js for older Smart TVs!');
} else {
  console.log('ℹ️ flutter_bootstrap.js already patched — skipping bootstrap patches.');
  // Still ensure TV CanvasKit config on re-runs
  if (!content.includes('canvasKitVariant:"full"')) {
    content = content.replace(
      /_flutter\.loader\.load\(\{\s*serviceWorkerSettings:/,
      '_flutter.loader.load({ config: { canvasKitBaseUrl: "canvaskit/", canvasKitVariant: "full" }, serviceWorkerSettings:'
    );
    fs.writeFileSync(filePath, content);
    console.log('✅ Injected TV CanvasKit config into flutter_bootstrap.js');
  }
}

// Transpile ES2021+ syntax that older webOS / Tizen Chromium builds reject.
function transpileCanvasKitForLegacyEngines(ckContent) {
  const ident = '[\\w$]+(?:\\.[\\w$]+|\\[[^\\]]+\\])*';
  // RHS runs until next statement ; (safe for minified CanvasKit one-liners).
  const rhs = '[^;]+';

  ckContent = ckContent.replace(
    new RegExp(`(${ident})\\?\\?=(${rhs})`, 'g'),
    '($1=(null==$1?$2:$1))'
  );
  // (alias=obj).prop??(alias.prop=[]) — must run before generic ?? (avoids breaking ".ze??")
  ckContent = ckContent.replace(
    /\(([\w$]+)=([\w$]+\.[\w$]+)\)\.([\w$]+)\?\?\(\1\.\3=\[\]\)/g,
    '($1=$2).$3=null==$1.$3?($1.$3=[]):$1.$3'
  );
  ckContent = ckContent.replace(
    new RegExp(`(${ident})\\|\\|=(${rhs})`, 'g'),
    '$1=$1||$2'
  );
  ckContent = ckContent.replace(
    new RegExp(`(${ident})&&=(${rhs})`, 'g'),
    '$1=$1&&$2'
  );
  ckContent = ckContent.replace(
    new RegExp(`(${ident})\\?\\.\\(`, 'g'),
    '$1&&$1('
  );
  ckContent = ckContent.replace(
    new RegExp(`(${ident})\\?\\.([\\w$]+)`, 'g'),
    '$1&&$1.$2'
  );
  // Comma-expression GL error codes: V||=1281,0 → V=V||1281,0
  ckContent = ckContent.replace(/V\|\|=(1280|1281|1282)/g, 'V=V||$1');
  return ckContent;
}

// 7. Patch CanvasKit files for file:// + legacy TV JS engines
const canvaskitPaths = [
  path.join(__dirname, 'build', 'web', 'canvaskit', 'canvaskit.js'),
  path.join(__dirname, 'build', 'web', 'canvaskit', 'chromium', 'canvaskit.js')
];

canvaskitPaths.forEach(ckPath => {
  if (fs.existsSync(ckPath)) {
    let ckContent = fs.readFileSync(ckPath, 'utf8');
    const ckAlreadyPatched = ckContent.includes('location.protocol==="file:"') &&
      ckContent.includes('XHR :');

    if (ckAlreadyPatched) {
      console.log(`ℹ️ Already patched: ${path.relative(__dirname, ckPath)}`);
      return;
    }

    ckContent = ckContent.replace(
      'var _scriptName = import.meta.url;',
      "var _scriptName = (typeof document !== 'undefined' && document.currentScript ? document.currentScript.src : '');"
    );
    ckContent = ckContent.replace(/import\.meta\.url/g, '_scriptName');
    ckContent = ckContent.replace(
      'export default CanvasKitInit;',
      "if (typeof window !== 'undefined') { window.CanvasKitInit = CanvasKitInit; }"
    );
    ckContent = transpileCanvasKitForLegacyEngines(ckContent);

    // file:// blocks fetch() — CanvasKit wasm loader must use XHR on TV
    ckContent = ckContent.replace(
      'ua=a=>fetch(a,{credentials:"same-origin"}).then(b=>b.ok?b.arrayBuffer():Promise.reject(Error(b.status+" : "+b.url)))',
      'ua=a=>{if(typeof location!=="undefined"&&location.protocol==="file:"){return new Promise(function(res,rej){var x=new XMLHttpRequest();x.open("GET",a,true);x.responseType="arraybuffer";x.onload=function(){if(x.status===0||x.status>=200&&x.status<300)res(x.response);else rej(Error(x.status+" : "+a))};x.onerror=function(){rej(Error("XHR : "+a))};x.send()})}return fetch(a,{credentials:"same-origin"}).then(b=>b.ok?b.arrayBuffer():Promise.reject(Error(b.status+" : "+b.url)))}'
    );
    ckContent = ckContent.replace(
      'fetch(c,{credentials:"same-origin"}).then(e=>WebAssembly.instantiateStreaming(e,a).then(b,function(f){ya(`wasm streaming compile failed: ${f}`);ya("falling back to ArrayBuffer instantiation");return Ta(c,a,b)}))',
      '(typeof location!=="undefined"&&location.protocol==="file:"?new Promise(function(res,rej){var x=new XMLHttpRequest();x.open("GET",c,true);x.responseType="arraybuffer";x.onload=function(){if(x.status===0||x.status>=200&&x.status<300)res(x.response);else rej(Error(x.status))};x.onerror=rej;x.send()}).then(function(buf){return WebAssembly.instantiate(buf,a).then(b)}):fetch(c,{credentials:"same-origin"}).then(e=>WebAssembly.instantiateStreaming(e,a).then(b,function(f){ya(`wasm streaming compile failed: ${f}`);ya("falling back to ArrayBuffer instantiation");return Ta(c,a,b)})))'
    );

    fs.writeFileSync(ckPath, ckContent);
    const legacyOps = (ckContent.match(/\|\|=/g) || []).length;
    console.log(`✅ Patched CanvasKit file: ${path.relative(__dirname, ckPath)}${legacyOps ? ` (warning: ${legacyOps} ||= left)` : ''}`);
  } else {
    console.warn(`⚠️ CanvasKit file not found: ${path.relative(__dirname, ckPath)}`);
  }
});

// 8. Copy video to shallow media/ path (hosted http:// and file:// .ipk / .wgt)
// First match wins — keep in sync with AppConstants.videoAssetPath file name.
const videoNames = ['sample.mp4', 'sample_tv_1080p_low.mp4'];
const projectVideosDir = path.join(__dirname, 'assets', 'videos');
const videoDestDir = path.join(webRoot, 'media');
let videoCopied = false;
for (const name of videoNames) {
  const sources = [
    path.join(projectVideosDir, name),
    path.join(webRoot, 'assets', 'assets', 'videos', name),
    path.join(webRoot, 'assets', 'videos', name),
  ];
  for (const src of sources) {
    if (fs.existsSync(src)) {
      fs.mkdirSync(videoDestDir, { recursive: true });
      const dest = path.join(videoDestDir, name);
      fs.copyFileSync(src, dest);
      console.log(`✅ Copied TV video to ${path.relative(__dirname, dest)}`);
      videoCopied = true;
      break;
    }
  }
  if (videoCopied) break;
}
if (!videoCopied) {
  console.warn('⚠️ No video found for build/web/media — add assets/videos/sample.mp4');
}

// 9. TV bootstrap finalization (service worker off, boot moved to index.html)
if (fs.existsSync(filePath)) {
  let boot = fs.readFileSync(filePath, 'utf8');

  // Remove service worker from loader.load(...)
  boot = boot.replace(
    /_flutter\.loader\.load\(\{\s*config:\s*\{\s*canvasKitBaseUrl:\s*"canvaskit\/",\s*canvasKitVariant:\s*"full"\s*\},\s*serviceWorkerSettings:\s*\{[\s\S]*?\}\s*\}\);/,
    '_flutter.loader.load({ config: { canvasKitBaseUrl: "canvaskit/", canvasKitVariant: "full" } });'
  );

  // Allow all script URLs on file:// (webOS TrustedTypes can block CanvasKit)
  if (!boot.includes('TV_FILE_TRUSTED_TYPES')) {
    boot = boot.replace(
      'createScriptURL:function(r){if(r.startsWith("blob:"))return r;',
      'createScriptURL:function(r){if(typeof location!=="undefined"&&location.protocol==="file:")return r;/*TV_FILE_TRUSTED_TYPES*/if(r.startsWith("blob:"))return r;'
    );
  }

  // Do not auto-start here — index.html bootTvFlutter() shows errors on screen
  boot = boot.replace(
    /\n_flutter\.loader\.load\(\{\s*config:\s*\{\s*canvasKitBaseUrl:\s*"canvaskit\/",\s*canvasKitVariant:\s*"full"\s*\}\s*\}\);\s*$/,
    '\n// TV: started from index.html bootTvFlutter()\n'
  );

  fs.writeFileSync(filePath, boot);
  console.log('✅ TV bootstrap finalized (no SW, boot via index.html)');
}

// 10. Tizen .wgt metadata (Flutter build may omit these)
for (const file of ['config.xml', 'icon.png']) {
  const from = path.join(__dirname, 'web', file);
  const to = path.join(webRoot, file);
  if (fs.existsSync(from)) {
    fs.copyFileSync(from, to);
    console.log(`✅ Copied ${file} → build/web/`);
  }
}

