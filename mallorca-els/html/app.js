(() => {
  const panel = document.getElementById('panel');
  const status = document.getElementById('status');
  const veh = document.getElementById('veh');
  const sceneBtn = document.getElementById('scene');
  const bar = document.getElementById('bar');
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

  function modeFor(data) {
    if (data.scene) return 'scene';
    const stage = Number(data.stage) || 0;
    if (stage === 1) return 'rear';
    if (stage === 2) return 'sweep';
    if (stage >= 3) return 'full';
    return 'off';
  }

  function render(data = {}) {
    const stage = Number(data.stage) || 0;
    document.querySelectorAll('.row [data-stage]').forEach((btn) => {
      const value = Number(btn.getAttribute('data-stage'));
      btn.classList.toggle('on', value === stage);
    });
    sceneBtn.classList.toggle('on', !!data.scene);
    status.textContent = data.scene ? 'WERKLICHT' : (data.stageName || 'UIT');
    veh.textContent = data.vehicle || data.model || 'fmltow / dlbrickade';
    bar.setAttribute('data-mode', modeFor(data));
    if (data.visible) {
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
      { visible: true, stage: 0, stageName: 'UIT', scene: false, vehicle: 'FML Tow' },
      { visible: true, stage: 1, stageName: 'ACHTER', scene: false, vehicle: 'FML Tow' },
      { visible: true, stage: 2, stageName: 'ZWAAI', scene: false, vehicle: 'DL Brickade' },
      { visible: true, stage: 3, stageName: 'VOL', scene: false, vehicle: 'DL Brickade' },
      { visible: true, stage: 0, stageName: 'UIT', scene: true, vehicle: 'FML Tow' }
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
      gateText.textContent = 'Je zit in de wagen. Schakelkast aan (1/2/3/0 · R). Geen sirene.';
      i = 0;
      render(demo[0]);
      stopCycle();
      cycleTimer = setInterval(() => {
        if (!seated) return;
        i += 1;
        render(demo[i % demo.length]);
      }, 1700);
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
