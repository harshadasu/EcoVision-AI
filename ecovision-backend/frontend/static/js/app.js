/* ── SVG gradient for ring (injected once) ── */
const SVG_DEFS = `<svg width="0" height="0" style="position:absolute">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:#22c55e"/>
      <stop offset="100%" style="stop-color:#2dd4bf"/>
    </linearGradient>
  </defs>
</svg>`;
document.body.insertAdjacentHTML('afterbegin', SVG_DEFS);

const BASE = '';   // same origin — FastAPI serves both

// ═══════════════════════════════════════════
// UTILITIES
// ═══════════════════════════════════════════
function toast(msg, type = 'info') {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.className = `toast show ${type}`;
  setTimeout(() => el.className = 'toast', 3200);
}

function scrollToSection(id) {
  document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
}

function setLoading(btnId, loading) {
  const btn = document.getElementById(btnId);
  if (!btn) return;
  if (loading) {
    btn.dataset.orig = btn.innerHTML;
    btn.innerHTML = `<span class="loader"></span> Processing…`;
    btn.disabled = true;
  } else {
    btn.innerHTML = btn.dataset.orig || btn.innerHTML;
    btn.disabled = false;
  }
}

function markdownLite(text) {
  return text
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/\n/g, '<br>');
}

// ═══════════════════════════════════════════
// NAVBAR — highlight active link on scroll
// ═══════════════════════════════════════════
const navbar = document.getElementById('navbar');
const sections = document.querySelectorAll('section[id]');
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 40);
  const scrollY = window.scrollY + 120;
  sections.forEach(sec => {
    const top = sec.offsetTop;
    const h   = sec.offsetHeight;
    const link = document.querySelector(`.nav-link[data-section="${sec.id}"]`);
    if (link) link.classList.toggle('active', scrollY >= top && scrollY < top + h);
  });
});

// ═══════════════════════════════════════════
// ANIMATED COUNTERS
// ═══════════════════════════════════════════
function animateCounters() {
  document.querySelectorAll('.hero-stat-num[data-target]').forEach(el => {
    const target = parseInt(el.dataset.target);
    const dur = 2000;
    const step = target / (dur / 16);
    let current = 0;
    const timer = setInterval(() => {
      current = Math.min(current + step, target);
      el.textContent = Math.floor(current).toLocaleString();
      if (current >= target) clearInterval(timer);
    }, 16);
  });
}

// ═══════════════════════════════════════════
// INTERSECTION OBSERVER — animate bars on scroll
// ═══════════════════════════════════════════
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (!entry.isIntersecting) return;
    const el = entry.target;
    // bar charts
    el.querySelectorAll('.bar-fill').forEach(b => {
      b.style.width = b.style.getPropertyValue('--w') || b.dataset.w || '0%';
    });
    // counter
    if (el.id === 'hero') animateCounters();
    observer.unobserve(el);
  });
}, { threshold: 0.15 });

document.querySelectorAll('section').forEach(s => observer.observe(s));

// ═══════════════════════════════════════════
// ANALYSE
// ═══════════════════════════════════════════
async function runAnalysis() {
  const text = document.getElementById('analyseText').value.trim();
  const category = document.getElementById('analyseCat').value;

  if (text.length < 10) { toast('Please enter at least 10 characters.', 'error'); return; }

  setLoading('analyseBtn', true);
  try {
    const res = await fetch(`${BASE}/api/v1/analyse`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text, category })
    });
    if (!res.ok) throw new Error((await res.json()).detail || 'Server error');
    const data = await res.json();
    renderAnalysis(data);
  } catch (err) {
    toast(`Error: ${err.message}`, 'error');
  } finally {
    setLoading('analyseBtn', false);
  }
}

function renderAnalysis(data) {
  const resultEl = document.getElementById('analyseResult');
  resultEl.style.display = 'block';

  // Category badge
  document.getElementById('resultCat').textContent = data.category;

  // Score ring animation
  const score = data.eco_score;
  const circumference = 2 * Math.PI * 50;  // r=50
  const offset = circumference - (score / 100) * circumference;

  const ring = document.getElementById('ringFill');
  ring.style.strokeDasharray = circumference;
  ring.style.strokeDashoffset = circumference;
  requestAnimationFrame(() => {
    ring.style.transition = 'stroke-dashoffset 1.5s cubic-bezier(0.22,1,0.36,1)';
    ring.style.strokeDashoffset = offset;
  });

  // Number counter
  const numEl = document.getElementById('scoreNum');
  let cur = 0;
  const timer = setInterval(() => {
    cur = Math.min(cur + score / 60, score);
    numEl.textContent = Math.round(cur);
    if (cur >= score) clearInterval(timer);
  }, 16);

  // Ring colour by severity
  ring.style.stroke = score > 60 ? '#f87171' : score > 30 ? '#fbbf24' : '#34d399';

  // Summary
  document.getElementById('resultSummary').innerHTML = markdownLite(data.summary);

  // Recommendations
  const list = document.getElementById('recList');
  list.innerHTML = data.recommendations.map(r => `<li>${r}</li>`).join('');

  // Confidence
  const pct = Math.round(data.confidence * 100);
  document.getElementById('confFill').style.width = pct + '%';
  document.getElementById('confVal').textContent = pct + '%';

  resultEl.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  toast('Analysis complete!', 'success');
}

// ═══════════════════════════════════════════
// SEARCH
// ═══════════════════════════════════════════
function setSearch(q) {
  document.getElementById('searchQuery').value = q;
  runSearch();
}

async function runSearch() {
  const query = document.getElementById('searchQuery').value.trim();
  const top_k = parseInt(document.getElementById('searchTopK').value);
  if (!query) { toast('Enter a search query.', 'error'); return; }

  const container = document.getElementById('searchResults');
  container.innerHTML = `<div style="text-align:center;padding:2rem"><span class="loader"></span></div>`;

  try {
    const res = await fetch(`${BASE}/api/v1/search`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query, top_k })
    });
    if (!res.ok) throw new Error((await res.json()).detail);
    const data = await res.json();
    renderSearchResults(data.results);
  } catch (err) {
    container.innerHTML = `<p style="color:var(--danger);text-align:center">Error: ${err.message}</p>`;
  }
}

function renderSearchResults(results) {
  const container = document.getElementById('searchResults');
  if (!results.length) {
    container.innerHTML = `<p style="text-align:center;color:var(--text-muted)">No results found.</p>`;
    return;
  }
  container.innerHTML = results.map((r, i) => `
    <div class="search-result-card" style="animation:fade-up 0.3s ${i * 0.06}s ease both;opacity:0">
      <div class="src-meta">
        <span class="src-source">📄 ${r.source}</span>
        <span class="src-score">Score: ${(r.score * 100).toFixed(1)}%</span>
      </div>
      <p class="src-text">${r.text}</p>
    </div>
  `).join('');
  // trigger opacity
  requestAnimationFrame(() => {
    container.querySelectorAll('.search-result-card').forEach(c => c.style.opacity = '');
  });
}

// ═══════════════════════════════════════════
// UPLOAD
// ═══════════════════════════════════════════
const dropZone = document.getElementById('dropZone');

dropZone.addEventListener('dragover', e => { e.preventDefault(); dropZone.classList.add('drag-over'); });
dropZone.addEventListener('dragleave', () => dropZone.classList.remove('drag-over'));
dropZone.addEventListener('drop', e => {
  e.preventDefault();
  dropZone.classList.remove('drag-over');
  const file = e.dataTransfer.files[0];
  if (file) uploadFile(file);
});

function handleFileSelect(event) {
  const file = event.target.files[0];
  if (file) uploadFile(file);
}

async function uploadFile(file) {
  const resultEl = document.getElementById('uploadResult');
  resultEl.style.display = 'block';
  resultEl.innerHTML = `<div style="display:flex;align-items:center;gap:0.75rem"><span class="loader"></span> Uploading <strong>${file.name}</strong>…</div>`;

  const form = new FormData();
  form.append('file', file);
  try {
    const res = await fetch(`${BASE}/api/v1/upload`, { method: 'POST', body: form });
    const data = await res.json();
    if (!res.ok) throw new Error(data.detail || 'Upload failed');
    resultEl.innerHTML = `
      <div style="display:flex;flex-direction:column;gap:0.5rem">
        <p style="color:var(--success);font-weight:600">✅ ${data.message}</p>
        <p style="color:var(--text-muted);font-size:0.85rem">
          File: <strong>${data.filename}</strong> &nbsp;|&nbsp;
          Type: ${data.type.toUpperCase()} &nbsp;|&nbsp;
          Chunks indexed: ${data.indexed}
        </p>
      </div>`;
    toast('File uploaded and indexed!', 'success');
  } catch (err) {
    resultEl.innerHTML = `<p style="color:var(--danger)">❌ ${err.message}</p>`;
    toast(`Upload error: ${err.message}`, 'error');
  }
}

// ═══════════════════════════════════════════
// CHAT
// ═══════════════════════════════════════════
const chatHistory = [];

async function sendChat() {
  const input = document.getElementById('chatInput');
  const text = input.value.trim();
  if (!text) return;
  input.value = '';

  appendMessage('user', text);
  chatHistory.push({ role: 'user', content: text });

  // typing indicator
  const typingId = appendTyping();

  try {
    const res = await fetch(`${BASE}/api/v1/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages: chatHistory })
    });
    const data = await res.json();
    removeTyping(typingId);
    const reply = data.reply || 'Sorry, I could not generate a response.';
    appendMessage('assistant', reply, data.sources);
    chatHistory.push({ role: 'assistant', content: reply });
  } catch (err) {
    removeTyping(typingId);
    appendMessage('assistant', '⚠️ Connection error. Please make sure the server is running.');
  }
}

function appendMessage(role, text, sources = []) {
  const msgs = document.getElementById('chatMessages');
  const avatar = role === 'user' ? '👤' : '🌿';
  const sourceHtml = sources.length
    ? `<div style="margin-top:0.5rem;font-size:0.75rem;color:var(--text-muted)">📚 ${sources.join(' · ')}</div>`
    : '';
  const div = document.createElement('div');
  div.className = `chat-msg ${role}`;
  div.innerHTML = `
    <div class="msg-avatar">${avatar}</div>
    <div class="msg-bubble">
      <p>${markdownLite(text)}</p>
      ${sourceHtml}
    </div>`;
  msgs.appendChild(div);
  msgs.scrollTop = msgs.scrollHeight;
}

function appendTyping() {
  const msgs = document.getElementById('chatMessages');
  const id = 'typing-' + Date.now();
  const div = document.createElement('div');
  div.className = 'chat-msg assistant';
  div.id = id;
  div.innerHTML = `
    <div class="msg-avatar">🌿</div>
    <div class="msg-bubble">
      <div class="typing-indicator">
        <div class="typing-dot"></div>
        <div class="typing-dot"></div>
        <div class="typing-dot"></div>
      </div>
    </div>`;
  msgs.appendChild(div);
  msgs.scrollTop = msgs.scrollHeight;
  return id;
}

function removeTyping(id) {
  document.getElementById(id)?.remove();
}

// ═══════════════════════════════════════════
// STATS — load real stats from API
// ═══════════════════════════════════════════
async function loadStats() {
  try {
    const res = await fetch(`${BASE}/api/v1/stats`);
    if (!res.ok) return;
    // stats are shown via the hard-coded dashboard values for now
  } catch { /* offline fallback — dashboard uses static values */ }
}

loadStats();
