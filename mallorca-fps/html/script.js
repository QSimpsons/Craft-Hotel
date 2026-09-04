const RESOURCE_NAME = 'mallorca-fps';

window.addEventListener('message', function(event) {
    let data = event.data;

    if (data.action === "open") {
        document.getElementById('panel-container').style.display = 'block';
    } else if (data.action === "close") {
        document.getElementById('panel-container').style.display = 'none';
    } else if (data.action === "updateStats") {
        document.getElementById('stat-fps').innerText = data.fps;
        document.getElementById('stat-ping').innerText = data.ping;
        document.getElementById('stat-health').innerText = data.health;
        document.getElementById('stat-armor').innerText = data.armor;
        document.getElementById('stat-location').innerText = data.location;
    }
});

function sendAction(name, status = null) {
    fetch(`https://${RESOURCE_NAME}/toggleSetting`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ setting: name, status: status })
    }).catch(err => console.log("Fetch error: ", err));
}

const cards = ['btn-laag', 'btn-boost', 'btn-texturen', 'btn-nogpu', 'btn-grafics', 'btn-vignette', 'btn-zwartwit', 'btn-schaduwen'];

cards.forEach(id => {
    let element = document.getElementById(id);
    if (element) {
        element.addEventListener('click', function() {
            this.classList.toggle('active');
            let isActive = this.classList.contains('active');
            sendAction(id, isActive);
        });
    }
});

function closeMenu() {
    fetch(`https://${RESOURCE_NAME}/close`, { method: 'POST' }).catch(err => console.log("Fetch error: ", err));
}

document.getElementById('btn-close').addEventListener('click', closeMenu);
document.getElementById('icon-close').addEventListener('click', closeMenu);

document.getElementById('btn-reset').addEventListener('click', function() {
    cards.forEach(id => {
        let element = document.getElementById(id);
        if (element) element.classList.remove('active');
    });
    fetch(`https://${RESOURCE_NAME}/reset`, { method: 'POST' }).catch(err => console.log("Fetch error: ", err));
});

window.addEventListener('keydown', function(event) {
    if (event.key === "Escape") {
        closeMenu();
    }
});

// Browser preview buiten FiveM
if (!window.invokeNative) {
    const panel = document.getElementById('panel-container');
    panel.style.display = 'block';
    document.getElementById('stat-fps').innerText = '144';
    document.getElementById('stat-ping').innerText = '18';
    document.getElementById('stat-health').innerText = '100';
    document.getElementById('stat-armor').innerText = '50';
    document.getElementById('stat-location').innerText = 'Palma de Mallorca';
    document.body.style.background =
        'radial-gradient(120% 80% at 50% 0%, #3d1c08 0%, #120c08 55%, #070504 100%)';
}
