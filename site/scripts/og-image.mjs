// Renders public/og.png — the 1200×630 social preview (og:image / twitter:image).
// Re-run after changing the logo or tagline: `node scripts/og-image.mjs`.
import sharp from 'sharp';

const W = 1200;
const H = 630;

// Same artwork as src/assets/logo.svg (32×32), scaled into a 340px square.
const logo = `
  <g transform="translate(780 145) scale(10.6)">
    <path d="M20 6C15 9 11.5 14 10.5 20" stroke="#4c9a2a" stroke-width="2" stroke-linecap="round" fill="none"/>
    <path d="M20 6C20.5 12 21 17.5 21.5 21" stroke="#4c9a2a" stroke-width="2" stroke-linecap="round" fill="none"/>
    <path d="M20 6C22.5 3.5 26 3 28.5 4.5C27.5 7.5 24.5 8.5 20 6Z" fill="#63b846"/>
    <circle cx="9.5" cy="23" r="6" fill="#e11d48"/>
    <circle cx="22" cy="24.5" r="5.5" fill="#e11d48"/>
    <circle cx="7.3" cy="21" r="1.6" fill="#fecdd3" opacity="0.9"/>
    <circle cx="20" cy="22.6" r="1.4" fill="#fecdd3" opacity="0.9"/>
  </g>`;

const font = `'Helvetica Neue', Helvetica, Arial, sans-serif`;

const svg = `
<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="glow" cx="78%" cy="50%" r="55%">
      <stop offset="0%" stop-color="#e11d48" stop-opacity="0.22"/>
      <stop offset="100%" stop-color="#e11d48" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="#17181c"/>
  <rect width="${W}" height="${H}" fill="url(#glow)"/>
  <rect x="0" y="${H - 10}" width="${W}" height="10" fill="#d4234a"/>
  ${logo}
  <text x="80" y="270" font-family="${font}" font-size="96" font-weight="700" fill="#ffffff">CherryPick</text>
  <text x="80" y="345" font-family="${font}" font-size="40" fill="#c0c2c7">Dependency Injection</text>
  <text x="80" y="397" font-family="${font}" font-size="40" fill="#c0c2c7">for Dart &amp; Flutter</text>
  <text x="80" y="520" font-family="${font}" font-size="28" fill="#888b96">cherrypick.openidealab.com</text>
</svg>`;

const out = new URL('../public/og.png', import.meta.url).pathname;
await sharp(Buffer.from(svg)).png({ compressionLevel: 9 }).toFile(out);
console.log(`wrote ${out}`);
