const isFiveM = typeof GetParentResourceName === 'function';

const DEFAULT_PRESETS = [
  { id: 1, title: 'Kwaliteit', description: 'Volledig detail en alle effecten.' },
  { id: 2, title: 'Lichte boost', description: 'Een kleine stap minder detail veraf.' },
  { id: 3, title: 'Licht gebalanceerd', description: 'Meer detail dan Gebalanceerd.' },
  { id: 4, title: 'Gebalanceerd', description: 'Balans tussen beeld en prestaties.' },
  { id: 5, title: 'Prestaties', description: 'Minder detail en verre voertuiglichten.' },
  { id: 6, title: 'Extra prestaties', description: 'Minder detail; decals blijven zichtbaar.' },
  { id: 7, title: 'Hoge FPS', description: 'Nog minder detail op afstand.' },
  { id: 8, title: 'Maximale FPS', description: 'Laagste detail; decals uit.' }
];

const overlay = document.getElementById('overlay');
const grid = document.getElementById('grid');
const closeBtn = document.getElementById('btn-close');

let selectedId = 1;
let presets = DEFAULT_PRESETS;

function resourceName() {
  return GetParentResourceName();
}

function pad(id) {
  return String(id).padStart(2, '0');
}

function render() {
  grid.innerHTML = presets.map((preset) => {
    const active = preset.id === selectedId ? ' is-active' : '';
    return `
      <button class="card${active}" type="button" role="radio" aria-checked="${preset.id === selectedId}" data-id="${preset.id}">
        <span class="card-index">${pad(preset.id)}</span>
        <span class="card-radio" aria-hidden="true"></span>
        <h2>${preset.title}</h2>
        <p>${preset.description}</p>
      </button>
    `;
  }).join('');
}

function setOpen(open) {
  overlay.classList.toggle('is-open', open);
  document.body.classList.toggle('menu-open', open);
}

function closeMenu() {
  setOpen(false);
  if (isFiveM) {
    fetch(`https://${resourceName()}/close`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: '{}'
    });
  }
}

function selectPreset(id) {
  selectedId = id;
  render();
  if (isFiveM) {
    fetch(`https://${resourceName()}/select`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ id })
    });
  } else {
    localStorage.setItem('mallorca_fps_preset', String(id));
  }
}

grid.addEventListener('click', (event) => {
  const card = event.target.closest('.card');
  if (!card) {
    return;
  }
  selectPreset(Number(card.dataset.id));
});

closeBtn.addEventListener('click', closeMenu);

window.addEventListener('keydown', (event) => {
  if (event.key === 'Escape' && overlay.classList.contains('is-open')) {
    event.preventDefault();
    closeMenu();
  }

  if (!isFiveM && (event.key === 'F7') && !overlay.classList.contains('is-open')) {
    event.preventDefault();
    setOpen(true);
  }
});

window.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.action === 'open') {
    if (Array.isArray(data.presets) && data.presets.length) {
      presets = data.presets;
    }
    selectedId = Number(data.selected) || selectedId;
    render();
    setOpen(true);
  }
  if (data.action === 'close') {
    setOpen(false);
  }
});

if (!isFiveM) {
  document.body.classList.add('demo');
  const saved = Number(localStorage.getItem('mallorca_fps_preset'));
  if (saved >= 1 && saved <= 8) {
    selectedId = saved;
  }
  render();
  setOpen(true);
} else {
  setOpen(false);
}
