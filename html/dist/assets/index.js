/* 187Graffiti — pre-built UI bundle (vanilla JS, no build step required) */
(() => {
    const state = {
        visible: false,
        activeTab: 'spray',
        wall: null,
        playerGang: null,
        selectedStyle: null,
        tagStyles: [],
        leaderboard: [],
        totalWalls: 0,
        sprayCount: 5,
        playerStats: null,
    };

    // DOM refs populated after buildUI()
    let panel, wallNameEl, wallOwnerEl, contestBox, contestGangEl,
        contestCountEl, contestFill, stylesGrid, gangRow, playerGangBadge,
        enemyBadge, ownBadge, gangLabel, sprayBtn, leaderboardList,
        statsSection, statsSprays, statsClaimed, statsLost,
        sprayPanel, territoryPanel, tabSpray, tabTerritory;

    // ── Helpers ────────────────────────────────────────────────────────────────

    function $(id) { return document.getElementById(id); }

    function renderWallInfo() {
        const { wall, sprayCount, playerGang } = state;
        if (!wall) return;

        wallNameEl.textContent = wall.name || '';

        const isOwn = wall.ownerGang && wall.ownerGang === playerGang;
        if (wall.ownerGang) {
            wallOwnerEl.className = `badge ${isOwn ? 'badge-success' : 'badge-danger'}`;
            wallOwnerEl.textContent = wall.ownerGang;
        } else {
            wallOwnerEl.className = 'badge badge-success';
            wallOwnerEl.textContent = 'Unclaimed';
        }

        if (wall.contestGang) {
            contestBox.style.display = '';
            contestGangEl.textContent = wall.contestGang;
            contestCountEl.textContent = `${wall.contestCount || 0}/${sprayCount}`;
            const pct = Math.min(100, ((wall.contestCount || 0) / sprayCount) * 100);
            contestFill.style.width = pct + '%';
        } else {
            contestBox.style.display = 'none';
        }
    }

    function renderStyles() {
        stylesGrid.innerHTML = '';
        state.tagStyles.forEach(style => {
            const card = document.createElement('div');
            card.className = 'style-card' + (state.selectedStyle === style.id ? ' active' : '');
            card.innerHTML = `<div class="emoji">${style.emoji}</div><div class="label">${style.label}</div>`;
            card.addEventListener('click', () => {
                state.selectedStyle = style.id;
                renderStyles();
                updateSprayBtn();
            });
            stylesGrid.appendChild(card);
        });
    }

    function updateSprayBtn() {
        const { wall, playerGang, selectedStyle } = state;
        const canSpray = playerGang && playerGang !== '' && selectedStyle;
        sprayBtn.disabled = !canSpray;

        const isEnemy = wall?.ownerGang && wall.ownerGang !== playerGang;
        const isOwn   = wall?.ownerGang && wall.ownerGang === playerGang;

        sprayBtn.textContent = !wall?.ownerGang ? '🖌️ Claim Wall'
                             : isEnemy           ? '🖌️ Contest Wall'
                             :                     '🖌️ Defend Wall';

        if (playerGang && playerGang !== '') {
            gangLabel.textContent = 'Your gang:';
            playerGangBadge.textContent = playerGang;
            gangRow.style.display = '';
        } else {
            gangLabel.textContent = 'No gang assigned';
            playerGangBadge.textContent = '';
        }

        enemyBadge.style.display = isEnemy ? '' : 'none';
        ownBadge.style.display   = isOwn   ? '' : 'none';
    }

    function renderLeaderboard() {
        leaderboardList.innerHTML = '';
        const { leaderboard, totalWalls } = state;

        if (!leaderboard || leaderboard.length === 0) {
            leaderboardList.innerHTML =
                '<div style="text-align:center;color:var(--text-secondary);padding:30px 0">' +
                '<div style="font-size:32px">🏙️</div>' +
                '<div style="margin-top:8px">No territories claimed yet.</div></div>';
        } else {
            const medals = ['🥇', '🥈', '🥉'];
            const header = document.createElement('div');
            header.style.cssText = 'display:flex;justify-content:space-between;color:var(--text-secondary);font-size:11px;padding:0 4px;margin-bottom:8px;text-transform:uppercase;letter-spacing:0.5px';
            header.innerHTML = '<span>Gang</span><span>Walls</span>';
            leaderboardList.appendChild(header);

            const list = document.createElement('div');
            list.className = 'item-list';
            leaderboard.forEach((entry, i) => {
                const pct = totalWalls > 0 ? Math.round((entry.walls / totalWalls) * 100) : 0;
                const row = document.createElement('div');
                row.className = 'item';
                row.innerHTML = `
                    <div class="item-left">
                        <div class="item-icon">${medals[i] ?? '#' + (i + 1)}</div>
                        <div>
                            <div class="item-name">${entry.gang}</div>
                            <div class="item-sub">${pct}% of territory</div>
                        </div>
                    </div>
                    <span class="badge badge-accent">${entry.walls}</span>
                `;
                list.appendChild(row);
            });
            leaderboardList.appendChild(list);
        }

        renderStats();
    }

    function renderStats() {
        const s = state.playerStats;
        if (!s) { statsSection.style.display = 'none'; return; }
        statsSection.style.display = '';
        statsSprays.textContent  = s.total_sprays  ?? 0;
        statsClaimed.textContent = s.walls_tagged  ?? 0;
        statsLost.textContent    = s.walls_lost     ?? 0;
    }

    function setTab(tab) {
        state.activeTab = tab;
        if (tab === 'spray') {
            tabSpray.classList.add('active');
            tabTerritory.classList.remove('active');
            sprayPanel.style.display = '';
            territoryPanel.style.display = 'none';
        } else {
            tabTerritory.classList.add('active');
            tabSpray.classList.remove('active');
            territoryPanel.style.display = '';
            sprayPanel.style.display = 'none';
            renderLeaderboard();
        }
    }

    function close() {
        state.visible = false;
        panel.style.display = 'none';
        S187.post('close');
    }

    // ── Build DOM ──────────────────────────────────────────────────────────────

    function buildUI() {
        const root = document.getElementById('root');
        root.innerHTML = `
<div id="g-panel" class="panel" style="width:520px;position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);display:none">
  <div class="panel-header">
    <div class="panel-title"><div class="icon">🎨</div>Graffiti Tag</div>
    <button class="btn-close" id="g-close">✕</button>
  </div>
  <div class="panel-body">
    <div class="tabs" style="margin-bottom:16px">
      <div class="tab active" id="g-tab-spray">🖌️ Tag Wall</div>
      <div class="tab" id="g-tab-territory">🏙️ Territory</div>
    </div>

    <!-- Spray panel -->
    <div id="g-spray-panel">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
        <span id="g-wall-name" style="color:var(--text-secondary);font-size:13px"></span>
        <span id="g-wall-owner"></span>
      </div>

      <div id="g-contest" class="contest-box" style="display:none">
        ⚠ Contested by <strong id="g-contest-gang"></strong>
        — <span id="g-contest-count"></span> sprays
        <div class="progress-bar" style="margin-top:6px">
          <div id="g-contest-fill" class="progress-fill" style="width:0%"></div>
        </div>
      </div>

      <div class="divider"></div>

      <div style="margin-bottom:12px">
        <div style="font-size:12px;color:var(--text-secondary);margin-bottom:8px;text-transform:uppercase;letter-spacing:0.5px">
          Select Tag Style
        </div>
        <div id="g-styles" class="style-grid"></div>
      </div>

      <div class="divider"></div>

      <div id="g-gang-row" style="display:flex;align-items:center;gap:8px;margin-bottom:12px">
        <span id="g-gang-label" style="color:var(--text-secondary);font-size:12px">Your gang:</span>
        <span id="g-gang-badge" class="badge badge-accent"></span>
        <span id="g-enemy-badge" class="badge badge-warning" style="display:none;margin-left:auto">Enemy territory</span>
        <span id="g-own-badge" class="badge badge-success" style="display:none;margin-left:auto">Your territory</span>
      </div>

      <div style="display:flex;gap:8px">
        <button id="g-spray-btn" class="btn btn-primary" style="flex:1">🖌️ Claim Wall</button>
        <button id="g-cancel-btn" class="btn btn-secondary">Cancel</button>
      </div>
    </div>

    <!-- Territory panel -->
    <div id="g-territory-panel" style="display:none">
      <div id="g-leaderboard"></div>
      <div id="g-stats-section" style="display:none">
        <div class="divider"></div>
        <div style="font-size:12px;color:var(--text-secondary);margin-bottom:8px;text-transform:uppercase;letter-spacing:0.5px">Your Stats</div>
        <div class="stat-grid">
          <div class="stat-card"><div id="g-stat-sprays" class="stat-value">0</div><div class="stat-label">Sprays</div></div>
          <div class="stat-card"><div id="g-stat-claimed" class="stat-value">0</div><div class="stat-label">Claimed</div></div>
          <div class="stat-card"><div id="g-stat-lost" class="stat-value">0</div><div class="stat-label">Lost</div></div>
        </div>
      </div>
    </div>
  </div>
</div>`;

        // Refs
        panel           = $('g-panel');
        wallNameEl      = $('g-wall-name');
        wallOwnerEl     = $('g-wall-owner');
        contestBox      = $('g-contest');
        contestGangEl   = $('g-contest-gang');
        contestCountEl  = $('g-contest-count');
        contestFill     = $('g-contest-fill');
        stylesGrid      = $('g-styles');
        gangRow         = $('g-gang-row');
        playerGangBadge = $('g-gang-badge');
        enemyBadge      = $('g-enemy-badge');
        ownBadge        = $('g-own-badge');
        gangLabel       = $('g-gang-label');
        sprayBtn        = $('g-spray-btn');
        leaderboardList = $('g-leaderboard');
        statsSection    = $('g-stats-section');
        statsSprays     = $('g-stat-sprays');
        statsClaimed    = $('g-stat-claimed');
        statsLost       = $('g-stat-lost');
        sprayPanel      = $('g-spray-panel');
        territoryPanel  = $('g-territory-panel');
        tabSpray        = $('g-tab-spray');
        tabTerritory    = $('g-tab-territory');

        // Events
        $('g-close').addEventListener('click', close);
        $('g-cancel-btn').addEventListener('click', close);
        tabSpray.addEventListener('click', () => setTab('spray'));
        tabTerritory.addEventListener('click', () => setTab('territory'));

        sprayBtn.addEventListener('click', () => {
            if (!state.selectedStyle || !state.wall) return;
            S187.post('spray', { wallId: state.wall.id, tagStyle: state.selectedStyle });
            panel.style.display = 'none';
        });

        S187.onEscape(close);
    }

    // ── Message handler ────────────────────────────────────────────────────────

    window.addEventListener('message', ({ data }) => {
        if (!data || !data.action) return;

        if (data.action === 'open') {
            const d = data.data;
            state.wall          = d.wall;
            state.playerGang    = d.playerGang;
            state.tagStyles     = d.tagStyles   || [];
            state.leaderboard   = d.leaderboard || [];
            state.totalWalls    = d.totalWalls  || 0;
            state.sprayCount    = d.sprayCount  || 5;
            state.playerStats   = d.playerStats || null;
            state.selectedStyle = state.tagStyles[0]?.id ?? null;
            state.visible       = true;

            panel.style.display   = '';
            panel.style.animation = 'panelIn 0.25s cubic-bezier(0.34,1.56,0.64,1)';
            setTab('spray');
            renderWallInfo();
            renderStyles();
            updateSprayBtn();

        } else if (data.action === 'leaderboardUpdate') {
            const lb = data.data?.leaderboard || data.leaderboard || [];
            state.leaderboard = lb;
            if (state.activeTab === 'territory') renderLeaderboard();

        } else if (data.action === 'wallStateUpdate') {
            const w = data.data?.wall;
            if (w) {
                state.wall = w;
                if (state.activeTab === 'spray') {
                    renderWallInfo();
                    updateSprayBtn();
                }
            }
        }
    });

    // ── Init ──────────────────────────────────────────────────────────────────

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', buildUI);
    } else {
        buildUI();
    }
})();
