#!/usr/bin/env node
/**
 * Mermaid diagram legibility check.
 *
 * Renders every ```mermaid block in the given Markdown files through the real
 * Mermaid engine, reads the CSS it generates, pairs each run of text with the
 * fill actually painted behind it, and measures WCAG contrast.
 *
 * Why this exists: Mermaid colours come from two places with very different
 * guarantees. `classDef` compiles to CSS carrying `!important` on both `fill`
 * and `color`, so it survives any theme the host injects. Everything else —
 * erDiagram attribute rows, sequence actors, notes — is driven purely by theme
 * variables, which GitHub overrides with its own theme. That difference once
 * shipped a Data Model diagram with white rows and invisible column names.
 *
 * A second class of bug it catches: text drawn on the transparent canvas
 * (sequence message and loop labels) inherits the reader's page background, so
 * it must stay legible on GitHub's dark, dim AND light themes.
 *
 *   npm --prefix scripts install
 *   node scripts/check-diagram-contrast.mjs [file.md ...]
 *
 * Exits non-zero if any pair falls below threshold.
 */
import fs from 'fs';
import path from 'path';
import { JSDOM } from 'jsdom';

const DEFAULT_TARGETS = ['README.md', 'backend/README.md'];

// GitHub renders the block on its own page background; the SVG stays transparent.
const CANVAS = { 'GitHub dark': '#0D1117', 'GitHub dim': '#212830', 'GitHub light': '#FFFFFF' };
const MIN_ON_FILL = 4.5;   // WCAG AA, normal text, against a fill we control
const MIN_ON_CANVAS = 3.0; // AA-large: AA-normal on both #0D1117 and #FFFFFF is impossible

// ── jsdom has no SVG layout engine; stub what Mermaid/dagre measure with ──────
const { window } = new JSDOM('<!doctype html><html><body></body></html>', { pretendToBeVisual: true });
Object.assign(global, {
  window, document: window.document, HTMLElement: window.HTMLElement,
  SVGElement: window.SVGElement, Element: window.Element, Node: window.Node,
  DOMParser: window.DOMParser, XMLSerializer: window.XMLSerializer,
  getComputedStyle: window.getComputedStyle, requestAnimationFrame: (cb) => setTimeout(cb, 0),
  CSSStyleSheet: window.CSSStyleSheet ||
    class { constructor() { this.cssRules = []; } replaceSync() {} insertRule() {} },
});
const svgProto = window.SVGElement.prototype;
svgProto.getBBox = function () {
  const n = (this.textContent || '').length;
  return { x: 0, y: 0, width: Math.max(n * 7, 20), height: 18 };
};
svgProto.getComputedTextLength = function () { return (this.textContent || '').length * 7; };
svgProto.getScreenCTM = function () { return { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0, inverse() { return this; } }; };

const mermaid = (await import('mermaid')).default;
mermaid.initialize({ startOnLoad: false, securityLevel: 'loose' });

// ── colour maths ─────────────────────────────────────────────────────────────
const toRGB = (c) => {
  c = (c || '').trim();
  let m = c.match(/^rgba?\(\s*([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)/i);
  if (m) return [+m[1], +m[2], +m[3]];
  m = c.match(/^#([0-9a-f]{6})$/i);
  if (m) return [0, 2, 4].map((i) => parseInt(m[1].slice(i, i + 2), 16));
  m = c.match(/^#([0-9a-f]{3})$/i);
  if (m) return [0, 1, 2].map((i) => parseInt(m[1][i].repeat(2), 16));
  return null;
};
const luminance = (rgb) => {
  const a = rgb.map((v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; });
  return 0.2126 * a[0] + 0.7152 * a[1] + 0.0722 * a[2];
};
const contrast = (fg, bg) => {
  const F = toRGB(fg), B = toRGB(bg);
  if (!F || !B) return null;
  const [hi, lo] = [luminance(F), luminance(B)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
};

// ── per-diagram pair extraction ──────────────────────────────────────────────
function pairsFor(kind, css, id) {
  const rules = [...css.matchAll(/([^{}]+)\{([^}]*)\}/g)]
    .map((m) => ({ sel: m[1].replace(new RegExp('#' + id + '\\s*', 'g'), '').trim(), body: m[2] }));
  const get = (selRe, prop) => {
    for (const r of rules) {
      if (!selRe.test(r.sel)) continue;
      const m = r.body.match(new RegExp(`(?:^|;)\\s*${prop}\\s*:\\s*([^;!]+)`, 'i'));
      if (m && toRGB(m[1])) return m[1].trim();
    }
    return null;
  };
  const pairs = [];

  // classDef groups — the theme-proof path
  for (const name of new Set([...css.matchAll(/\.([A-Za-z][\w-]*)\s*>\s*\*\s*\{/g)].map((m) => m[1]))) {
    const fill = get(new RegExp(`^\\.${name}\\s*>\\s*\\*$`), 'fill');
    const color = get(new RegExp(`^\\.${name}\\s+span$`), 'color') ||
                  get(new RegExp(`^\\.${name}\\s+tspan$`), 'fill');
    if (fill && color) pairs.push({ label: `classDef .${name}`, fg: color, bg: fill, bgName: 'node fill' });
  }

  if (/sequenceDiagram/.test(kind)) {
    for (const [label, fgSel, bgSel, bgName] of [
      ['actor name', /^text\.actor\s*>\s*tspan$/, /^\.actor$/, 'actor box'],
      ['note text', /^\.noteText/, /^\.note$/, 'note box'],
      ['loop label', /^\.labelText/, /^\.labelBox$/, 'label box'],
      ['autonumber', /^\.sequenceNumber$/, /^\.loopLine$/, 'number circle'],
    ]) {
      const fg = get(fgSel, 'fill'), bg = get(bgSel, 'fill');
      if (fg && bg) pairs.push({ label, fg, bg, bgName });
    }
    // Painted on the bare canvas — must hold up in every GitHub theme.
    for (const [label, sel] of [['message text', /^\.messageText$/], ['loop text', /^\.loopText/]]) {
      const fg = get(sel, 'fill');
      if (!fg) continue;
      for (const [name, value] of Object.entries(CANVAS))
        pairs.push({ label, fg, bg: value, bgName: name, canvas: true });
    }
  }

  if (/^flowchart|^graph/.test(kind)) {
    const nodeFill = get(/\.node rect/, 'fill');
    const labelColor = get(/^\.label$/, 'color');
    if (nodeFill && labelColor)
      pairs.push({ label: 'unclassed node text', fg: labelColor, bg: nodeFill, bgName: 'default node fill' });
    const clusterFill = get(/^\.cluster rect$/, 'fill');
    const clusterText = get(/cluster-label text|^\.cluster text$/, 'fill');
    if (clusterFill && clusterText)
      pairs.push({ label: 'subgraph title', fg: clusterText, bg: clusterFill, bgName: 'cluster fill' });
    const edgeBg = get(/^\.edgeLabel$/, 'background-color');
    const edgeFg = get(/\.edgeLabel .label text/, 'fill') || labelColor;
    if (edgeBg && edgeFg)
      pairs.push({ label: 'edge label', fg: edgeFg, bg: edgeBg, bgName: 'edge label bkg' });
  }

  return pairs;
}

// ── run ──────────────────────────────────────────────────────────────────────
const repoRoot = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const targets = (process.argv.slice(2).length ? process.argv.slice(2) : DEFAULT_TARGETS)
  .map((f) => (path.isAbsolute(f) ? f : path.join(repoRoot, f)));

let checked = 0, failed = 0, diagrams = 0;

for (const file of targets) {
  if (!fs.existsSync(file)) { console.error(`missing: ${file}`); failed++; continue; }
  const blocks = [...fs.readFileSync(file, 'utf8').matchAll(/```mermaid\n([\s\S]*?)```/g)].map((m) => m[1]);
  console.log(`\n══ ${path.relative(repoRoot, file)} — ${blocks.length} diagram(s) ══`);

  for (let i = 0; i < blocks.length; i++) {
    const kind = blocks[i].split('\n').find((l) => l.trim() && !l.startsWith('%%')).trim();
    const id = `chk${path.basename(file).length}x${i}`;
    diagrams++;
    let svg;
    try { ({ svg } = await mermaid.render(id, blocks[i])); }
    catch (e) { console.log(`  #${i + 1} ${kind}: RENDER FAIL — ${e.message.split('\n')[0]}`); failed++; continue; }

    const css = [...svg.matchAll(/<style>([\s\S]*?)<\/style>/g)].map((m) => m[1]).join('');
    const pairs = pairsFor(kind, css, id);
    const bad = [];

    for (const p of pairs) {
      const r = contrast(p.fg, p.bg);
      if (r == null) continue;
      checked++;
      const floor = p.canvas ? MIN_ON_CANVAS : MIN_ON_FILL;
      if (r < floor) bad.push(`${p.label}: ${p.fg} on ${p.bgName} ${p.bg} → ${r.toFixed(2)}:1 (need ${floor})`);
      else if (process.env.VERBOSE)
        console.log(`        ${p.label.padEnd(20)} ${p.fg} on ${p.bg} — ${r.toFixed(2)}:1`);
    }

    failed += bad.length;
    if (bad.length) {
      console.log(`  #${i + 1} ${kind}: ✗ ${bad.length} unreadable`);
      bad.forEach((b) => console.log(`        ${b}`));
    } else {
      console.log(`  #${i + 1} ${kind}: ✓ ${pairs.length} text/background pairs legible`);
    }
  }
}

console.log(`\n${diagrams} diagram(s) · ${checked} pairs checked · ${failed} failure(s)`);
process.exit(failed ? 1 : 0);
