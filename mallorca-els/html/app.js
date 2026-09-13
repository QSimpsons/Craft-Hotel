(() => {
  const panel = document.getElementById('panel');
  const status = document.getElementById('status');
  const veh = document.getElementById('veh');
  const sirenBtn = document.getElementById('siren');

  function render(data = {}) {
    const stage = Number(data.stage) || 0;
    document.querySelectorAll('.stages [data-stage]').forEach((btn) => {
      btn.classList.toggle('on', Number(btn.getAttribute('data-stage')) <= stage && stage > 0);
    });
    sirenBtn.classList.toggle('on', !!data.siren);
    status.textContent = data.stageName || 'UIT';
    veh.textContent = data.vehicle || data.model || 'fmltow / dlbrickade';
    if (data.visible || stage > 0) {
      panel.classList.add('visible');
      panel.setAttribute('aria-hidden', 'false');
    } else {
      panel.classList.remove('visible');
      panel.setAttribute('aria-hidden', 'true');
    }
  }

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'show') render(msg.data || {});
    else if (msg.action === 'hide') {
      panel.classList.remove('visible');
      panel.setAttribute('aria-hidden', 'true');
    }
  });

  if (typeof GetParentResourceName !== 'function') {
    document.body.classList.add('demo-mode');
    const demo = [
      { visible: true, stage: 0, stageName: 'UIT', siren: false, vehicle: 'FML Tow' },
      { visible: true, stage: 1, stageName: 'CRUISE', siren: false, vehicle: 'FML Tow' },
      { visible: true, stage: 2, stageName: 'WAARSCHUWING', siren: false, vehicle: 'DL Brickade' },
      { visible: true, stage: 3, stageName: 'VOL', siren: true, vehicle: 'DL Brickade' }
    ];
    let i = 0;
    const tick = () => {
      render(demo[i % demo.length]);
      i += 1;
    };
    tick();
    setInterval(tick, 1600);
  }
})();
