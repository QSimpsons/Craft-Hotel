(() => {
  const titles = {
    home: ['Overzicht', 'Depot · inbeslagname · pechhulp'],
    tow: ['Takelen', 'Haak of flatbed — O om vast te maken'],
    impound: ['Inbeslagname', 'Kentekens, reden en vrijgave'],
    calls: ['Oproepen', 'Spelers en NPC-pechhulp'],
    bill: ['Factuur', 'Stuur een rekening naar iemand in de buurt'],
    garage: ['Garage', 'Pak een takelwagen bij het depot'],
  };

  const el = {
    app: document.getElementById('app'),
    demo: document.getElementById('demo'),
    duty: document.getElementById('btn-duty'),
    title: document.getElementById('page-title'),
    sub: document.getElementById('page-sub'),
    statDuty: document.getElementById('stat-duty'),
    statHook: document.getElementById('stat-hook'),
    statCalls: document.getElementById('stat-calls'),
    statImpound: document.getElementById('stat-impound'),
    homeLoad: document.getElementById('home-load'),
    towTruck: document.getElementById('tow-truck'),
    towTarget: document.getElementById('tow-target'),
    towAttached: document.getElementById('tow-attached'),
    impoundList: document.getElementById('impound-list'),
    callList: document.getElementById('call-list'),
    billTarget: document.getElementById('bill-target'),
    garageList: document.getElementById('garage-list'),
    search: document.getElementById('impound-search'),
  };

  const isNui = typeof GetParentResourceName === 'function';
  const resName = isNui ? GetParentResourceName() : 'mallorca-takel';

  const state = {
    duty: false,
    employee: true,
    civilian: false,
    calls: [],
    impounds: [],
    players: [],
    garage: [],
    truck: null,
    attached: null,
    target: null,
    prices: { impound: 1500, minBill: 100, maxBill: 25000 },
    page: 'home',
  };

  function post(name, data) {
    if (!isNui) {
      handleDemoAction(name, data || {});
      return;
    }
    fetch(`https://${resName}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {}),
    });
  }

  function vehicleLine(info, empty) {
    if (!info || !info.plate) return empty;
    return `${info.model || 'Voertuig'} · ${info.plate} · motor ${info.engine ?? '—'}% · schade ${info.body ?? '—'}%`;
  }

  function setPage(page) {
    state.page = page;
    document.querySelectorAll('.page').forEach((node) => {
      node.classList.toggle('visible', node.id === `page-${page}`);
    });
    document.querySelectorAll('.nav nav button').forEach((btn) => {
      btn.classList.toggle('active', btn.getAttribute('data-page') === page);
    });
    const meta = titles[page] || titles.home;
    el.title.textContent = meta[0];
    el.sub.textContent = meta[1];
  }

  function renderImpound() {
    const q = (el.search.value || '').toUpperCase();
    const rows = (state.impounds || []).filter((row) => {
      const plate = String(row.plate || '').toUpperCase();
      return !q || plate.includes(q);
    });
    if (!rows.length) {
      el.impoundList.innerHTML = '<div class="empty">Geen voertuigen inbeslaggenomen.</div>';
      return;
    }
    el.impoundList.innerHTML = rows.map((row) => `
      <div class="item">
        <div>
          <b>${row.plate || 'ONBEKEND'}</b>
          <small>${row.model || 'Voertuig'} · ${row.reason || 'Getakeld'} · €${row.price || state.prices.impound}</small>
        </div>
        <button type="button" data-release="${row.id}">Vrijgeven</button>
      </div>
    `).join('');
  }

  function renderCalls() {
    const rows = state.calls || [];
    if (!rows.length) {
      el.callList.innerHTML = '<div class="empty">Geen openstaande oproepen.</div>';
      return;
    }
    el.callList.innerHTML = rows.map((row) => `
      <div class="item">
        <div>
          <b>${row.callerName || row.caller_name || 'Oproep'} · ${row.kind === 'npc' ? 'NPC' : 'Speler'}</b>
          <small>${row.message || ''} · status ${row.status}</small>
        </div>
        <button type="button" data-call="${row.id}">Aannemen</button>
      </div>
    `).join('');
  }

  function renderPlayers() {
    const rows = state.players || [];
    if (!rows.length) {
      el.billTarget.innerHTML = '<option value="">Niemand in de buurt</option>';
      return;
    }
    el.billTarget.innerHTML = rows.map((p) =>
      `<option value="${p.id}">${p.name} (${p.dist}m)</option>`
    ).join('');
  }

  function renderGarage() {
    const rows = state.garage || [];
    el.garageList.innerHTML = rows.map((row) => `
      <button type="button" data-model="${row.model}">${row.label || row.model}</button>
    `).join('') || '<div class="empty">Geen wagens ingesteld.</div>';
  }

  function render() {
    el.duty.classList.toggle('on', !!state.duty);
    el.duty.classList.toggle('off', !state.duty);
    el.duty.textContent = state.duty ? 'In dienst' : 'Uit dienst';
    el.statDuty.textContent = state.duty ? 'Aan' : 'Uit';
    el.statHook.textContent = state.attached && state.attached.plate ? state.attached.plate : '—';
    el.statCalls.textContent = String((state.calls || []).length);
    el.statImpound.textContent = String((state.impounds || []).length);
    el.homeLoad.textContent = vehicleLine(state.attached, 'Nog geen voertuig vastgemaakt. Gebruik O of de tab Takelen.');
    el.towTruck.textContent = vehicleLine(state.truck, 'Geen takelwagen in de buurt.');
    el.towTarget.textContent = vehicleLine(state.target, 'Ga achter (flatbed) of voor (haak) een voertuig staan.');
    el.towAttached.textContent = vehicleLine(state.attached, 'Leeg');
    renderImpound();
    renderCalls();
    renderPlayers();
    renderGarage();
  }

  function applyData(data = {}) {
    Object.assign(state, data);
    if (!state.garage || !state.garage.length) {
      state.garage = data.garage || [
        { model: 'flatbed', label: 'Flatbed' },
        { model: 'towtruck', label: 'Takelwagen' },
        { model: 'towtruck2', label: 'Takelwagen Tow' },
        { model: 'slamtruck', label: 'Slamtruck' },
      ];
    }
    render();
    document.querySelectorAll('.nav nav button').forEach((btn) => {
      const page = btn.getAttribute('data-page');
      const staffOnly = page === 'tow' || page === 'bill' || page === 'garage' || page === 'calls';
      btn.style.display = state.civilian && staffOnly ? 'none' : '';
    });
    el.duty.style.display = state.civilian ? 'none' : '';
    if (data.page) setPage(data.page);
  }

  function open(data) {
    applyData(data || {});
    el.app.classList.add('visible');
    el.app.setAttribute('aria-hidden', 'false');
  }

  function close() {
    el.app.classList.remove('visible');
    el.app.setAttribute('aria-hidden', 'true');
    post('close');
  }

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'open') open(msg.data || {});
    else if (msg.action === 'update') applyData(msg.data || {});
    else if (msg.action === 'close') {
      el.app.classList.remove('visible');
      el.app.setAttribute('aria-hidden', 'true');
    }
  });

  document.querySelectorAll('[data-page]').forEach((btn) => {
    btn.addEventListener('click', () => setPage(btn.getAttribute('data-page')));
  });

  document.getElementById('btn-close').addEventListener('click', close);
  document.getElementById('btn-duty').addEventListener('click', () => post('toggleDuty'));
  document.getElementById('btn-attach').addEventListener('click', () => post('attach'));
  document.getElementById('btn-detach').addEventListener('click', () => post('detach'));
  document.getElementById('btn-impound').addEventListener('click', () => post('impound'));
  document.getElementById('btn-store').addEventListener('click', () => post('storeTruck'));
  document.getElementById('btn-refresh').addEventListener('click', () => post('refresh'));
  document.getElementById('btn-bill').addEventListener('click', () => {
    post('sendBill', {
      target: Number(el.billTarget.value),
      amount: Number(document.getElementById('bill-amount').value),
      reason: document.getElementById('bill-reason').value,
    });
  });
  el.search.addEventListener('input', renderImpound);

  el.impoundList.addEventListener('click', (ev) => {
    const btn = ev.target.closest('[data-release]');
    if (!btn) return;
    post('release', { id: Number(btn.getAttribute('data-release')) });
  });

  el.callList.addEventListener('click', (ev) => {
    const btn = ev.target.closest('[data-call]');
    if (!btn) return;
    post('acceptCall', { id: Number(btn.getAttribute('data-call')) });
  });

  el.garageList.addEventListener('click', (ev) => {
    const btn = ev.target.closest('[data-model]');
    if (!btn) return;
    post('spawnTruck', { model: btn.getAttribute('data-model') });
  });

  document.addEventListener('keydown', (ev) => {
    if (ev.key === 'Escape' && el.app.classList.contains('visible')) close();
  });

  function demoState() {
    return {
      duty: state.duty,
      employee: true,
      garage: [
        { model: 'flatbed', label: 'Flatbed' },
        { model: 'towtruck', label: 'Takelwagen' },
        { model: 'towtruck2', label: 'Takelwagen Tow' },
        { model: 'slamtruck', label: 'Slamtruck' },
      ],
      truck: state.truck,
      attached: state.attached,
      target: state.target,
      players: [{ id: 12, name: 'Alex Rivera', dist: 2.1 }],
      calls: state.calls,
      impounds: state.impounds,
      prices: { impound: 1500, minBill: 100, maxBill: 25000 },
    };
  }

  function handleDemoAction(name, data) {
    if (name === 'toggleDuty') state.duty = !state.duty;
    if (name === 'attach') {
      state.attached = state.target || { plate: 'MAL 482', model: 'SULTAN', engine: 18, body: 24 };
      state.target = null;
    }
    if (name === 'detach') {
      state.target = state.attached;
      state.attached = null;
    }
    if (name === 'impound' && state.attached) {
      state.impounds = [{
        id: Date.now(),
        plate: state.attached.plate,
        model: state.attached.model,
        reason: 'Getakeld',
        price: 1500,
      }, ...state.impounds];
      state.attached = null;
    }
    if (name === 'release') {
      state.impounds = state.impounds.filter((row) => row.id !== data.id);
    }
    if (name === 'acceptCall') {
      state.calls = state.calls.filter((row) => row.id !== data.id);
    }
    if (name === 'close') {
      el.app.classList.remove('visible');
      return;
    }
    applyData(demoState());
  }

  if (!isNui) {
    document.body.classList.add('demo-mode');
    el.demo.classList.remove('hidden');
    state.truck = { plate: 'TAKEL', model: 'FLATBED', engine: 100, body: 100 };
    state.target = { plate: 'MAL 482', model: 'SULTAN', engine: 18, body: 24 };
    state.calls = [
      { id: 1, callerName: 'Sara', kind: 'player', message: 'Motor doet het niet', status: 'open' },
      { id: 2, callerName: 'Pechhulp', kind: 'npc', message: 'Voertuig gestrand', status: 'open' },
    ];
    state.impounds = [
      { id: 9, plate: 'RP 190', model: 'ORACLE', reason: 'Fout geparkeerd', price: 1500 },
    ];
    open(demoState());

    document.getElementById('demo-open').addEventListener('click', () => open(demoState()));
    document.getElementById('demo-call').addEventListener('click', () => {
      state.calls.unshift({
        id: Date.now(),
        callerName: 'Nieuwe pechhulp',
        kind: 'player',
        message: 'Sta stil op de snelweg',
        status: 'open',
      });
      applyData(demoState());
      setPage('calls');
    });
    document.getElementById('demo-attach').addEventListener('click', () => {
      handleDemoAction('attach', {});
      setPage('tow');
    });

    const params = new URLSearchParams(window.location.search);
    if (params.get('auto') === '1') {
      const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
      (async () => {
        await sleep(700);
        state.duty = true;
        applyData(demoState());
        await sleep(1400);
        setPage('tow');
        await sleep(900);
        handleDemoAction('attach', {});
        await sleep(1400);
        setPage('impound');
        await sleep(1400);
        setPage('calls');
        await sleep(1400);
        setPage('bill');
        await sleep(1200);
        setPage('garage');
        await sleep(1200);
        setPage('home');
      })();
    }
  }
})();
