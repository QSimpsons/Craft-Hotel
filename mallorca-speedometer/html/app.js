(() => {
  const ARC_LEN = 112; // lengte van de horizontale snelheidsbalk

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
    engineBar: document.getElementById('engine-bar'),
    bodyBar: document.getElementById('body-bar'),
    demo: document.getElementById('demo'),
  };

  const state = {
    left: false,
    right: false,
    hazard: false,
    handbrake: false,
  };

  function setActive(node, on) {
    node.classList.toggle('active', !!on);
  }

  function setStatus(node, status) {
    node.classList.remove('green', 'yellow', 'red');
    node.classList.add(status || 'green');
  }

  function setBar(node, percent, status) {
    const p = Math.max(0, Math.min(100, Number(percent) || 0));
    node.style.transform = `scaleX(${p / 100})`;
    node.classList.remove('green', 'yellow', 'red');
    node.classList.add(status || 'green');
  }

  function update(data = {}) {
    const max = Number(data.maxSpeed) || 280;
    const speed = Math.max(0, Math.min(max, Number(data.speed) || 0));
    const ratio = speed / max;

    el.speed.textContent = String(Math.round(speed));
    el.unit.textContent = data.unit || 'km/h';
    if (el.arc) {
      el.arc.style.strokeDashoffset = String(ARC_LEN - ARC_LEN * ratio);
    }

    setActive(el.left, data.left);
    setActive(el.right, data.right);
    setActive(el.hazard, data.hazard);
    setActive(el.handbrake, data.handbrake);

    setStatus(el.engine, data.engine);
    setStatus(el.damage, data.damage);

    const enginePct = data.engineHealth != null ? data.engineHealth : (
      data.engine === 'green' ? 90 : data.engine === 'yellow' ? 50 : 15
    );
    const bodyPct = data.bodyHealth != null ? data.bodyHealth : (
      data.damage === 'green' ? 90 : data.damage === 'yellow' ? 50 : 15
    );

    setBar(el.engineBar, enginePct, data.engine);
    setBar(el.bodyBar, bodyPct, data.damage);

    el.root.classList.add('visible');
    el.root.setAttribute('aria-hidden', 'false');
  }

  function hide() {
    el.root.classList.remove('visible');
    el.root.setAttribute('aria-hidden', 'true');
  }

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'update') {
      update(msg.data || {});
    } else if (msg.action === 'hide') {
      hide();
    }
  });

  // Browser preview buiten FiveM
  const isNui = typeof GetParentResourceName === 'function';
  if (!isNui) {
    document.body.classList.add('demo-mode');
    el.demo.classList.remove('hidden');

    const syncDemo = () => {
      const engine = document.getElementById('demo-engine').value;
      const damage = document.getElementById('demo-damage').value;
      update({
        speed: Number(document.getElementById('demo-speed').value),
        maxSpeed: 280,
        unit: 'km/h',
        engine,
        damage,
        engineHealth: engine === 'green' ? 92 : engine === 'yellow' ? 48 : 12,
        bodyHealth: damage === 'green' ? 88 : damage === 'yellow' ? 42 : 10,
        left: state.left || state.hazard,
        right: state.right || state.hazard,
        hazard: state.hazard,
        handbrake: state.handbrake,
      });
    };

    document.getElementById('demo-speed').addEventListener('input', syncDemo);
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
        }

        el.demo.querySelectorAll('[data-toggle]').forEach((b) => {
          const k = b.getAttribute('data-toggle');
          b.classList.toggle('active', !!state[k]);
        });
        syncDemo();
      });
    });

    syncDemo();
  }
})();
