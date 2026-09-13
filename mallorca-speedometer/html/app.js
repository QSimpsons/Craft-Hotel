(() => {
  const ARC_TOTAL = 2 * Math.PI * 48;
  const ARC_VISIBLE = ARC_TOTAL * 0.75;
  const ARC_HIDDEN = ARC_TOTAL - ARC_VISIBLE;
  const FUEL_CIRC = 2 * Math.PI * 17;

  const el = {
    root: document.getElementById('speedo'),
    speed: document.getElementById('speed'),
    unit: document.getElementById('unit'),
    arc: document.getElementById('arc'),
    left: document.getElementById('ind-left'),
    right: document.getElementById('ind-right'),
    hazard: document.getElementById('ind-hazard'),
    engine: document.getElementById('ind-engine'),
    damage: document.getElementById('ind-damage'),
    handbrake: document.getElementById('ind-handbrake'),
    lights: document.getElementById('ind-lights'),
    fuel: document.getElementById('fuel'),
    fuelArc: document.getElementById('fuel-arc'),
    fuelPct: document.getElementById('fuel-pct'),
    demo: document.getElementById('demo'),
  };

  if (el.arc) {
    el.arc.style.strokeDasharray = String(ARC_TOTAL);
    el.arc.style.strokeDashoffset = String(ARC_TOTAL);
  }
  if (el.fuelArc) {
    el.fuelArc.style.strokeDasharray = String(FUEL_CIRC);
    el.fuelArc.style.strokeDashoffset = '0';
  }

  const state = {
    left: false,
    right: false,
    hazard: false,
    handbrake: false,
    lights: true,
  };

  function setActive(node, on) {
    if (!node) return;
    node.classList.toggle('active', !!on);
  }

  function setStatus(node, status) {
    if (!node) return;
    node.classList.remove('green', 'yellow', 'red');
    node.classList.add(status || 'green');
  }

  function fuelStatus(percent, explicit) {
    if (explicit) return explicit;
    if (percent >= 40) return 'green';
    if (percent >= 15) return 'yellow';
    return 'red';
  }

  function setFuel(percent, status) {
    const p = Math.max(0, Math.min(100, Number(percent) || 0));
    const st = fuelStatus(p, status);
    if (el.fuelPct) el.fuelPct.textContent = `${Math.round(p)}%`;
    if (el.fuelArc) {
      el.fuelArc.style.strokeDashoffset = String(FUEL_CIRC * (1 - p / 100));
    }
    if (el.fuel) {
      el.fuel.classList.remove('green', 'yellow', 'red');
      el.fuel.classList.add(st);
      el.fuel.title = `Brandstof ${Math.round(p)}%`;
    }
  }

  function update(data = {}) {
    const max = Number(data.maxSpeed) || 280;
    const speed = Math.max(0, Math.min(max, Number(data.speed) || 0));
    const ratio = speed / max;

    el.speed.textContent = String(Math.round(speed));
    el.unit.textContent = (data.unit || 'km/h').toUpperCase();

    if (el.arc) {
      el.arc.style.strokeDashoffset = String(ARC_HIDDEN + ARC_VISIBLE * (1 - ratio));
    }

    setActive(el.left, data.left);
    setActive(el.right, data.right);
    setActive(el.hazard, data.hazard);
    setActive(el.handbrake, data.handbrake);

    setStatus(el.engine, data.engine);
    setStatus(el.damage, data.damage);
    setFuel(data.fuel != null ? data.fuel : 100, data.fuelState);

    if (el.lights) {
      el.lights.classList.toggle('on', !!data.lights);
    }

    el.root.classList.add('visible');
    el.root.setAttribute('aria-hidden', 'false');
  }

  function hide() {
    el.root.classList.remove('visible');
    el.root.setAttribute('aria-hidden', 'true');
  }

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'update') update(msg.data || {});
    else if (msg.action === 'hide') hide();
  });

  const isNui = typeof GetParentResourceName === 'function';
  if (!isNui) {
    document.body.classList.add('demo-mode');
    el.demo.classList.remove('hidden');

    const syncDemo = () => {
      const engine = document.getElementById('demo-engine').value;
      const damage = document.getElementById('demo-damage').value;
      const fuel = Number(document.getElementById('demo-fuel').value);
      update({
        speed: Number(document.getElementById('demo-speed').value),
        maxSpeed: 280,
        unit: 'km/h',
        engine,
        damage,
        fuel,
        fuelState: fuelStatus(fuel),
        left: state.left || state.hazard,
        right: state.right || state.hazard,
        hazard: state.hazard,
        handbrake: state.handbrake,
        lights: state.lights,
      });
    };

    document.getElementById('demo-speed').addEventListener('input', syncDemo);
    document.getElementById('demo-fuel').addEventListener('input', syncDemo);
    document.getElementById('demo-engine').addEventListener('change', syncDemo);
    document.getElementById('demo-damage').addEventListener('change', syncDemo);

    el.demo.querySelectorAll('[data-toggle]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const key = btn.getAttribute('data-toggle');
        if (key === 'hazard') {
          state.hazard = !state.hazard;
          if (state.hazard) {
            state.left = false;
            state.right = false;
          }
        } else if (key === 'left') {
          state.hazard = false;
          state.left = !state.left;
          if (state.left) state.right = false;
        } else if (key === 'right') {
          state.hazard = false;
          state.right = !state.right;
          if (state.right) state.left = false;
        } else if (key === 'handbrake') {
          state.handbrake = !state.handbrake;
        } else if (key === 'lights') {
          state.lights = !state.lights;
        }

        el.demo.querySelectorAll('[data-toggle]').forEach((b) => {
          const k = b.getAttribute('data-toggle');
          b.classList.toggle('active', !!state[k]);
        });
        syncDemo();
      });
    });

    const lightsBtn = el.demo.querySelector('[data-toggle="lights"]');
    if (lightsBtn) lightsBtn.classList.add('active');
    syncDemo();
  }
})();
