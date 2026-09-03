const isFiveM = typeof GetParentResourceName === 'function';

const els = {
  hud: document.getElementById('hud'),
  fps: document.getElementById('val-fps'),
  ping: document.getElementById('val-ping'),
  id: document.getElementById('val-id'),
  players: document.getElementById('val-players'),
  time: document.getElementById('val-time'),
  voice: document.getElementById('val-voice'),
  discord: document.getElementById('val-discord'),
  server: document.getElementById('val-server'),
  tagline: document.getElementById('val-tagline'),
  fpsCard: document.querySelector('[data-key="fps"]'),
  pingCard: document.querySelector('[data-key="ping"]')
};

function pad(value) {
  return String(value).padStart(2, '0');
}

function clockText(date) {
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function toneForFps(fps) {
  if (fps >= 80) return 'ok';
  if (fps >= 50) return 'warn';
  return 'hot';
}

function toneForPing(ping) {
  if (ping <= 50) return 'ok';
  if (ping <= 100) return 'warn';
  return 'hot';
}

function render(state) {
  if (typeof state.fps === 'number') {
    els.fps.textContent = String(state.fps);
    els.fpsCard.dataset.tone = toneForFps(state.fps);
  }

  if (typeof state.ping === 'number') {
    els.ping.innerHTML = `${state.ping}<span class="unit">ms</span>`;
    els.pingCard.dataset.tone = toneForPing(state.ping);
  }

  if (state.id !== undefined) {
    els.id.textContent = String(state.id);
  }

  if (typeof state.players === 'number') {
    const max = state.maxPlayers || 128;
    els.players.innerHTML = `${state.players}<span class="unit">/${max}</span>`;
  }

  if (state.voice) {
    els.voice.textContent = state.voice;
  }

  if (state.discord) {
    els.discord.textContent = state.discord;
  }

  if (state.serverName) {
    els.server.textContent = state.serverName;
  }

  if (state.tagline) {
    els.tagline.textContent = state.tagline;
  }

  els.time.textContent = clockText(new Date());
}

window.addEventListener('message', (event) => {
  const data = event.data || {};

  if (data.action === 'toggle') {
    els.hud.classList.toggle('is-hidden', data.show === false);
    return;
  }

  if (data.action === 'init' || data.action === 'update') {
    render(data);
  }
});

function startDemo() {
  document.body.classList.add('demo');

  const voices = ['Fluisteren', 'Normaal', 'Schreeuwen'];
  const state = {
    fps: 144,
    ping: 24,
    id: 12,
    players: 48,
    maxPlayers: 128,
    voice: 'Normaal',
    discord: 'discord.gg/mallorca',
    serverName: 'Mallorca',
    tagline: 'Islas Baleares'
  };

  render(state);

  setInterval(() => {
    const swing = Math.round((Math.random() - 0.45) * 10);
    state.fps = Math.max(42, Math.min(165, state.fps + swing));
    state.ping = Math.max(12, Math.min(140, state.ping + Math.round((Math.random() - 0.5) * 8)));
    if (Math.random() < 0.12) {
      state.players = Math.max(12, Math.min(128, state.players + (Math.random() > 0.5 ? 1 : -1)));
    }
    if (Math.random() < 0.08) {
      state.voice = voices[Math.floor(Math.random() * voices.length)];
    }
    render(state);
  }, 700);

  window.addEventListener('keydown', (event) => {
    if (event.key === 'F7') {
      event.preventDefault();
      els.hud.classList.toggle('is-hidden');
    }
  });
}

if (!isFiveM) {
  startDemo();
} else {
  render({ fps: 0, ping: 0, id: 0, players: 0, maxPlayers: 128, voice: 'Normaal' });
}
