(() => {
  const panel = document.getElementById('panel');
  const status = document.getElementById('status');
  const veh = document.getElementById('veh');
  const sirenBtn = document.getElementById('siren');
  const gate = document.getElementById('gate');
  const gateText = document.getElementById('gate-text');
  const enterBtn = document.getElementById('enter');
  const exitBtn = document.getElementById('exit');
  let seated = false;
  let cycleTimer = null;

  function hidePanel() {
    panel.classList.remove('visible');
    panel.setAttribute('aria-hidden', 'true');
  }

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
      hidePanel();
    }
  }

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'show') render(msg.data || {});
    else if (msg.action === 'hide') hidePanel();
  });

  if (typeof GetParentResourceName !== 'function') {
    document.body.classList.add('demo-mode');
    if (gate) gate.hidden = false;
    hidePanel();

    const demo = [
      { visible: true, stage: 1, stageName: 'CRUISE', siren: false, vehicle: 'FML Tow' },
      { visible: true, stage: 2, stageName: 'WAARSCHUWING', siren: false, vehicle: 'DL Brickade' },
      { visible: true, stage: 3, stageName: 'VOL', siren: true, vehicle: 'DL Brickade' }
    ];
    let i = 0;

    function stopCycle() {
      if (cycleTimer) {
        clearInterval(cycleTimer);
        cycleTimer = null;
      }
    }

    enterBtn.addEventListener('click', () => {
      seated = true;
      enterBtn.hidden = true;
      exitBtn.hidden = false;
      gateText.textContent = 'Je zit in de fmltow. ELS staat aan.';
      i = 0;
      render(demo[0]);
      stopCycle();
      cycleTimer = setInterval(() => {
        if (!seated) return;
        i += 1;
        render(demo[i % demo.length]);
      }, 1600);
    });

    exitBtn.addEventListener('click', () => {
      seated = false;
      stopCycle();
      hidePanel();
      enterBtn.hidden = false;
      exitBtn.hidden = true;
      gateText.textContent = 'ELS staat uit. Stap eerst in de fmltow of dlbrickade.';
    });
  }
})();
