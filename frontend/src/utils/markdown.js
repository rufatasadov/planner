// Small Markdown renderer for task notes. All input is HTML-escaped first, so the output is safe for v-html;
// only http(s)/mailto links are turned into anchors.

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const LINK_ATTRS = 'target="_blank" rel="noopener noreferrer"';

function inline(text) {
  const kept = [];
  const keep = (html) => `\u0000${kept.push(html) - 1}\u0000`;
  return esc(text)
    .replace(/`([^`]+)`/g, (_, code) => keep(`<code>${code}</code>`))
    .replace(/\[([^\]]+)\]\(((?:https?:\/\/|mailto:)[^\s)]+)\)/g, (_, label, url) => keep(`<a href="${url}" ${LINK_ATTRS}>${label}</a>`))
    .replace(/(^|[\s(])(https?:\/\/[^\s<)]+)/g, (_, pre, url) => pre + keep(`<a href="${url}" ${LINK_ATTRS}>${url}</a>`))
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/~~(.+?)~~/g, '<del>$1</del>')
    .replace(/(^|[^*\w])\*(?![\s*])(.+?)\*(?!\w)/g, '$1<em>$2</em>')
    .replace(/(^|[^\w])_(?![\s_])(.+?)_(?!\w)/g, '$1<em>$2</em>')
    .replace(/\u0000(\d+)\u0000/g, (_, i) => kept[i]);
}

const LIST_RE = /^\s*([-*]|\d+\.)\s+(.*)$/;
const isSpecial = (line) =>
  /^```/.test(line) || /^#{1,3}\s/.test(line) || LIST_RE.test(line) || /^>/.test(line) || /^-{3,}\s*$/.test(line);

export function renderMarkdown(src) {
  const lines = (src ?? '').replace(/\r\n?/g, '\n').split('\n');
  const out = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];

    if (/^```/.test(line)) {
      const code = [];
      for (i++; i < lines.length && !/^```/.test(lines[i]); i++) code.push(lines[i]);
      i++;
      out.push(`<pre><code>${esc(code.join('\n'))}</code></pre>`);
      continue;
    }

    const heading = line.match(/^(#{1,3})\s+(.*)$/);
    if (heading) {
      const tag = `h${heading[1].length + 2}`;
      out.push(`<${tag}>${inline(heading[2])}</${tag}>`);
      i++;
      continue;
    }

    if (/^-{3,}\s*$/.test(line)) {
      out.push('<hr>');
      i++;
      continue;
    }

    const item = line.match(LIST_RE);
    if (item) {
      const ordered = /\d/.test(item[1]);
      const items = [];
      for (let m; i < lines.length && (m = lines[i].match(LIST_RE)) && /\d/.test(m[1]) === ordered; i++) {
        const task = m[2].match(/^\[([ xX])\]\s*(.*)$/);
        items.push(
          task
            ? `<li class="md-task${task[1] === ' ' ? '' : ' checked'}"><input type="checkbox" disabled${task[1] === ' ' ? '' : ' checked'}> ${inline(task[2])}</li>`
            : `<li>${inline(m[2])}</li>`,
        );
      }
      const tag = ordered ? 'ol' : 'ul';
      out.push(`<${tag}>${items.join('')}</${tag}>`);
      continue;
    }

    if (/^>/.test(line)) {
      const quote = [];
      for (; i < lines.length && /^>/.test(lines[i]); i++) quote.push(inline(lines[i].replace(/^>\s?/, '')));
      out.push(`<blockquote>${quote.join('<br>')}</blockquote>`);
      continue;
    }

    if (!line.trim()) {
      i++;
      continue;
    }

    const para = [];
    for (; i < lines.length && lines[i].trim() && !isSpecial(lines[i]); i++) para.push(inline(lines[i]));
    out.push(`<p>${para.join('<br>')}</p>`);
  }
  return out.join('');
}
