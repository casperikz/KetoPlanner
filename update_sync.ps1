# Powershell script to inject Cloud Sync & Inset-safe styling into build_mobile_app.ps1
$ps1Path = "c:\Users\Casperikz\AndroidStudioProjects\KetoPlanner\build_mobile_app.ps1"
$txt = [System.IO.File]::ReadAllText($ps1Path, [System.Text.Encoding]::UTF8)

# 1. Add Firebase scripts to <head>
if (-not $txt.Contains('firebase-app.js')) {
    $headTarget = '<link href="https://api.fontshare.com/v2/css?f[]=satoshi@400,500,700&display=swap" rel="stylesheet">'
    $headReplacement = @"
  <link href="https://api.fontshare.com/v2/css?f[]=satoshi@400,500,700&display=swap" rel="stylesheet">
  <script src="firebase-app.js"></script>
  <script src="firebase-firestore.js"></script>
"@
    $txt = $txt.Replace($headTarget, $headReplacement)
}

# 2. Add Cloud Sync CSS
if (-not $txt.Contains('.cloud-pill')) {
    $cssTarget = '/* Converter Page */'
    $syncCss = @"
    /* Cloud Sync & Pill */
    .cloud-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 999px;
      font-size: var(--text-xs);
      font-weight: 600;
      background: var(--color-surface-offset);
      border: 1px solid var(--color-border);
      color: var(--color-text);
      cursor: pointer;
    }
    .cloud-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--color-text-faint);
    }
    .cloud-pill.connected .cloud-dot { background: var(--color-success); box-shadow: 0 0 6px var(--color-success); }
    .cloud-pill.syncing .cloud-dot { background: var(--color-warning); }
    .cloud-pill.error .cloud-dot { background: var(--color-danger); }
    .sync-status-card {
      padding: var(--space-4);
      border-radius: var(--radius-lg);
      background: var(--color-surface-2);
      border: 1px solid var(--color-border);
    }
    .sync-badge {
      font-size: var(--text-xs);
      font-weight: 700;
      padding: 3px 8px;
      border-radius: 999px;
      background: var(--color-surface-offset);
      border: 1px solid var(--color-border);
    }
    .sync-badge.live { background: #e8f5e9; color: #2e7d32; border-color: #a5d6a7; }
    [data-theme="dark"] .sync-badge.live { background: #1b3320; color: #81c784; border-color: #2e7d32; }
    .household-code-tag {
      font-family: monospace;
      font-size: 1.15rem;
      font-weight: 700;
      letter-spacing: 1px;
      padding: 6px 14px;
      border-radius: var(--radius-md);
      background: var(--color-primary-highlight);
      color: var(--color-primary);
      border: 1px solid var(--color-primary);
    }
    .sync-toast {
      position: fixed;
      top: 66px;
      left: 50%;
      transform: translateX(-50%) translateY(-20px);
      opacity: 0;
      pointer-events: none;
      background: var(--color-primary);
      color: #fff;
      padding: 8px 16px;
      border-radius: 999px;
      font-size: var(--text-xs);
      font-weight: 600;
      box-shadow: var(--shadow-md);
      z-index: 1000;
      transition: all .25s ease;
    }
    .sync-toast.show {
      transform: translateX(-50%) translateY(0);
      opacity: 1;
    }

    /* Converter Page */
"@
    $txt = $txt.Replace($cssTarget, $syncCss)
}

# 3. Add Cloud pill to header
if (-not $txt.Contains('cloudHeaderBtn')) {
    $hdrTarget = @"
    <div class="header-right">
      <button data-theme-toggle class="theme-btn" aria-label="Toggle theme">◐</button>
    </div>
"@
    $hdrReplacement = @"
    <div class="header-right" style="display:flex;gap:8px;align-items:center">
      <button id="cloudHeaderBtn" class="cloud-pill" data-tab-btn="sync" aria-label="Cloud sync">
        <span class="cloud-dot" id="cloudDot"></span>
        <span id="cloudLabel">Local</span>
      </button>
      <button data-theme-toggle class="theme-btn" aria-label="Toggle theme">◐</button>
    </div>
"@
    $txt = $txt.Replace($hdrTarget, $hdrReplacement)
}

# 4. Add Live Share & Sync menu card on Home tab
if (-not $txt.Contains('data-tab-btn="sync"')) {
    $menuTarget = @"
        <button class="menu-card" data-tab-btn="settings">
          <div class="menu-icon-wrap">⚙️</div>
          <div class="menu-card-info">
            <strong>Settings & Backup</strong>
            <span>Personal targets, pack sizes, store notes & export backup</span>
          </div>
          <div class="menu-arrow">›</div>
        </button>
"@
    $menuReplacement = @"
        <button class="menu-card" data-tab-btn="sync" style="border-color:var(--color-primary)">
          <div class="menu-icon-wrap">☁️</div>
          <div class="menu-card-info">
            <strong>Live Share & Sync</strong>
            <span id="homeSyncSubtitle">Share planner & stock in real time</span>
          </div>
          <div class="menu-arrow">›</div>
        </button>

        <button class="menu-card" data-tab-btn="settings">
          <div class="menu-icon-wrap">⚙️</div>
          <div class="menu-card-info">
            <strong>Settings & Backup</strong>
            <span>Personal targets, pack sizes, store notes & export backup</span>
          </div>
          <div class="menu-arrow">›</div>
        </button>
"@
    $txt = $txt.Replace($menuTarget, $menuReplacement)
}

# 5. Add Sync section before </main>
if (-not $txt.Contains('data-tab="sync"')) {
    $mainTarget = '    </section>' + "`n" + '  </main>'
    $syncSection = @"
    </section>

    <!-- 8. CLOUD SHARE & LIVE SYNC -->
    <section data-tab="sync" class="hidden stack">
      <div class="panel stack">
        <div class="section-title">
          <div>
            <h2 style="font-size:var(--text-lg)">Live Cloud Sync</h2>
            <p class="muted small">Share your weekly planner, pantry, fridge & freezer in real time with another person.</p>
          </div>
        </div>

        <!-- Connection Status Card -->
        <div class="sync-status-card" id="syncStatusCard">
          <div style="display:flex;align-items:center;justify-content:space-between">
            <span class="sync-badge" id="syncBadge">⚪ Local Mode (Not shared)</span>
            <span class="tiny muted" id="syncLastTime"></span>
          </div>
          <div id="syncActiveDetails" class="hidden" style="margin-top:12px">
            <label class="tiny muted">Your Active Household Code:</label>
            <div style="display:flex;gap:8px;align-items:center;margin-top:4px">
              <span id="syncCurrentCodeDisplay" class="household-code-tag">KETO-XXXX</span>
              <button id="syncCopyCodeBtn" class="act-btn small" type="button">📋 Copy</button>
              <button id="syncShareCodeBtn" class="act-btn primary small" type="button">📤 Share Code</button>
            </div>
            <p class="tiny muted" style="margin-top:8px">🟢 Live 2-way sync is active. Whenever you or your partner modify meals or check off fridge items, both phones update instantly.</p>
            <div style="display:flex;gap:8px;margin-top:12px">
              <button id="syncForcePushBtn" class="act-btn" type="button">🔄 Sync Now</button>
              <button id="syncDisconnectBtn" class="panel small" type="button" style="color:var(--color-danger);padding:6px 12px">Disconnect Household</button>
            </div>
          </div>
        </div>

        <!-- Join or Create Section (Shown when not connected) -->
        <div id="syncSetupContainer" class="stack" style="gap:var(--space-3)">
          <!-- Option A: Create -->
          <div class="panel stack" style="background:var(--color-surface-2);border:1px dashed var(--color-border)">
            <h3>Option 1: Create a Shared Household</h3>
            <p class="muted small">Generate a shareable code to link with your partner or family. Your current meal plan and stock will be uploaded as the shared starting point.</p>
            <div style="display:flex;gap:8px;align-items:center">
              <input id="syncCustomCodeInput" class="search" placeholder="Custom code (optional, e.g. FAMILY)" style="flex:1">
              <button id="syncCreateBtn" class="act-btn primary" type="button">🚀 Create Household</button>
            </div>
          </div>

          <!-- Option B: Join -->
          <div class="panel stack" style="background:var(--color-surface-2);border:1px dashed var(--color-border)">
            <h3>Option 2: Join an Existing Household</h3>
            <p class="muted small">Did your partner or family member already create a Household Code? Enter it below to join and sync with their planner and stock.</p>
            <div style="display:flex;gap:8px;align-items:center">
              <input id="syncJoinCodeInput" class="search" placeholder="Enter code (e.g. KETO-7491)" style="flex:1">
              <button id="syncJoinBtn" class="act-btn primary" type="button">🔗 Join & Sync</button>
            </div>
          </div>
        </div>

        <!-- Firebase Firestore Activation Notice -->
        <details class="more-filters" style="margin-top:8px">
          <summary class="small"><strong>⚙️ Database Setup (One-time, 1 minute)</strong></summary>
          <div class="note small stack" style="gap:6px;margin-top:8px">
            <p>Your app is linked to Firebase Project: <code>com-example-ketoplanner-ce533</code>.</p>
            <p>To enable real-time sync:</p>
            <ol style="margin-left:20px;display:grid;gap:4px">
              <li>Open <a href="https://console.firebase.google.com/project/com-example-ketoplanner-ce533/firestore" target="_blank">Firebase Console: Cloud Firestore</a>.</li>
              <li>Click <strong>"Create database"</strong>.</li>
              <li>Choose <strong>"Start in test mode"</strong> (allows sync) and click <strong>Enable</strong>.</li>
            </ol>
            <p class="tiny muted">Everything else is 100% automated by the app.</p>
          </div>
        </details>
      </div>
    </section>
  </main>
"@
    $txt = $txt.Replace($mainTarget, $syncSection)
}

# 6. Add 'sync' to TAB_TITLES
if (-not $txt.Contains("'sync': 'Live Cloud Sync'")) {
    $titlesTarget = "'settings': 'Settings & Backup'"
    $titlesReplacement = @"
'settings': 'Settings & Backup',
      'sync': 'Live Cloud Sync'
"@
    $txt = $txt.Replace($titlesTarget, $titlesReplacement)
}

# 7. Add Firestore Sync Engine
if (-not $txt.Contains('const FB_CONFIG')) {
    $engineTarget = '    function saveState() {'
    $engineCode = @"
    /* FIREBASE CLOUD SYNC ENGINE */
    const FB_CONFIG = {
      apiKey: "AIzaSyDpDVlG-_NwFtiSuxJt5PhjeK_16-F7yd0",
      authDomain: "com-example-ketoplanner-ce533.firebaseapp.com",
      projectId: "com-example-ketoplanner-ce533",
      storageBucket: "com-example-ketoplanner-ce533.firebasestorage.app",
      messagingSenderId: "298323350581",
      appId: "1:298323350581:android:e547ca36f30a635d370d7c"
    };

    let fbDb = null;
    let fbUnsubscribe = null;
    let syncDeviceId = localStorage.getItem('ketoSync.deviceId');
    if (!syncDeviceId) {
      syncDeviceId = 'dev_' + Math.random().toString(36).substring(2, 10);
      localStorage.setItem('ketoSync.deviceId', syncDeviceId);
    }
    let currentHouseholdCode = localStorage.getItem('ketoSync.householdCode') || null;
    let lastRemoteUpdate = 0;
    let syncPushTimeout = null;

    function initFirebase() {
      try {
        if (typeof firebase !== 'undefined' && !firebase.apps.length) {
          firebase.initializeApp(FB_CONFIG);
          fbDb = firebase.firestore();
        } else if (typeof firebase !== 'undefined' && firebase.apps.length) {
          fbDb = firebase.firestore();
        }
      } catch (err) {
        console.warn('Firebase init:', err);
      }
    }
    initFirebase();

    function updateSyncUI(state, text) {
      const pill = document.getElementById('cloudHeaderBtn');
      const dot = document.getElementById('cloudDot');
      const label = document.getElementById('cloudLabel');
      const badge = document.getElementById('syncBadge');
      const activeDetails = document.getElementById('syncActiveDetails');
      const setupContainer = document.getElementById('syncSetupContainer');
      const codeDisplay = document.getElementById('syncCurrentCodeDisplay');
      const homeSubtitle = document.getElementById('homeSyncSubtitle');

      if (pill) {
        pill.className = 'cloud-pill ' + (state || '');
      }
      if (label) label.textContent = text || (currentHouseholdCode ? currentHouseholdCode : 'Local');

      if (currentHouseholdCode) {
        if (badge) {
          badge.className = 'sync-badge live';
          badge.textContent = '🟢 Live Synced (' + currentHouseholdCode + ')';
        }
        if (activeDetails) activeDetails.classList.remove('hidden');
        if (setupContainer) setupContainer.classList.add('hidden');
        if (codeDisplay) codeDisplay.textContent = currentHouseholdCode;
        if (homeSubtitle) homeSubtitle.textContent = '🟢 Live Synced with: ' + currentHouseholdCode;
      } else {
        if (badge) {
          badge.className = 'sync-badge';
          badge.textContent = '⚪ Local Mode (Not shared)';
        }
        if (activeDetails) activeDetails.classList.add('hidden');
        if (setupContainer) setupContainer.classList.remove('hidden');
        if (homeSubtitle) homeSubtitle.textContent = 'Share planner & stock with partner/family';
      }
    }

    function showSyncToast(msg) {
      let toast = document.getElementById('syncToast');
      if (!toast) {
        toast = document.createElement('div');
        toast.id = 'syncToast';
        toast.className = 'sync-toast';
        document.body.appendChild(toast);
      }
      toast.textContent = msg;
      toast.classList.add('show');
      setTimeout(() => toast.classList.remove('show'), 2500);
    }

    function subscribeToHousehold(code) {
      if (!code) return;
      if (!fbDb) initFirebase();
      if (!fbDb) return;
      if (fbUnsubscribe) { fbUnsubscribe(); fbUnsubscribe = null; }

      updateSyncUI('syncing', 'Syncing...');
      fbUnsubscribe = fbDb.collection('households').doc(code).onSnapshot((doc) => {
        if (!doc.exists) {
          pushToCloud(true);
          updateSyncUI('connected', code);
          return;
        }
        const data = doc.data();
        if (data.updatedBy === syncDeviceId) {
          updateSyncUI('connected', code);
          return;
        }

        if (data.updatedAt && data.updatedAt > lastRemoteUpdate) {
          lastRemoteUpdate = data.updatedAt;

          if (data.custom && typeof data.custom === 'object') {
            DAYS.forEach(d => {
              if (data.custom[d]) {
                SLOTS.forEach(s => {
                  if (typeof data.custom[d][s] === 'string') custom[d][s] = data.custom[d][s];
                });
              }
            });
          }

          if (data.stock && typeof data.stock === 'object') {
            if (Array.isArray(data.stock.pantry)) stock.pantry = data.stock.pantry;
            if (Array.isArray(data.stock.fridge)) stock.fridge = data.stock.fridge;
            if (Array.isArray(data.stock.freezer)) stock.freezer = data.stock.freezer;
          }

          if (Array.isArray(data.customRecipes)) {
            customRecipes = data.customRecipes;
            rebuildMap();
          }

          try {
            localStorage.setItem(LS_KEY, JSON.stringify({
              custom, shopping, customRecipes, settings, stock, packSizes, stores, ticked, meta, customIngredients
            }));
          } catch(e) {}

          renderCustom();
          renderPlannerTotals();
          renderStock();
          rebuildShopping();
          renderSettings();
          updateSyncUI('connected', code);
          showSyncToast('☁️ Live update from partner synced!');
        }
      }, (err) => {
        console.warn('Firestore snapshot error:', err);
        updateSyncUI('error', 'Sync Err');
      });
    }

    function pushToCloud(immediate = false) {
      if (!currentHouseholdCode) return;
      if (!fbDb) initFirebase();
      if (!fbDb) return;
      if (syncPushTimeout) clearTimeout(syncPushTimeout);

      const doPush = () => {
        const payload = {
          updatedAt: Date.now(),
          updatedBy: syncDeviceId,
          custom: custom,
          stock: stock,
          customRecipes: customRecipes,
          settings: settings
        };
        updateSyncUI('syncing', 'Saving...');
        fbDb.collection('households').doc(currentHouseholdCode).set(payload, { merge: true })
          .then(() => {
            updateSyncUI('connected', currentHouseholdCode);
            const timeEl = document.getElementById('syncLastTime');
            if (timeEl) timeEl.textContent = 'Synced ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
          })
          .catch((err) => {
            console.warn('Firestore push error:', err);
            updateSyncUI('error', 'Offline');
          });
      };

      if (immediate) {
        doPush();
      } else {
        syncPushTimeout = setTimeout(doPush, 600);
      }
    }

    function saveState() {
"@
    $txt = $txt.Replace($engineTarget, $engineCode)
}

# 8. Add pushToCloud call in saveState
if (-not $txt.Contains('pushToCloud(false)')) {
    $saveStateTarget = "localStorage.setItem(LS_KEY, JSON.stringify({"
    $saveStateReplace = "pushToCloud(false);`n        localStorage.setItem(LS_KEY, JSON.stringify({"
    $txt = $txt.Replace($saveStateTarget, $saveStateReplace)
}

# 9. Add event listeners for sync buttons and theme toggle sync
if (-not $txt.Contains('syncCreateBtn')) {
    $listenersTarget = "document.getElementById('exportBtn')?.addEventListener('click', exportBackup);"
    $listenersCode = @"
      // Cloud Sync Button Handlers
      document.getElementById('syncCreateBtn')?.addEventListener('click', () => {
        const customCode = (document.getElementById('syncCustomCodeInput')?.value || '').trim().toUpperCase();
        const code = customCode || ('KETO-' + Math.floor(1000 + Math.random() * 9000));
        currentHouseholdCode = code;
        localStorage.setItem('ketoSync.householdCode', code);
        subscribeToHousehold(code);
        pushToCloud(true);
        updateSyncUI('connected', code);
        alert('Created Household: ' + code + '\nShare this code with your partner or family member so they can connect!');
      });

      document.getElementById('syncJoinBtn')?.addEventListener('click', () => {
        const code = (document.getElementById('syncJoinCodeInput')?.value || '').trim().toUpperCase();
        if (!code) { alert('Please enter a Household Code.'); return; }
        currentHouseholdCode = code;
        localStorage.setItem('ketoSync.householdCode', code);
        subscribeToHousehold(code);
        updateSyncUI('connected', code);
        alert('Connected to Household: ' + code + '!\nYour planner and stock are now syncing in real time.');
      });

      document.getElementById('syncCopyCodeBtn')?.addEventListener('click', () => {
        if (!currentHouseholdCode) return;
        if (window.Android && window.Android.copyToClipboard) {
          window.Android.copyToClipboard(currentHouseholdCode);
        } else if (navigator.clipboard) {
          navigator.clipboard.writeText(currentHouseholdCode);
          alert('Copied Household Code: ' + currentHouseholdCode);
        }
      });

      document.getElementById('syncShareCodeBtn')?.addEventListener('click', () => {
        if (!currentHouseholdCode) return;
        const msg = 'Join my Keto Planner household! Our code is: ' + currentHouseholdCode;
        if (window.Android && window.Android.shareOrSave) {
          window.Android.shareOrSave(msg, 'Join Keto Planner Household');
        } else if (navigator.share) {
          navigator.share({ title: 'Keto Planner Household', text: msg });
        } else {
          alert(msg);
        }
      });

      document.getElementById('syncForcePushBtn')?.addEventListener('click', () => {
        pushToCloud(true);
        showSyncToast('☁️ Pushed latest changes to cloud');
      });

      document.getElementById('syncDisconnectBtn')?.addEventListener('click', () => {
        if (confirm('Disconnect from shared household ' + currentHouseholdCode + '? Your app will return to local mode.')) {
          if (fbUnsubscribe) { fbUnsubscribe(); fbUnsubscribe = null; }
          currentHouseholdCode = null;
          localStorage.removeItem('ketoSync.householdCode');
          updateSyncUI('', 'Local');
        }
      });

      document.getElementById('exportBtn')?.addEventListener('click', exportBackup);
"@
    $txt = $txt.Replace($listenersTarget, $listenersCode)
}

# 10. Update theme toggle in build_mobile_app to notify Android
if (-not $txt.Contains('window.Android.setNavTheme')) {
    $themeTarget = "curTheme = curTheme === 'dark' ? 'light' : 'dark';`n        document.documentElement.setAttribute('data-theme', curTheme);"
    $themeReplacement = @"
curTheme = curTheme === 'dark' ? 'light' : 'dark';
        document.documentElement.setAttribute('data-theme', curTheme);
        localStorage.setItem('ketoTheme', curTheme);
        if (window.Android && window.Android.setNavTheme) window.Android.setNavTheme(curTheme === 'dark');
"@
    $txt = $txt.Replace($themeTarget, $themeReplacement)
}

# 11. Initial sync state check
if (-not $txt.Contains('updateSyncUI(')) {
    $initTarget = "switchTab('home');"
    $initReplacement = @"
updateSyncUI();
      if (currentHouseholdCode) subscribeToHousehold(currentHouseholdCode);
      const savedTheme = localStorage.getItem('ketoTheme') || curTheme;
      document.documentElement.setAttribute('data-theme', savedTheme);
      if (window.Android && window.Android.setNavTheme) window.Android.setNavTheme(savedTheme === 'dark');
      switchTab('home');
"@
    $txt = $txt.Replace($initTarget, $initReplacement)
}

# Save with UTF-8 BOM so powershell 5.1 interprets emojis cleanly
$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($ps1Path, $txt, $utf8bom)
Write-Output "Successfully updated build_mobile_app.ps1 with Cloud Sync & UI elements."
