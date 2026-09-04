Future = {}

$(document).ready(function () {
    window.addEventListener('message', function (event) {
        var payload = event.data || {};
        if (payload.action === 'updateHud') {
            Future.updateHud(payload.data);
        }
    });
});

function accountMoney(accounts, name) {
    if (!accounts || !accounts[name]) {
        return 0;
    }

    var value = accounts[name].money;
    return (typeof value === 'number' && isFinite(value)) ? value : 0;
}

function jobIconName(jobName) {
    if (!jobName) {
        return 'unemployed';
    }

    if (jobName.indexOf('off') === 0 && jobName.length > 3) {
        return jobName.substring(3);
    }

    return jobName;
}

function setJobIcon(selector, jobName) {
    var $img = $(selector);
    var src = 'img/jobs/' + jobIconName(jobName) + '.png';
    $img.off('error.esx115').on('error.esx115', function () {
        this.src = 'img/jobs/unemployed.png';
    });
    $img.attr('src', src);
}

function applyNeedBar(name, percent) {
    percent = Math.max(0, Math.min(100, Number(percent) || 0));
    var empty = 100 - percent;
    var fill = (name === 'thirst')
        ? 'rgba(58, 125, 170, 0.7)'
        : 'rgba(168, 170, 58, 0.7)';

    $('[data-needed="' + name + '"]').css({
        background: 'linear-gradient(to bottom, rgba(0, 0, 0, 0.6) ' + empty + '%, ' + fill + ' ' + percent + '%)'
    });
}

Future.updateHud = function (data) {
    if (!data || data.hud === false) {
        $('.future-hud').hide();
        return;
    }

    var accounts = data.accounts || {};
    $('[data-money="money"]').html('€' + number_format(accountMoney(accounts, 'money'), 0, '.', '.'));
    $('[data-money="bank"]').html('€' + number_format(accountMoney(accounts, 'bank'), 0, '.', '.'));
    $('[data-money="black_money"]').html('€' + number_format(accountMoney(accounts, 'black_money'), 0, '.', '.'));

    var statuses = Array.isArray(data.status) ? data.status : [];
    for (var i = 0; i < statuses.length; i++) {
        var status = statuses[i];
        if (!status || !status.name) {
            continue;
        }

        if (status.name === 'thirst' || status.name === 'hunger') {
            applyNeedBar(status.name, status.percent);
        }
    }

    var jobData = data.job || { name: 'unemployed', label: 'Werkloos', grade_label: '' };
    var job2Data = data.job2;

    if (job2Data && job2Data.name && job2Data.name !== 'unemployed2' && job2Data.name !== 'unemployed' && job2Data.name.indexOf('off') === -1) {
        $('.future-secondjob').css({ display: 'flex' });
        setJobIcon('.future-secondjob-cat', job2Data.name);
        $('[data-job="second"]').html((job2Data.label || job2Data.name) + ' | ' + (job2Data.grade_label || ''));
    } else {
        $('.future-secondjob').css({ display: 'none' });
    }

    setJobIcon('.future-mainjob-cat', jobData.name);
    $('[data-job="main"]').html((jobData.label || 'Werkloos') + ' | ' + (jobData.grade_label || ''));
    $('[data-job="idnum"]').html(data.idnum != null ? String(data.idnum) : '');
    $('.future-hud').css({ display: 'block' });
};

function number_format(number, decimals, dec_point, thousands_point) {
    number = Number(number);
    if (!isFinite(number)) {
        number = 0;
    }

    if (!decimals) {
        decimals = 0;
    }
    if (!dec_point) {
        dec_point = '.';
    }
    if (!thousands_point) {
        thousands_point = ',';
    }

    number = number.toFixed(decimals);
    number = number.replace('.', dec_point);
    var splitNum = number.split(dec_point);
    splitNum[0] = splitNum[0].replace(/\B(?=(\d{3})+(?!\d))/g, thousands_point);
    return splitNum.join(dec_point);
}
