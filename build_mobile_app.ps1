# Full PowerShell generator for Keto Planner Mobile v3
$srcPath = "c:\Users\Casperikz\AndroidStudioProjects\KetoPlanner\app\src\main\assets\index.html"
$content = [System.IO.File]::ReadAllText($srcPath, [System.Text.Encoding]::UTF8)

# 1. Extract RECIPES
$mRecipes = [System.Text.RegularExpressions.Regex]::Match($content, "(const RECIPES\s*=\s*\[[\s\S]*?\];)\s*const DAYS")
if (-not $mRecipes.Success) { throw "Failed to extract RECIPES block" }
$recipesBlock = $mRecipes.Groups[1].Value

# 2. Extract N, COUNT, NX
$mN = [System.Text.RegularExpressions.Regex]::Match($content, "(const N\s*=\s*\{[\s\S]*?\};\s*const COUNT\s*=\s*\{[\s\S]*?\};\s*const NX\s*=\s*\{[\s\S]*?\};)")
if (-not $mN.Success) { throw "Failed to extract N, COUNT, NX databases" }
$nutritionBlock = $mN.Groups[1].Value

# 3. Extract CUP_DENSITY and LIQUID_INGS & convertToGrams
$mCups = [System.Text.RegularExpressions.Regex]::Match($content, "(const CUP_DENSITY\s*=\s*\{[\s\S]*?\};[\s\S]*?const LIQUID_INGS\s*=\s*new Set\([\s\S]*?\);[\s\S]*?function convertToGrams[\s\S]*?return \{ grams: cups \* perCup, isLiquid: LIQUID_INGS\.has\(ingredientKey\) \};\s*\})")
if (-not $mCups.Success) { throw "Failed to extract CUP_DENSITY block" }
$cupsBlock = $mCups.Groups[1].Value

$html = @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
  <title>Keto Planner</title>
  <meta name="theme-color" content="#01696f">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="Keto Planner">
  <link rel="manifest" href="manifest.json">
  <link rel="apple-touch-icon" href="icon.png">
  <link rel="icon" href="icon.png" type="image/png">
    <link href="https://api.fontshare.com/v2/css?f[]=satoshi@400,500,700&display=swap" rel="stylesheet">
  <script src="firebase-app.js"></script>
  <script src="firebase-firestore.js"></script>
  <style>
    :root, [data-theme="light"] {
      --text-xs: .75rem;
      --text-sm: .875rem;
      --text-base: 1rem;
      --text-lg: 1.25rem;
      --text-xl: 1.6rem;
      --space-1: .25rem;
      --space-2: .5rem;
      --space-3: .75rem;
      --space-4: 1rem;
      --space-5: 1.25rem;
      --space-6: 1.5rem;
      --radius-sm: .375rem;
      --radius-md: .625rem;
      --radius-lg: .875rem;
      --radius-xl: 1.125rem;
      --color-bg: #f5f4ef;
      --color-surface: #ffffff;
      --color-surface-2: #faf9f6;
      --color-surface-offset: #eeece6;
      --color-border: #dcd7cc;
      --color-divider: #e4dfd5;
      --color-text: #22201b;
      --color-text-muted: #6b675e;
      --color-text-faint: #9c978d;
      --color-primary: #01696f;
      --color-primary-hover: #0a4f54;
      --color-primary-highlight: #e0eeeb;
      --color-success: #2e7d32;
      --color-warning: #e65100;
      --color-danger: #c62828;
      --shadow-sm: 0 1px 3px rgba(0,0,0,0.06);
      --shadow-md: 0 4px 14px rgba(0,0,0,0.08);
      --font-body: 'Satoshi', system-ui, -apple-system, sans-serif;
    }

    [data-theme="dark"] {
      --color-bg: #141412;
      --color-surface: #1d1c19;
      --color-surface-2: #242320;
      --color-surface-offset: #2b2926;
      --color-border: #3b3934;
      --color-divider: #2e2c28;
      --color-text: #eae8e3;
      --color-text-muted: #aba79d;
      --color-text-faint: #7a766e;
      --color-primary: #38a3a5;
      --color-primary-hover: #57cc99;
      --color-primary-highlight: #223838;
      --shadow-sm: 0 1px 3px rgba(0,0,0,0.3);
      --shadow-md: 0 4px 14px rgba(0,0,0,0.4);
    }

    * { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
    html { -webkit-text-size-adjust: 100%; text-size-adjust: 100%; }
    body {
      min-height: 100dvh;
      line-height: 1.45;
      font-family: var(--font-body);
      font-size: var(--text-base);
      color: var(--color-text);
      background: var(--color-bg);
      overflow-x: hidden;
      padding-bottom: calc(72px + env(safe-area-inset-bottom, 12px));
    }

    button, input, select, textarea { font: inherit; color: inherit; }
    button { cursor: pointer; border: none; background: none; }
    a { color: var(--color-primary); text-decoration: none; }

    /* App Header */
    .app-header {
      position: sticky;
      top: 0;
      z-index: 100;
      height: 56px;
      background: var(--color-surface);
      border-bottom: 1px solid var(--color-border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 var(--space-4);
      box-shadow: var(--shadow-sm);
    }
    .header-left { display: flex; align-items: center; gap: var(--space-2); min-width: 0; }
    .header-brand { display: flex; align-items: center; gap: var(--space-2); }
    .brand-icon { width: 30px; height: 30px; border-radius: 8px; object-fit: cover; }
    .header-brand strong { font-size: var(--text-base); font-weight: 700; color: var(--color-primary); }
    .back-btn {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      font-size: var(--text-sm);
      font-weight: 600;
      color: var(--color-primary);
      padding: 6px 8px;
      border-radius: var(--radius-md);
      background: var(--color-primary-highlight);
    }
    .header-title { font-size: var(--text-base); font-weight: 700; text-align: center; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .header-right { display: flex; align-items: center; gap: var(--space-2); }
    .theme-btn {
      width: 38px;
      height: 38px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.1rem;
      background: var(--color-surface-2);
      border: 1px solid var(--color-border);
    }

    /* Bottom Navigation Bar */
    .bottom-nav {
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      z-index: 100;
      height: 60px;
      background: var(--color-surface);
      border-top: 1px solid var(--color-border);
      display: grid;
      grid-template-columns: repeat(5, 1fr);
      padding-bottom: env(safe-area-inset-bottom, 0px);
      box-shadow: 0 -2px 10px rgba(0,0,0,0.05);
    }
    .nav-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 2px;
      color: var(--color-text-muted);
      font-size: 10px;
      font-weight: 600;
      transition: color 150ms ease;
    }
    .nav-item .nav-icon { font-size: 18px; line-height: 1; }
    .nav-item.active { color: var(--color-primary); }
    .nav-item.active .nav-icon { transform: scale(1.1); }

    /* Layout Containers */
    .main-content {
      padding: var(--space-4);
      max-width: 800px;
      margin: 0 auto;
      width: 100%;
    }
    .panel {
      background: var(--color-surface);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-xl);
      box-shadow: var(--shadow-sm);
      padding: var(--space-4);
    }
    .stack { display: grid; gap: var(--space-4); }
    .hidden { display: none !important; }

    /* Home / Main Menu */
    .home-banner {
      background: linear-gradient(135deg, color-mix(in oklab, var(--color-primary) 12%, var(--color-surface)), var(--color-surface));
      border: 1px solid color-mix(in oklab, var(--color-primary) 30%, var(--color-border));
      position: relative;
      overflow: hidden;
    }
    .home-badge {
      display: inline-block;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: .05em;
      color: var(--color-primary);
      background: var(--color-primary-highlight);
      padding: 3px 8px;
      border-radius: 999px;
      margin-bottom: var(--space-2);
    }
    .home-banner h2 { font-size: var(--text-xl); line-height: 1.2; margin-bottom: 4px; }
    .home-target-card {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: var(--space-2);
      margin-top: var(--space-3);
      padding-top: var(--space-3);
      border-top: 1px solid var(--color-divider);
    }
    .target-item { text-align: center; }
    .target-item .t-lbl { font-size: 11px; color: var(--color-text-muted); display: block; }
    .target-item .t-val { font-size: var(--text-sm); font-weight: 700; color: var(--color-primary); }

    .menu-grid { display: grid; gap: var(--space-3); }
    .menu-card {
      display: flex;
      align-items: center;
      gap: var(--space-3);
      padding: var(--space-4);
      background: var(--color-surface);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-xl);
      box-shadow: var(--shadow-sm);
      text-align: left;
      transition: transform 120ms ease, border-color 120ms ease;
    }
    .menu-card:active { transform: scale(0.98); border-color: var(--color-primary); }
    .menu-icon-wrap {
      width: 48px;
      height: 48px;
      border-radius: var(--radius-lg);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      flex-shrink: 0;
      background: var(--color-primary-highlight);
    }
    .menu-card-info { flex: 1; min-width: 0; }
    .menu-card-info strong { display: block; font-size: var(--text-base); font-weight: 700; color: var(--color-text); margin-bottom: 2px; }
    .menu-card-info span { display: block; font-size: var(--text-xs); color: var(--color-text-muted); line-height: 1.3; }
    .menu-arrow { font-size: 20px; color: var(--color-text-faint); font-weight: 300; }

    /* Buttons & Inputs */
    .act-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: .4rem;
      padding: .6rem 1rem;
      border: 1px solid var(--color-primary);
      border-radius: var(--radius-md);
      background: var(--color-primary-highlight);
      color: var(--color-text);
      font-size: var(--text-sm);
      font-weight: 600;
    }
    .act-btn:active { background: color-mix(in oklab, var(--color-primary-highlight) 60%, var(--color-primary)); }
    .act-btn.primary { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
    .x-btn {
      width: 28px;
      height: 28px;
      border-radius: var(--radius-sm);
      background: var(--color-surface-offset);
      border: 1px solid var(--color-border);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      color: var(--color-text-muted);
      font-size: 14px;
      flex-shrink: 0;
    }
    .x-btn:active { background: var(--color-danger); color: #fff; }
    .search, .slot-select {
      width: 100%;
      min-width: 0;
      padding: .6rem .75rem;
      border: 1px solid var(--color-border);
      border-radius: var(--radius-md);
      background: var(--color-surface-2);
      font-size: var(--text-sm);
    }

    /* KPIs */
    .kpis {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: var(--space-2);
    }
    @media (min-width: 600px) { .kpis { grid-template-columns: repeat(4, 1fr); } }
    .kpi {
      padding: var(--space-3);
      border-radius: var(--radius-lg);
      background: var(--color-surface-2);
      border: 1px solid var(--color-border);
    }
    .kpi .label { font-size: 11px; color: var(--color-text-muted); margin-bottom: 2px; }
    .kpi .value { font-size: var(--text-base); font-weight: 700; }
    .good { color: var(--color-success); font-weight: 700; }
    .warn { color: var(--color-warning); font-weight: 700; }
    .bad { color: var(--color-danger); font-weight: 700; }

    /* Day Selector Pills for Planner */
    .day-pills-bar {
      display: flex;
      gap: 6px;
      overflow-x: auto;
      padding-bottom: 6px;
      scrollbar-width: none;
      -webkit-overflow-scrolling: touch;
    }
    .day-pills-bar::-webkit-scrollbar { display: none; }
    .day-pill {
      flex: 0 0 auto;
      padding: 6px 12px;
      border-radius: 999px;
      font-size: var(--text-xs);
      font-weight: 600;
      background: var(--color-surface-2);
      border: 1px solid var(--color-border);
      color: var(--color-text-muted);
    }
    .day-pill.active {
      background: var(--color-primary);
      border-color: var(--color-primary);
      color: #fff;
    }

    /* Planner Meals */
    .day-card {
      background: var(--color-surface);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-xl);
      padding: var(--space-4);
      display: grid;
      gap: var(--space-3);
      box-shadow: var(--shadow-sm);
    }
    .day-card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid var(--color-divider);
      padding-bottom: var(--space-2);
    }
    .day-card-header h3 { font-size: var(--text-lg); font-weight: 700; }
    .copy-day {
      font-size: var(--text-xs);
      padding: 4px 8px;
      border-radius: var(--radius-sm);
      border: 1px solid var(--color-border);
      background: var(--color-surface-2);
    }
    .meal-slot-row {
      background: var(--color-surface-2);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-lg);
      padding: var(--space-2) var(--space-3);
    }
    .slot-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 4px;
    }
    .slot-badge {
      font-size: 11px;
      font-weight: 700;
      letter-spacing: .04em;
      color: var(--color-primary);
      text-transform: uppercase;
    }
    .slot-control { display: flex; gap: 8px; align-items: center; width: 100%; }
    .slot-thumb { width: 38px; height: 38px; border-radius: var(--radius-md); object-fit: cover; flex-shrink: 0; background: var(--color-surface-offset); }
    .slot-control select { flex: 1; min-width: 0; }
    .day-totals-box {
      background: var(--color-surface-offset);
      border-radius: var(--radius-lg);
      padding: var(--space-3);
      font-size: var(--text-sm);
    }

    /* Stock Manager */
    .stock-subnav {
      display: flex;
      gap: 6px;
      border-bottom: 1px solid var(--color-border);
      padding-bottom: var(--space-2);
    }
    .stock-tab-btn {
      flex: 1;
      text-align: center;
      padding: 8px 4px;
      font-size: var(--text-sm);
      font-weight: 600;
      border-radius: var(--radius-md);
      color: var(--color-text-muted);
      background: var(--color-surface-2);
      border: 1px solid var(--color-border);
    }
    .stock-tab-btn.active {
      background: var(--color-primary);
      border-color: var(--color-primary);
      color: #fff;
    }
    .stock-filters-row { display: flex; gap: 6px; flex-wrap: wrap; align-items: center; }
    .stock-filter-chip {
      padding: 4px 10px;
      border-radius: 999px;
      font-size: 11px;
      font-weight: 600;
      background: var(--color-surface-2);
      border: 1px solid var(--color-border);
      color: var(--color-text-muted);
    }
    .stock-filter-chip.active { background: var(--color-primary-highlight); color: var(--color-primary); border-color: var(--color-primary); }
    .stock-add-bar { display: flex; gap: 6px; }
    .stock-add-bar input { flex: 1; }
    .stock-items-list { display: grid; gap: 6px; }
    .stock-item-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
      padding: 10px 12px;
      border-radius: var(--radius-lg);
      background: var(--color-surface-2);
      border: 1px solid var(--color-border);
    }
    .stock-item-row.is-stocked { border-left: 4px solid var(--color-success); }
    .stock-item-row.is-missing { border-left: 4px solid var(--color-warning); opacity: 0.85; }
    .stock-check-label {
      display: flex;
      align-items: center;
      gap: 10px;
      flex: 1;
      min-width: 0;
      cursor: pointer;
    }
    .stock-check-input {
      width: 20px;
      height: 20px;
      accent-color: var(--color-primary);
      flex-shrink: 0;
    }
    .stock-item-name { font-size: var(--text-sm); font-weight: 500; word-break: break-word; }
    .stock-item-actions { display: flex; align-items: center; gap: 6px; flex-shrink: 0; }
    .stock-badge {
      font-size: 10px;
      font-weight: 700;
      padding: 2px 6px;
      border-radius: 999px;
      text-transform: uppercase;
    }
    .badge-have { background: color-mix(in oklab, var(--color-success) 15%, transparent); color: var(--color-success); }
    .badge-need { background: color-mix(in oklab, var(--color-warning) 15%, transparent); color: var(--color-warning); }

    /* Macronutrients Mobile Cards */
    .macro-sort-chips { display: flex; gap: 6px; overflow-x: auto; padding-bottom: 4px; scrollbar-width: none; }
    .macro-sort-chips::-webkit-scrollbar { display: none; }
    .chip-btn {
      flex: 0 0 auto;
      padding: 4px 10px;
      font-size: 11px;
      font-weight: 600;
      border-radius: 999px;
      background: var(--color-surface-2);
      border: 1px solid var(--color-border);
      color: var(--color-text-muted);
    }
    .chip-btn.active { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
    .macro-cards-wrap { display: grid; gap: 6px; }
    .macro-card {
      background: var(--color-surface-2);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-lg);
      padding: 10px 12px;
    }
    .macro-card-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
    .macro-card-top strong { font-size: var(--text-sm); }
    .macro-basis { font-size: 11px; color: var(--color-text-muted); margin-left: 4px; }
    .macro-chips-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 4px; text-align: center; }
    .macro-stat-pill {
      padding: 3px 2px;
      border-radius: var(--radius-sm);
      background: var(--color-surface);
      border: 1px solid var(--color-divider);
      font-size: 11px;
    }
    .macro-stat-pill span { display: block; font-size: 9px; color: var(--color-text-muted); text-transform: uppercase; }

    /* Recipes Library */
    .recipes-sort-bar {
      display: flex;
      align-items: center;
      gap: var(--space-2);
      background: var(--color-surface-2);
      padding: var(--space-2) var(--space-3);
      border-radius: var(--radius-md);
      border: 1px solid var(--color-border);
    }
    .recipes-sort-bar select { flex: 1; }
    .recipe-btn {
      display: flex;
      gap: var(--space-3);
      align-items: center;
      text-align: left;
      padding: var(--space-3);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-lg);
      background: var(--color-surface-2);
      width: 100%;
    }
    .recipe-btn.active { border-color: var(--color-primary); background: var(--color-primary-highlight); }
    .recipe-thumb { width: 56px; height: 56px; border-radius: var(--radius-md); object-fit: cover; flex-shrink: 0; background: var(--color-surface-offset); }
    .recipe-meta { min-width: 0; flex: 1; }
    .tag-chip {
      display: inline-block;
      padding: 2px 6px;
      border-radius: 999px;
      font-size: 10px;
      background: var(--color-surface-offset);
      border: 1px solid var(--color-border);
      margin: 1px;
    }
    .tag-chip.sel { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }

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
    .convert-stack { display: grid; gap: var(--space-3); }

    /* Settings Page */
    .settings-grid { display: grid; grid-template-columns: 1fr; gap: var(--space-3); }
    @media (min-width: 600px) { .settings-grid { grid-template-columns: 1fr 1fr; } }
    .pack-row, .store-row { display: grid; grid-template-columns: 1fr 80px 80px 28px; gap: 6px; align-items: center; margin-bottom: 6px; }
    .store-row { grid-template-columns: 1fr 1fr 28px; }

    .note { padding: var(--space-3); border-radius: var(--radius-lg); background: var(--color-surface-offset); font-size: var(--text-sm); }
    .tiny { font-size: var(--text-xs); }
    .small { font-size: var(--text-sm); }
    .muted { color: var(--color-text-muted); }
    .section-title { display: flex; justify-content: space-between; align-items: flex-start; gap: var(--space-2); margin-bottom: var(--space-2); }
    .filters { display: flex; gap: var(--space-2); flex-wrap: wrap; }
    .shop-list { list-style: none; display: grid; gap: 6px; }
    .shop-list li { display: flex; justify-content: space-between; align-items: center; gap: 8px; font-size: var(--text-sm); }
    .shop-cat { font-weight: 700; font-size: 11px; text-transform: uppercase; color: var(--color-text-muted); margin-top: 8px; }
  </style>
</head>
<body>
  <!-- Fixed App Header -->
  <header class="app-header">
    <div class="header-left">
      <button id="appBackBtn" class="back-btn hidden" aria-label="Back to menu">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M12 19l-7-7 7-7"/></svg>
        <span>Menu</span>
      </button>
      <div id="headerBrand" class="header-brand">
        <img src="icon.png" class="brand-icon" alt="">
        <strong>Keto Planner</strong>
      </div>
    </div>
    <div id="appHeaderTitle" class="header-title hidden"></div>
    <div class="header-right">
      <button data-theme-toggle class="theme-btn" aria-label="Toggle theme">◐</button>
    </div>
  </header>

  <main class="main-content">
    <!-- 1. HOME / MAIN MENU -->
    <section data-tab="home" class="stack">
      <div class="home-banner panel">
        <span class="home-badge">🥑 KETO MEAL PLANNER</span>
        <h2>Your Low-Carb Hub</h2>
        <p class="muted small">High-protein keto weekly planner, stock manager, macro guide & recipe builder.</p>
        <div class="home-target-card">
          <div class="target-item">
            <span class="t-lbl">Daily Target</span>
            <strong class="t-val" id="homeTargetKcal">2,000 kcal</strong>
          </div>
          <div class="target-item">
            <span class="t-lbl">Protein Target</span>
            <strong class="t-val" id="homeTargetProt">150 g</strong>
          </div>
          <div class="target-item">
            <span class="t-lbl">Net Carbs Cap</span>
            <strong class="t-val" id="homeTargetCarbs">≤ 50 g</strong>
          </div>
        </div>
      </div>

      <div class="menu-grid">
        <button class="menu-card" data-tab-btn="planner">
          <div class="menu-icon-wrap">📅</div>
          <div class="menu-card-info">
            <strong>Weekly Planner</strong>
            <span>7-day dropdown planner with live macro calculations</span>
          </div>
          <div class="menu-arrow">›</div>
        </button>

        <button class="menu-card" data-tab-btn="recipes">
          <div class="menu-icon-wrap">🍳</div>
          <div class="menu-card-info">
            <strong>Recipe Library</strong>
            <span>60+ keto meals, protein-first sorting, tags & ratings</span>
          </div>
          <div class="menu-arrow">›</div>
        </button>

        <button class="menu-card" data-tab-btn="stock">
          <div class="menu-icon-wrap">📦</div>
          <div class="menu-card-info">
            <strong>Stock Manager</strong>
            <span>Pantry, Fridge & Freezer inventory with on-hand checkmarks</span>
          </div>
          <div class="menu-arrow">›</div>
        </button>

        <button class="menu-card" data-tab-btn="builder">
          <div class="menu-icon-wrap">🧪</div>
          <div class="menu-card-info">
            <strong>Recipe Builder</strong>
            <span>Formulate custom meals with automatic nutrition tracking</span>
          </div>
          <div class="menu-arrow">›</div>
        </button>

        <button class="menu-card" data-tab-btn="macros">
          <div class="menu-icon-wrap">🥑</div>
          <div class="menu-card-info">
            <strong>Macronutrients</strong>
            <span>Search 100+ keto ingredients for protein, fat & carbs</span>
          </div>
          <div class="menu-arrow">›</div>
        </button>

        <button class="menu-card" data-tab-btn="convert">
          <div class="menu-icon-wrap">⚖️</div>
          <div class="menu-card-info">
            <strong>Unit Converter</strong>
            <span>Convert cups, spoons & ounces to grams instantly</span>
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
      </div>
    </section>

    <!-- 2. WEEKLY PLANNER -->
    <section data-tab="planner" class="hidden stack">
      <div class="panel stack">
        <div class="section-title">
          <div>
            <h2 style="font-size:var(--text-lg)">Weekly Planner</h2>
            <p class="muted small">Select meals per day. Total macros adjust automatically.</p>
          </div>
          <button id="clearAllPlannerBtn" class="act-btn" type="button">Clear all</button>
        </div>

        <div class="kpis" id="customKpis"></div>

        <!-- Day Selector Pills -->
        <div class="day-pills-bar" id="plannerDayPills"></div>

        <!-- Days Render Container -->
        <div id="customDays" class="stack"></div>

        <!-- Shopping range -->
        <div class="note small" style="display:flex;flex-direction:column;gap:.5rem">
          <strong>Generate Shopping List</strong>
          <div style="display:flex;gap:.5rem;align-items:center;flex-wrap:wrap">
            <span>From</span>
            <select id="shopFrom" class="slot-select" style="width:auto"></select>
            <span>to</span>
            <select id="shopTo" class="slot-select" style="width:auto"></select>
            <label>× <input id="shopServings" type="number" min="1" value="1" style="width:3.2rem;padding:.3rem;border-radius:4px;border:1px solid var(--color-border);background:var(--color-surface-2)"> serv</label>
            <button id="shopDaysBtn" class="act-btn" type="button">Add to shopping list</button>
          </div>
          <span id="shopDaysMsg" class="tiny good"></span>
        </div>

        <!-- Shopping List Output -->
        <div class="panel stack" style="margin-top:var(--space-2)">
          <div class="section-title">
            <h3>Shopping List</h3>
            <div style="display:flex;gap:.4rem">
              <button id="copyShoppingBtn" class="act-btn" type="button">Copy</button>
              <button id="clearShoppingBtn" class="act-btn" type="button">Clear</button>
            </div>
          </div>
          <div id="shoppingList"></div>
          <textarea id="shoppingText" readonly class="search" rows="4" style="font-size:12px;font-family:monospace"></textarea>
        </div>

        <!-- Prep Sheet -->
        <div class="note small" style="display:flex;flex-direction:column;gap:.5rem">
          <strong>Prep-day Cook Sheet</strong>
          <div style="display:flex;gap:.5rem;align-items:center;flex-wrap:wrap">
            <select id="prepFrom" class="slot-select" style="width:auto"></select>
            <span>to</span>
            <select id="prepTo" class="slot-select" style="width:auto"></select>
            <label>× <input id="prepServings" type="number" min="1" value="1" style="width:3.2rem;padding:.3rem;border-radius:4px;border:1px solid var(--color-border);background:var(--color-surface-2)"> serv</label>
            <button id="prepBtn" class="act-btn" type="button">Make cook sheet</button>
            <button id="prepCopyBtn" class="act-btn" type="button">Copy</button>
          </div>
          <div id="prepSheet" style="margin-top:8px"></div>
        </div>
      </div>
    </section>

    <!-- 3. RECIPES LIBRARY -->
    <section data-tab="recipes" class="hidden stack">
      <div class="panel stack">
        <div class="section-title">
          <div>
            <h2 style="font-size:var(--text-lg)">Recipe Library (<span id="recipeCount">0</span>)</h2>
            <p class="muted small">High-protein keto meal library.</p>
          </div>
        </div>

        <!-- SortingDropdown ONLY for Recipes -->
        <div class="recipes-sort-bar">
          <label class="small" for="sortRule"><strong>Sort recipes:</strong></label>
          <select id="sortRule" class="slot-select">
            <option value="protein">🥩 Protein first</option>
            <option value="calories">🔥 Closest to 500-600 kcal</option>
            <option value="batch">🧊 Best for batch/freezer</option>
            <option value="rating">⭐ Highest rated</option>
            <option value="time">⏱ Quickest first</option>
          </select>
        </div>

        <!-- Filters -->
        <div class="stack" style="gap:var(--space-2)">
          <input id="recipeSearch" class="search" type="search" placeholder="Search recipe or ingredient...">
          <div class="filters">
            <label class="small"><input type="checkbox" id="filterBreakfast" checked> Breakfast</label>
            <label class="small"><input type="checkbox" id="filterMain" checked> Main Course</label>
            <label class="small"><input type="checkbox" id="filterSnack" checked> Snack/Dessert</label>
          </div>

          <details class="more-filters">
            <summary class="small"><strong>Advanced nutrient & tag filters</strong></summary>
            <div class="filter-body" style="padding-top:8px">
              <label class="small">Min protein: <span id="fProteinV">0 g</span>
                <input id="fProtein" type="range" min="0" max="60" value="0" step="5">
              </label>
              <label class="small">Max net carbs: <span id="fCarbsV">30 g</span>
                <input id="fCarbs" type="range" min="0" max="30" value="30" step="2">
              </label>
              <input id="fInclude" class="search" placeholder="Must include ingredient...">
              <input id="fExclude" class="search" placeholder="Exclude ingredient...">
              <div id="tagFilters" class="tag-filter-row"></div>
              <button id="fClear" class="act-btn" type="button" style="margin-top:6px">Reset filters</button>
            </div>
          </details>
        </div>

        <!-- Recipe Detail Modal / View (if selected) -->
        <div id="recipeDetailContainer" class="panel hidden" style="border:2px solid var(--color-primary)">
          <button id="closeRecipeDetailBtn" class="act-btn" type="button" style="margin-bottom:8px">← Back to list</button>
          <div id="recipeDetail"></div>
        </div>

        <!-- Recipes List -->
        <div id="recipeList" class="stack"></div>
      </div>
    </section>

    <!-- 4. STOCK (PANTRY, FRIDGE, FREEZER) -->
    <section data-tab="stock" class="hidden stack">
      <div class="panel stack">
        <div class="section-title">
          <div>
            <h2 style="font-size:var(--text-lg)">Stock Manager</h2>
            <p class="muted small">Check items you physically have on hand.</p>
          </div>
        </div>

        <!-- Sub-menu Category Tabs -->
        <div class="stock-subnav">
          <button class="stock-tab-btn active" data-stock-tab="pantry">🥫 Pantry (<span id="stockCountPantry">0</span>)</button>
          <button class="stock-tab-btn" data-stock-tab="fridge">🧊 Fridge (<span id="stockCountFridge">0</span>)</button>
          <button class="stock-tab-btn" data-stock-tab="freezer">❄️ Freezer (<span id="stockCountFreezer">0</span>)</button>
        </div>

        <!-- Stock Filter & Search -->
        <div class="stock-filters-row">
          <input id="stockSearch" class="search" placeholder="Search stock items..." style="flex:1">
          <button class="stock-filter-chip active" data-stock-filter="all">All</button>
          <button class="stock-filter-chip" data-stock-filter="have">✓ In Stock</button>
          <button class="stock-filter-chip" data-stock-filter="need">✕ Need</button>
        </div>

        <!-- Add Item Row -->
        <div class="stock-add-bar">
          <input id="stockAddInput" class="search" placeholder="Add item (e.g. Eggs, Butter)...">
          <button id="stockAddBtn" class="act-btn primary" type="button">+ Add</button>
        </div>

        <!-- Items List -->
        <div id="stockList" class="stock-items-list"></div>

        <!-- Stock Quick Actions -->
        <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:8px">
          <button id="stockMissingToShopBtn" class="act-btn" type="button">🛒 Add missing items to Shopping List</button>
          <button id="stockResetBtn" class="panel small" type="button" style="padding:6px 10px">Restore defaults</button>
        </div>
      </div>
    </section>

    <!-- 5. RECIPE BUILDER -->
    <section data-tab="builder" class="hidden stack">
      <div class="panel stack">
        <div class="section-title">
          <div>
            <h2 style="font-size:var(--text-lg)">Recipe Builder</h2>
            <p class="muted small">Formulate meals and calculate macros per serving.</p>
          </div>
        </div>

        <div class="stack" style="gap:var(--space-2)">
          <input id="builderName" class="search" placeholder="Recipe name">
          <div style="display:flex;gap:6px">
            <select id="builderMeal" class="slot-select" style="flex:1">
              <option value="Breakfast">Breakfast</option>
              <option value="Lunch/Dinner" selected>Lunch/Dinner</option>
              <option value="Snack">Snack</option>
            </select>
            <label class="small" style="display:flex;align-items:center;gap:4px">
              Servings: <input id="builderServings" class="search" type="number" min="1" value="1" style="width:50px;padding:6px">
            </label>
          </div>
        </div>

        <div id="builderRows" class="stack" style="gap:6px"></div>
        <button id="builderAddRow" class="act-btn" type="button">+ Add ingredient row</button>

        <div class="note" id="builderPreview"></div>

        <div style="display:flex;gap:6px">
          <button id="builderSave" class="act-btn primary" type="button">Save Recipe</button>
          <span id="builderMsg" class="tiny good"></span>
        </div>

        <details class="more-filters">
          <summary class="small"><strong>Bulk import text</strong></summary>
          <div style="margin-top:8px">
            <textarea id="importText" class="search" rows="4" placeholder="Paste lines like: 2 eggs, 150g cottage cheese..."></textarea>
            <button id="importParseBtn" class="act-btn" type="button" style="margin-top:6px">Parse into builder</button>
            <span id="importMsg" class="tiny"></span>
          </div>
        </details>

        <div class="panel stack" style="margin-top:8px">
          <h3>Your Custom Recipes</h3>
          <div id="builderSaved"></div>
        </div>
      </div>
    </section>

    <!-- 6. MACRONUTRIENTS (MOBILE CARDS) -->
    <section data-tab="macros" class="hidden stack">
      <div class="panel stack">
        <div class="section-title">
          <div>
            <h2 style="font-size:var(--text-lg)">Macronutrients Database</h2>
            <p class="muted small">Values per 100 g or unit. Search & sort easily.</p>
          </div>
        </div>

        <input id="macroSearch" class="search" type="search" placeholder="Search ingredient (e.g. chicken, egg, cheddar)...">

        <!-- Sort Chips -->
        <div class="macro-sort-chips">
          <button class="chip-btn active" data-msort="name">Name A-Z</button>
          <button class="chip-btn" data-msort="p">🥩 Protein</button>
          <button class="chip-btn" data-msort="k">🔥 Calories</button>
          <button class="chip-btn" data-msort="f">🧈 Fat</button>
          <button class="chip-btn" data-msort="c">🥗 Net Carbs</button>
        </div>

        <!-- Mobile Macro Cards Container -->
        <div id="macroCardsContainer" class="macro-cards-wrap"></div>

        <!-- Add Custom Ingredient Form -->
        <details class="more-filters" style="margin-top:12px">
          <summary class="small"><strong>+ Add custom ingredient</strong></summary>
          <div class="stack" style="gap:6px;margin-top:8px">
            <input id="ingName" class="search" placeholder="Name (e.g. my protein bread)">
            <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:4px">
              <input id="ingKcal" class="search" type="number" placeholder="kcal">
              <input id="ingProt" class="search" type="number" placeholder="P (g)">
              <input id="ingFat" class="search" type="number" placeholder="F (g)">
              <input id="ingCarbs" class="search" type="number" placeholder="NC (g)">
            </div>
            <button id="ingAddBtn" class="act-btn" type="button">Save ingredient</button>
            <span id="ingMsg" class="tiny"></span>
          </div>
        </details>
      </div>
    </section>

    <!-- 7. UNIT CONVERTER -->
    <section data-tab="convert" class="hidden stack">
      <div class="panel stack">
        <div class="section-title">
          <div>
            <h2 style="font-size:var(--text-lg)">Unit Converter</h2>
            <p class="muted small">Ingredient-aware cup / spoon to gram converter.</p>
          </div>
        </div>

        <div class="convert-stack">
          <label class="small">Ingredient
            <select id="convIngredient" class="slot-select" style="margin-top:4px"></select>
          </label>
          <div style="display:flex;gap:8px">
            <label class="small" style="flex:1">Amount
              <input id="convAmount" class="search" type="number" min="0" step="0.125" value="1" style="margin-top:4px">
            </label>
            <label class="small" style="flex:1">Unit
              <select id="convUnit" class="slot-select" style="margin-top:4px">
                <option value="cup">cup</option>
                <option value="tbsp">tablespoon (tbsp)</option>
                <option value="tsp">teaspoon (tsp)</option>
                <option value="flOz">fluid ounce</option>
                <option value="oz">ounce (weight)</option>
                <option value="lb">pound (weight)</option>
              </select>
            </label>
          </div>
        </div>

        <div class="note" id="convResult" style="font-size:var(--text-lg);font-weight:700;text-align:center"></div>
        <p class="tiny muted" id="convNote" style="text-align:center"></p>

        <details class="more-filters">
          <summary class="small">Density table (grams per cup)</summary>
          <div id="convDensityList" class="stack" style="gap:4px;margin-top:8px;font-size:var(--text-xs)"></div>
        </details>
      </div>
    </section>

    <!-- 8. SETTINGS & BACKUP -->
    <section data-tab="settings" class="hidden stack">
      <div class="panel stack">
        <div class="section-title">
          <div>
            <h2 style="font-size:var(--text-lg)">Personal Targets</h2>
            <p class="muted small">Your target protein and daily calories.</p>
          </div>
        </div>
        <div class="settings-grid">
          <label class="small">Body weight (kg)
            <input id="setWeight" type="number" min="0" step="1" class="search">
          </label>
          <label class="small">Protein per kg
            <input id="setPerKg" type="number" min="0" step="0.1" class="search">
          </label>
          <label class="small">Daily calories (kcal)
            <input id="setKcal" type="number" min="0" step="50" class="search">
          </label>
          <label class="small">Net-carb cap (g)
            <input id="setCarbs" type="number" min="0" step="5" class="search">
          </label>
        </div>
        <div class="note small" id="setProteinOut"></div>
      </div>

      <div class="panel stack">
        <h3>Pack Sizes</h3>
        <p class="muted tiny">Shopping list rounds up to whole pack sizes.</p>
        <div id="packRows" class="stack"></div>
        <button id="packAddBtn" class="act-btn" type="button">+ Add pack size</button>
      </div>

      <div class="panel stack">
        <h3>Store / Brand Notes</h3>
        <p class="muted tiny">Notes shown next to items on shopping list.</p>
        <div id="storeRows" class="stack"></div>
        <button id="storeAddBtn" class="act-btn" type="button">+ Add store note</button>
      </div>

      <div class="panel stack">
        <h3>Backup & Export</h3>
        <p class="muted small">Export your planner and stock data to save or transfer.</p>
        <div style="display:flex;gap:6px;flex-wrap:wrap">
          <button id="exportBtn" class="act-btn primary" type="button">Export backup (JSON)</button>
          <label class="act-btn" style="cursor:pointer">Import backup
            <input id="importFile" type="file" accept="application/json,.json" style="display:none">
          </label>
          <button id="printBtn" class="act-btn" type="button">Print / PDF</button>
        </div>
        <span id="ioMsg" class="tiny"></span>
      </div>
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
            <span class="sync-badge" id="syncBadge">âšª Local Mode (Not shared)</span>
            <span class="tiny muted" id="syncLastTime"></span>
          </div>
          <div id="syncActiveDetails" class="hidden" style="margin-top:12px">
            <label class="tiny muted">Your Active Household Code:</label>
            <div style="display:flex;gap:8px;align-items:center;margin-top:4px">
              <span id="syncCurrentCodeDisplay" class="household-code-tag">KETO-XXXX</span>
              <button id="syncCopyCodeBtn" class="act-btn small" type="button">ðŸ“‹ Copy</button>
              <button id="syncShareCodeBtn" class="act-btn primary small" type="button">ðŸ“¤ Share Code</button>
            </div>
            <p class="tiny muted" style="margin-top:8px">ðŸŸ¢ Live 2-way sync is active. Whenever you or your partner modify meals or check off fridge items, both phones update instantly.</p>
            <div style="display:flex;gap:8px;margin-top:12px">
              <button id="syncForcePushBtn" class="act-btn" type="button">ðŸ”„ Sync Now</button>
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
              <button id="syncCreateBtn" class="act-btn primary" type="button">ðŸš€ Create Household</button>
            </div>
          </div>

          <!-- Option B: Join -->
          <div class="panel stack" style="background:var(--color-surface-2);border:1px dashed var(--color-border)">
            <h3>Option 2: Join an Existing Household</h3>
            <p class="muted small">Did your partner or family member already create a Household Code? Enter it below to join and sync with their planner and stock.</p>
            <div style="display:flex;gap:8px;align-items:center">
              <input id="syncJoinCodeInput" class="search" placeholder="Enter code (e.g. KETO-7491)" style="flex:1">
              <button id="syncJoinBtn" class="act-btn primary" type="button">ðŸ”— Join & Sync</button>
            </div>
          </div>
        </div>

        <!-- Firebase Firestore Activation Notice -->
        <details class="more-filters" style="margin-top:8px">
          <summary class="small"><strong>âš™ï¸ Database Setup (One-time, 1 minute)</strong></summary>
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

  <!-- Bottom Navigation Bar -->
  <nav class="bottom-nav">
    <button class="nav-item active" data-tab-btn="home">
      <span class="nav-icon">🏠</span>
      <span class="nav-label">Menu</span>
    </button>
    <button class="nav-item" data-tab-btn="planner">
      <span class="nav-icon">📅</span>
      <span class="nav-label">Planner</span>
    </button>
    <button class="nav-item" data-tab-btn="recipes">
      <span class="nav-icon">🍳</span>
      <span class="nav-label">Recipes</span>
    </button>
    <button class="nav-item" data-tab-btn="stock">
      <span class="nav-icon">📦</span>
      <span class="nav-label">Stock</span>
    </button>
    <button class="nav-item" data-tab-btn="settings">
      <span class="nav-icon">⚙️</span>
      <span class="nav-label">Settings</span>
    </button>
  </nav>

  <script>
'@

# Append extracted data structures
$html += "`n" + $recipesBlock + "`n"
$html += "const DAYS = ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5', 'Day 6', 'Day 7'];`n"
$html += "const SLOTS = ['Breakfast', 'Lunch', 'Dinner', 'Snack 1', 'Snack 2'];`n"
$html += "const TARGET = { kcal: 2000, protein: 190, netCarbs: 50, fat: 70 };`n"
$html += "const LS_KEY = 'ketoPlanner.v1';`n"
$html += "function loadState() { try { return JSON.parse(localStorage.getItem(LS_KEY)) || {}; } catch (e) { return {}; } }`n"
$html += "const SAVED = loadState();`n`n"
$html += $nutritionBlock + "`n`n"
$html += $cupsBlock + "`n`n"

# Append JS application logic
$html += @'
    function ingMacros(str) {
      const s = String(str).trim(); let m;
      if ((m = s.match(/^(\d+(?:\.\d+)?)\s*(g|ml)\s+(.+)$/i))) { const n = N[m[3]]; const g = +m[1] / 100; if (!n) return { k: 0, p: 0, f: 0, c: 0, known: false }; return { k: n[0] * g, p: n[1] * g, f: n[2] * g, c: n[3] * g, known: true }; }
      let cnt = null, rest = null;
      if ((m = s.match(/^half\s+(.+)$/i))) { cnt = 0.5; rest = m[1]; }
      else if ((m = s.match(/^(\d+(?:\.\d+)?)\s+(.+)$/))) { cnt = +m[1]; rest = m[2].replace(/^large\s+/, ''); }
      if (cnt !== null) { const cm = COUNT[rest] || COUNT[rest.replace(/s$/, '')]; if (!cm) return { k: 0, p: 0, f: 0, c: 0, known: false }; if (cm.pu) { const u = cm.pu; return { k: u[0] * cnt, p: u[1] * cnt, f: u[2] * cnt, c: u[3] * cnt, known: true }; } const n = nut(cm.key); const g = cm.g * cnt / 100; return { k: n[0] * g, p: n[1] * g, f: n[2] * g, c: n[3] * g, known: true }; }
      return { k: 0, p: 0, f: 0, c: 0, known: false };
    }
    function nut(key) { return NX[key] || N[key] || null; }
    function sumMacros(list) { return list.reduce((a, s) => { const m = ingMacros(s); a.kcal += m.k; a.protein += m.p; a.fat += m.f; a.netCarbs += m.c; return a; }, { kcal: 0, protein: 0, fat: 0, netCarbs: 0 }); }

    const SYN = { 'whey protein': 'whey', 'whey protein (vanilla or neutral)': 'whey', 'whey isolate': 'whey', 'protein powder': 'whey', 'cherry tomato': 'tomato', 'cherry tomatoes': 'tomato', 'tomatoes': 'tomato', 'full-fat greek yogurt': 'greek yogurt', 'greek yogurt 2%': 'greek yogurt', 'greek yogurt 2-5%': 'greek yogurt', 'milbona skyr natural': 'skyr', 'flaked almonds': 'almonds', 'large eggs': 'egg', 'eggs': 'egg' };
    function canon(name) { const n = String(name).toLowerCase().trim(); return SYN[n] || n; }
    const CATEGORIES = [
      ['Meat & seafood', ['chicken', 'beef', 'pork', 'turkey', 'lamb', 'steak', 'mince', 'bacon', 'ham', 'sausage', 'salami', 'pepperoni', 'salmon', 'mackerel', 'cod', 'shrimp', 'tuna', 'duck', 'jerky', 'rinds']],
      ['Dairy & eggs', ['egg', 'cheese', 'cheddar', 'mozzarella', 'parmesan', 'feta', 'telemea', 'ricotta', 'goat', 'swiss', 'blue cheese', 'cream', 'cottage', 'skyr', 'yogurt', 'yoghurt', 'butter', 'milk']],
      ['Fruits & vegetables', ['spinach', 'mushroom', 'broccoli', 'cauliflower', 'cabbage', 'asparagus', 'green bean', 'bell pepper', 'zucchini', 'cucumber', 'tomato', 'lettuce', 'romaine', 'onion', 'carrot', 'bok choy', 'eggplant', 'olive', 'pickle', 'celery', 'avocado', 'berr', 'blueberr', 'raspberr', 'strawberr', 'lemon', 'lime', 'ginger', 'garlic']],
      ['Pantry & baking', ['almond', 'coconut', 'baking powder', 'sweetener', 'cocoa', 'chocolate', 'chia', 'flax', 'seeds', 'vanilla', 'walnut', 'pecan', 'macadamia', 'peanut', 'bread', 'granola', 'flour']],
      ['Condiments & sauces', ['oil', 'mayonnaise', 'soy sauce', 'fish sauce', 'mustard', 'dressing', 'ranch', 'buffalo', 'tzatziki', 'horseradish', 'balsamic', 'vinegar', 'curry', 'sauce', 'passata', 'salt', 'pepper', 'paprika', 'cumin', 'chili', 'turmeric', 'coriander', 'oregano', 'thyme', 'rosemary', 'sage', 'basil', 'parsley', 'dill', 'mint', 'cilantro', 'chives', 'cinnamon', 'zest', 'herbs', 'spice']],
      ['Supplements', ['whey', 'protein bar', 'protein']]
    ];
    function categoryOf(name) {
      const n = name.toLowerCase();
      if (/peanut|almond butter|coconut butter/.test(n)) return 'Pantry & baking';
      if (/almond milk|coconut milk/.test(n)) return 'Pantry & baking';
      if (/\boil\b/.test(n)) return 'Condiments & sauces';
      for (const [cat, keys] of CATEGORIES) { if (keys.some(k => n.includes(k))) return cat; }
      return 'Other';
    }

    /* Custom Recipes & Ingredients */
    let customRecipes = Array.isArray(SAVED.customRecipes) ? SAVED.customRecipes : [];
    let customIngredients = (SAVED.customIngredients && typeof SAVED.customIngredients === 'object') ? SAVED.customIngredients : {};
    function applyCustomIngredients() { Object.keys(customIngredients).forEach(k => { N[k] = customIngredients[k]; }); }
    applyCustomIngredients();
    function allRecipes() { return RECIPES.concat(customRecipes); }
    let recipeMap = {};
    function rebuildMap() { recipeMap = Object.fromEntries(allRecipes().map(r => [r.id, r])); }
    rebuildMap();

    const BLANK_IMG = 'data:image/svg+xml,' + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"></svg>');
    let activeRecipeId = null;
    let currentSort = 'protein';
    let currentTab = 'home';
    let activeDay = 'Day 1';

    /* Settings & Stock Inventory */
    const DEFAULT_SETTINGS = { weightKg: 75, proteinPerKg: 2, dailyKcal: 2000, dailyNetCarbs: 50 };
    let settings = Object.assign({}, DEFAULT_SETTINGS, SAVED.settings || {});
    let packSizes = (SAVED.packSizes && typeof SAVED.packSizes === 'object') ? SAVED.packSizes : {};
    let stores = (SAVED.stores && typeof SAVED.stores === 'object') ? SAVED.stores : {
      'egg': 'generic / any', 'protein bread': 'Lidl', 'whey': 'GymBeam True Whey', 'greek yogurt': 'Milbona (Lidl)',
      'cottage cheese': 'Milbona', 'skyr': 'Milbona', 'mozzarella': 'Milbona', 'chicken breast': 'Lidl own brand', 'beef mince': 'Lidl own brand'
    };
    let meta = (SAVED.meta && typeof SAVED.meta === 'object') ? SAVED.meta : {};
    let ticked = (SAVED.ticked && typeof SAVED.ticked === 'object') ? SAVED.ticked : {};

    /* STOCK INITIALIZATION */
    const PANTRY_STAPLES = ['salt', 'sea salt', 'pepper', 'black pepper', 'paprika', 'cumin', 'chili powder', 'chili flakes', 'garlic powder', 'turmeric', 'coriander', 'oregano', 'thyme', 'rosemary', 'cinnamon', 'sweetener', 'vanilla extract', 'baking powder', 'olive oil', 'coconut oil', 'soy sauce', 'vinegar', 'mustard', 'almond flour', 'coconut flour', 'chia seeds', 'flaxseed', 'walnuts'];
    let stock = SAVED.stock;
    if (!stock || typeof stock !== 'object') {
      const oldPantry = SAVED.pantryHave || {};
      stock = {
        pantry: PANTRY_STAPLES.map(s => ({ name: s, have: (typeof oldPantry[s] !== 'undefined') ? !!oldPantry[s] : !/flour|oil|sauce|mustard|vinegar/.test(s) })),
        fridge: [
          { name: "Eggs (fresh)", have: true }, { name: "Butter (82%)", have: true }, { name: "Cheddar cheese", have: true },
          { name: "Mozzarella", have: false }, { name: "Feta / Telemea", have: true }, { name: "Greek yogurt", have: true },
          { name: "Cottage cheese", have: false }, { name: "Milbona skyr", have: true }, { name: "Cooking cream", have: false },
          { name: "Fresh spinach", have: true }, { name: "Mushrooms", have: false }, { name: "Cucumber", have: true }, { name: "Mayonnaise", have: true }
        ],
        freezer: [
          { name: "Chicken breast", have: true }, { name: "Beef mince (15%)", have: true }, { name: "Salmon fillets", have: false },
          { name: "Cauliflower rice", have: true }, { name: "Frozen berries", have: true }, { name: "Bacon rashers", have: true }
        ]
      };
    }
    let currentStockTab = 'pantry';
    let currentStockFilter = 'all';

    function emptyPlan() { const o = {}; DAYS.forEach(d => { o[d] = {}; SLOTS.forEach(s => o[d][s] = ''); }); return o; }
    let custom = emptyPlan();
    if (SAVED.custom && typeof SAVED.custom === 'object') {
      DAYS.forEach(day => { if (SAVED.custom[day]) SLOTS.forEach(slot => { if (typeof SAVED.custom[day][slot] === 'string') custom[day][slot] = SAVED.custom[day][slot]; }); });
    }
    let shopping = (SAVED.shopping && typeof SAVED.shopping === 'object') ? SAVED.shopping : {};

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
          badge.textContent = 'ðŸŸ¢ Live Synced (' + currentHouseholdCode + ')';
        }
        if (activeDetails) activeDetails.classList.remove('hidden');
        if (setupContainer) setupContainer.classList.add('hidden');
        if (codeDisplay) codeDisplay.textContent = currentHouseholdCode;
        if (homeSubtitle) homeSubtitle.textContent = 'ðŸŸ¢ Live Synced with: ' + currentHouseholdCode;
      } else {
        if (badge) {
          badge.className = 'sync-badge';
          badge.textContent = 'âšª Local Mode (Not shared)';
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
            pushToCloud(false);
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
          showSyncToast('â˜ï¸ Live update from partner synced!');
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
      try {
        pushToCloud(false);
        localStorage.setItem(LS_KEY, JSON.stringify({
          custom, shopping, customRecipes, settings, stock, packSizes, stores, ticked, meta, customIngredients
        }));
      } catch (e) { }
    }

    function protTarget() { const p = Math.round((settings.weightKg || 0) * (settings.proteinPerKg || 0)); return p || TARGET.protein; }

    function round5(x) { return Math.round(x / 5) * 5; }
    function isSeasoning(name) { const n = N[name] || N[canon(name)]; return !!(n && n[0] === 0); }
    function notSeasoningIng(ing) { const p = parseQty(ing); return !isSeasoning(p.name); }
    const COOK_RE = /cook|bake|fry|roast|sear|simmer|saut|boil|grill|air-?fry|microwave|steam|brown|poach|scramble/;
    function defaultTime(r) {
      const text = ((r.method || '') + ' ' + (r.batch || '')).toLowerCase();
      const nIng = r.ingredients.filter(notSeasoningIng).length;
      let prep = Math.max(5, Math.min(30, round5(4 + 2 * nIng)));
      let cook = 0; const m = text.match(/(\d+)\s*min/);
      if (m) cook = round5(+m[1]);
      else if (COOK_RE.test(text)) cook = (r.meal === 'Breakfast' ? 10 : (r.meal === 'Snack' ? 15 : 25));
      return { prep, cook };
    }
    function timeOf(r) {
      const m = meta[r.id] || {}; const d = defaultTime(r);
      const hasP = typeof m.prep === 'number', hasC = typeof m.cook === 'number';
      const prep = hasP ? m.prep : d.prep, cook = hasC ? m.cook : d.cook;
      return { prep, cook, total: prep + cook, est: !(hasP || hasC) };
    }
    function fmtTime(min) { min = Math.round(min); if (min < 60) return min + ' min'; const h = Math.floor(min / 60), mm = min % 60; return mm ? h + ' h ' + mm + ' min' : h + ' h'; }
    function weekPlanTime() { let t = 0; DAYS.forEach(day => SLOTS.forEach(slot => { const r = recipeMap[custom[day][slot]]; if (r) t += timeOf(r).total; })); return t; }
    function ratingOf(r) { return (meta[r.id] && meta[r.id].rating) || 0; }
    function starString(n) { return '★'.repeat(Math.max(0, Math.min(5, n))) + '☆'.repeat(Math.max(0, 5 - n)); }
    function tagsOf(r) {
      const m = meta[r.id]; if (m && Array.isArray(m.tags) && m.tags.length) return m.tags;
      const t = [];
      if (r.meal === 'Breakfast') t.push('breakfast');
      if (r.meal === 'Lunch/Dinner') t.push('main');
      if (r.meal === 'Snack') t.push('snack');
      if (r.batch && /batch|fridge|freezer/i.test(r.batch)) t.push('batch-cook');
      if (r.freezer && !/no|not/i.test(r.freezer)) t.push('freezer-friendly');
      if (r.protein >= 45) t.push('high-protein');
      if (r.netCarbs <= 5) t.push('ultra-low-carb');
      return t;
    }
    function sortRecipes(list) {
      const copy = list.slice();
      if (currentSort === 'protein') return copy.sort((a, b) => b.protein - a.protein);
      if (currentSort === 'calories') return copy.sort((a, b) => Math.abs(a.kcal - 520) - Math.abs(b.kcal - 520));
      if (currentSort === 'batch') return copy.sort((a, b) => (b.batch ? 1 : 0) - (a.batch ? 1 : 0));
      if (currentSort === 'rating') return copy.sort((a, b) => ratingOf(b) - ratingOf(a));
      if (currentSort === 'time') return copy.sort((a, b) => timeOf(a).total - timeOf(b).total);
      return copy;
    }

    function optionsForSlot(slot) {
      const list = allRecipes();
      if (slot === 'Breakfast') return sortRecipes(list.filter(r => r.meal === 'Breakfast'));
      if (slot === 'Lunch' || slot === 'Dinner') return sortRecipes(list.filter(r => r.meal === 'Lunch/Dinner'));
      return sortRecipes(list.filter(r => r.meal === 'Snack'));
    }
    function optionLabel(r) { return `${r.name} (${r.kcal} kcal | P ${r.protein}g | F ${r.fat}g | NC ${r.netCarbs}g)`; }
    function totalForDay(dayMap) {
      const t = { kcal: 0, protein: 0, fat: 0, netCarbs: 0 };
      SLOTS.forEach(s => { const r = recipeMap[dayMap[s]]; if (r) { t.kcal += r.kcal; t.protein += r.protein; t.fat += r.fat; t.netCarbs += r.netCarbs; } });
      return t;
    }
    function fmt(n) { return Math.round(n); }
    function numFmt(n) { return (Math.round(n * 10) / 10).toFixed(n % 1 ? 1 : 0); }
    function capitalize(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1) : ''; }

    function dayLevel(metric, value) {
      if (metric === 'kcal') { const t = settings.dailyKcal || 2000; const d = Math.abs(value - t) / t; return d <= 0.15 ? 'good' : (d <= 0.30 ? 'warn' : 'bad'); }
      if (metric === 'protein') { const t = protTarget(); if (value >= t) return 'good'; if (value >= t * 0.8) return 'warn'; return 'bad'; }
      if (metric === 'netCarbs') { const c = settings.dailyNetCarbs || 50; if (value <= c) return 'good'; if (value <= c * 1.2) return 'warn'; return 'bad'; }
      return '';
    }
    function macroPct(t) { const p = t.protein * 4, f = t.fat * 9, c = t.netCarbs * 4; const s = p + f + c || 1; return { f: Math.round(f / s * 100), p: Math.round(p / s * 100), c: Math.round(c / s * 100) }; }

    /* NAVIGATION LOGIC */
    const TAB_TITLES = {
      'home': 'Keto Planner',
      'planner': 'Weekly Planner',
      'recipes': 'Recipe Library',
      'stock': 'Stock Manager',
      'builder': 'Recipe Builder',
      'macros': 'Macronutrients',
      'convert': 'Unit Converter',
      'settings': 'Settings & Backup',
      'sync': 'Live Cloud Sync'
    };

    function switchTab(tabName) {
      currentTab = tabName;
      document.querySelectorAll('[data-tab]').forEach(sec => sec.classList.toggle('hidden', sec.dataset.tab !== tabName));
      document.querySelectorAll('.bottom-nav .nav-item').forEach(btn => btn.classList.toggle('active', btn.dataset.tabBtn === tabName));

      const backBtn = document.getElementById('appBackBtn');
      const brand = document.getElementById('headerBrand');
      const headerTitle = document.getElementById('appHeaderTitle');

      if (tabName === 'home') {
        backBtn.classList.add('hidden');
        brand.classList.remove('hidden');
        headerTitle.classList.add('hidden');
      } else {
        backBtn.classList.remove('hidden');
        brand.classList.add('hidden');
        headerTitle.classList.remove('hidden');
        headerTitle.textContent = TAB_TITLES[tabName] || 'Keto Planner';
      }

      window.scrollTo({ top: 0, behavior: 'instant' });
      if (tabName === 'stock') renderStock();
      if (tabName === 'macros') renderMacros();
    }

    // Android Hardware Back button integration
    window.onAndroidBack = function() {
      if (currentTab !== 'home') {
        switchTab('home');
        return true;
      }
      return false;
    };

    /* PLANNER RENDERING (MOBILE FIRST) */
    function buildPlannerDayPills() {
      const wrap = document.getElementById('plannerDayPills');
      if (!wrap) return;
      const pills = DAYS.concat(['All Days']).map(d => `<button class="day-pill ${d === activeDay ? 'active' : ''}" data-daypill="${d}">${d}</button>`).join('');
      wrap.innerHTML = pills;
      wrap.querySelectorAll('[data-daypill]').forEach(btn => btn.addEventListener('click', () => {
        activeDay = btn.dataset.daypill;
        buildPlannerDayPills();
        buildCustom();
      }));
    }

    function buildCustom() {
      const wrap = document.getElementById('customDays');
      if (!wrap) return;

      const daysToShow = activeDay === 'All Days' ? DAYS : [activeDay];

      wrap.innerHTML = daysToShow.map(day => {
        const rows = SLOTS.map(slot => {
          const cur = custom[day][slot];
          const rec = cur ? recipeMap[cur] : null;
          const none = `<option value="" ${cur ? '' : 'selected'}>— none —</option>`;
          const opts = optionsForSlot(slot).map(r => `<option value="${r.id}" ${cur === r.id ? 'selected' : ''}>${optionLabel(r)}</option>`).join('');
          return `
            <div class="meal-slot-row">
              <div class="slot-header">
                <span class="slot-badge">${slot}</span>
                ${cur ? `<button class="x-btn" type="button" data-clear-day="${day}" data-clear-slot="${slot}" title="Clear slot">×</button>` : ''}
              </div>
              <div class="slot-control">
                <img class="slot-thumb" src="${rec ? recipeImage(rec) : BLANK_IMG}" alt="" style="${rec ? '' : 'display:none'}">
                <select class="slot-select" data-day="${day}" data-slot="${slot}">${none}${opts}</select>
              </div>
            </div>`;
        }).join('');

        const copySel = `<select class="copy-day" data-copy-src="${day}"><option value="">Copy to…</option>${DAYS.filter(d => d !== day).map(d => `<option value="${d}">${d}</option>`).join('')}<option value="all">All days</option></select>`;

        return `
          <div class="day-card">
            <div class="day-card-header">
              <h3>${day}</h3>
              ${copySel}
            </div>
            <div class="stack" style="gap:6px">${rows}</div>
            <div class="day-totals-box" id="total-${day.replace(/\s/g, '')}"></div>
          </div>`;
      }).join('');

      wrap.querySelectorAll('select.slot-select').forEach(sel => sel.addEventListener('change', e => {
        custom[e.target.dataset.day][e.target.dataset.slot] = e.target.value;
        const img = e.target.parentElement.querySelector('.slot-thumb');
        const rec = recipeMap[e.target.value];
        if (img) {
          if (rec) { img.src = recipeImage(rec); img.style.display = ''; }
          else { img.style.display = 'none'; }
        }
        updateCustomTotals();
        afterPlannerChange();
      }));

      wrap.querySelectorAll('[data-clear-day]').forEach(btn => btn.addEventListener('click', () => clearSlot(btn.dataset.clearDay, btn.dataset.clearSlot)));
      wrap.querySelectorAll('.copy-day').forEach(sel => sel.addEventListener('change', e => { const dst = e.target.value; if (dst) copyDay(e.target.dataset.copySrc, dst); }));

      updateCustomTotals();
    }

    function clearSlot(day, slot) { custom[day][slot] = ''; buildCustom(); afterPlannerChange(); }
    function copyDay(src, dst) {
      if (dst === 'all') { DAYS.forEach(d => { if (d !== src) SLOTS.forEach(s => custom[d][s] = custom[src][s]); }); }
      else { SLOTS.forEach(s => custom[dst][s] = custom[src][s]); }
      buildCustom(); afterPlannerChange();
    }
    function afterPlannerChange() { saveState(); renderShopping(); markPlannerInList(); }
    function clearAllPlanner() { if (confirm('Clear all days in the planner?')) { custom = emptyPlan(); buildCustom(); afterPlannerChange(); } }

    function updateCustomTotals() {
      DAYS.forEach(day => {
        const el = document.getElementById('total-' + day.replace(/\s/g, ''));
        if (el) {
          const t = totalForDay(custom[day]);
          const k = dayLevel('kcal', t.kcal), pc = dayLevel('protein', t.protein), cc = dayLevel('netCarbs', t.netCarbs);
          const r = macroPct(t);
          el.innerHTML = `<strong>Day Total:</strong> <span class="${k}">${fmt(t.kcal)} kcal</span> • <span class="${pc}">P ${fmt(t.protein)}g</span> • F ${fmt(t.fat)}g • <span class="${cc}">NC ${fmt(t.netCarbs)}g</span> <span class="tiny muted">(${r.f}% F · ${r.p}% P · ${r.c}% C)</span>`;
        }
      });

      const week = DAYS.reduce((acc, day) => { const t = totalForDay(custom[day]); acc.kcal += t.kcal; acc.protein += t.protein; acc.fat += t.fat; acc.netCarbs += t.netCarbs; return acc; }, { kcal: 0, protein: 0, fat: 0, netCarbs: 0 });
      const avg = { kcal: week.kcal / DAYS.length, protein: week.protein / DAYS.length, fat: week.fat / DAYS.length, netCarbs: week.netCarbs / DAYS.length };

      const kpis = document.getElementById('customKpis');
      if (kpis) {
        kpis.innerHTML = [
          ['Avg kcal/day', fmt(avg.kcal), dayLevel('kcal', avg.kcal)],
          ['Avg protein/day', fmt(avg.protein) + ' g', dayLevel('protein', avg.protein)],
          ['Protein target', protTarget() + ' g', ''],
          ['Avg net carbs/day', fmt(avg.netCarbs) + ' g', dayLevel('netCarbs', avg.netCarbs)]
        ].map(([l, v, cls]) => `<div class="kpi"><div class="label">${l}</div><div class="value ${cls}">${v}</div></div>`).join('');
      }

      const hKcal = document.getElementById('homeTargetKcal');
      const hProt = document.getElementById('homeTargetProt');
      const hCarbs = document.getElementById('homeTargetCarbs');
      if (hKcal) hKcal.textContent = (settings.dailyKcal || 2000) + ' kcal';
      if (hProt) hProt.textContent = protTarget() + ' g';
      if (hCarbs) hCarbs.textContent = '≤ ' + (settings.dailyNetCarbs || 50) + ' g';
    }

    /* STOCK MANAGER IMPLEMENTATION */
    function renderStock() {
      const wrap = document.getElementById('stockList');
      if (!wrap) return;

      const items = stock[currentStockTab] || [];
      const searchQ = (document.getElementById('stockSearch')?.value || '').trim().toLowerCase();

      // Counts
      ['pantry', 'fridge', 'freezer'].forEach(cat => {
        const cEl = document.getElementById('stockCount' + capitalize(cat));
        if (cEl) cEl.textContent = String((stock[cat] || []).length);
      });

      let filtered = items.filter(i => {
        if (searchQ && !i.name.toLowerCase().includes(searchQ)) return false;
        if (currentStockFilter === 'have' && !i.have) return false;
        if (currentStockFilter === 'need' && i.have) return false;
        return true;
      });

      if (!filtered.length) {
        wrap.innerHTML = `<div class="note tiny muted" style="text-align:center;padding:var(--space-4)">No items found in ${currentStockTab}. Add an item above!</div>`;
        return;
      }

      wrap.innerHTML = filtered.map((item, idx) => {
        const realIdx = items.indexOf(item);
        return `
          <div class="stock-item-row ${item.have ? 'is-stocked' : 'is-missing'}">
            <label class="stock-check-label">
              <input type="checkbox" class="stock-check-input" data-stock-idx="${realIdx}" ${item.have ? 'checked' : ''}>
              <span class="stock-item-name">${item.name}</span>
            </label>
            <div class="stock-item-actions">
              <span class="stock-badge ${item.have ? 'badge-have' : 'badge-need'}">${item.have ? 'In Stock' : 'Need'}</span>
              <button class="x-btn" type="button" data-stock-del="${realIdx}" title="Delete">×</button>
            </div>
          </div>`;
      }).join('');

      wrap.querySelectorAll('.stock-check-input').forEach(cb => {
        cb.addEventListener('change', e => {
          const idx = parseInt(e.target.dataset.stockIdx, 10);
          stock[currentStockTab][idx].have = e.target.checked;
          saveState();
          renderStock();
          renderShopping();
        });
      });

      wrap.querySelectorAll('[data-stock-del]').forEach(btn => {
        btn.addEventListener('click', e => {
          const idx = parseInt(btn.dataset.stockDel, 10);
          stock[currentStockTab].splice(idx, 1);
          saveState();
          renderStock();
          renderShopping();
        });
      });
    }

    function addStockItem() {
      const inp = document.getElementById('stockAddInput');
      const val = inp ? inp.value.trim() : '';
      if (!val) return;
      if (!stock[currentStockTab]) stock[currentStockTab] = [];
      stock[currentStockTab].push({ name: val, have: true });
      inp.value = '';
      saveState();
      renderStock();
      renderShopping();
    }

    function addMissingStockToShopping() {
      let count = 0;
      ['pantry', 'fridge', 'freezer'].forEach(cat => {
        (stock[cat] || []).forEach(item => {
          if (!item.have) {
            const k = canon(item.name);
            shopping[k] = (shopping[k] || 0) + 1;
            count++;
          }
        });
      });
      renderShopping();
      saveState();
      alert(`Added ${count} missing item(s) from Stock into your Shopping List!`);
    }

    /* MACRONUTRIENTS (MOBILE CARDS) */
    let macroSortCol = 'name';
    let MACRO_ROWS = [];

    function buildMacros() {
      MACRO_ROWS = [];
      Object.keys(N).sort((a, b) => a.localeCompare(b)).forEach(k => {
        const v = N[k];
        MACRO_ROWS.push({ name: k, basis: 'per 100 g', k: v[0], p: v[1], f: v[2], c: v[3], custom: Object.prototype.hasOwnProperty.call(customIngredients, k) });
      });
      Object.keys(COUNT).forEach(k => {
        const cm = COUNT[k];
        if (cm.pu) MACRO_ROWS.push({ name: k, basis: 'per unit', k: cm.pu[0], p: cm.pu[1], f: cm.pu[2], c: cm.pu[3], custom: false });
      });
      renderMacros();
    }

    function renderMacros() {
      const wrap = document.getElementById('macroCardsContainer');
      if (!wrap) return;

      const q = (document.getElementById('macroSearch')?.value || '').trim().toLowerCase();
      let rows = MACRO_ROWS.filter(r => !q || r.name.toLowerCase().includes(q));

      if (macroSortCol === 'name') rows.sort((a, b) => a.name.localeCompare(b.name));
      else rows.sort((a, b) => b[macroSortCol] - a[macroSortCol]);

      wrap.innerHTML = rows.map(r => `
        <div class="macro-card">
          <div class="macro-card-top">
            <div>
              <strong>${capitalize(r.name)}</strong>
              <span class="macro-basis">${r.basis}</span>
              ${r.custom ? '<span class="tiny good" style="margin-left:4px">(custom)</span>' : ''}
            </div>
            ${r.custom ? `<button class="x-btn ing-del" data-ingdel="${r.name.replace(/"/g, '&quot;')}" title="Delete">×</button>` : ''}
          </div>
          <div class="macro-chips-row">
            <div class="macro-stat-pill"><span>Calories</span><strong>${numFmt(r.k)}</strong></div>
            <div class="macro-stat-pill"><span>Protein</span><strong>${numFmt(r.p)}g</strong></div>
            <div class="macro-stat-pill"><span>Fat</span><strong>${numFmt(r.f)}g</strong></div>
            <div class="macro-stat-pill"><span>Net Carbs</span><strong>${numFmt(r.c)}g</strong></div>
          </div>
        </div>
      `).join('');

      wrap.querySelectorAll('.ing-del').forEach(b => b.addEventListener('click', () => deleteCustomIngredient(b.dataset.ingdel)));
    }

    function saveCustomIngredient() {
      const name = canon((document.getElementById('ingName')?.value || '').trim());
      const k = parseFloat(document.getElementById('ingKcal')?.value) || 0;
      const p = parseFloat(document.getElementById('ingProt')?.value) || 0;
      const f = parseFloat(document.getElementById('ingFat')?.value) || 0;
      const c = parseFloat(document.getElementById('ingCarbs')?.value) || 0;
      const msg = document.getElementById('ingMsg');
      if (!name) { if (msg) { msg.textContent = 'Ingredient name required.'; msg.className = 'tiny bad'; } return; }
      customIngredients[name] = [k, p, f, c];
      applyCustomIngredients();
      saveState();
      buildMacros();
      if (msg) { msg.textContent = `Saved ${name}!`; msg.className = 'tiny good'; }
      document.getElementById('ingName').value = '';
    }
    function deleteCustomIngredient(name) {
      delete customIngredients[name];
      delete N[name];
      saveState();
      buildMacros();
    }

    /* RECIPES LIBRARY */
    function mealBucket(r) { return r.meal === 'Breakfast' ? 'breakfast' : (r.meal === 'Lunch/Dinner' ? 'main' : 'snack'); }
    function recipeMatchesFilters(r) {
      const q = (document.getElementById('recipeSearch')?.value || '').trim().toLowerCase();
      const showBreakfast = document.getElementById('filterBreakfast')?.checked ?? true;
      const showMain = document.getElementById('filterMain')?.checked ?? true;
      const showSnack = document.getElementById('filterSnack')?.checked ?? true;
      const bucket = mealBucket(r);
      if (!((bucket === 'breakfast' && showBreakfast) || (bucket === 'main' && showMain) || (bucket === 'snack' && showSnack))) return false;
      const hay = (r.name + ' ' + r.ingredients.join(' ')).toLowerCase();
      if (q && !hay.includes(q)) return false;
      const minP = parseFloat(document.getElementById('fProtein')?.value || 0) || 0;
      if (r.protein < minP) return false;
      const maxC = parseFloat(document.getElementById('fCarbs')?.value || 99) || 99;
      if (r.netCarbs > maxC) return false;
      const inc = (document.getElementById('fInclude')?.value || '').trim().toLowerCase();
      if (inc && !hay.includes(inc)) return false;
      const exc = (document.getElementById('fExclude')?.value || '').trim().toLowerCase();
      if (exc && hay.includes(exc)) return false;
      return true;
    }

    function buildRecipeList() {
      const wrap = document.getElementById('recipeList');
      if (!wrap) return;
      const sorted = sortRecipes(allRecipes()).filter(recipeMatchesFilters);
      const countEl = document.getElementById('recipeCount');
      if (countEl) countEl.textContent = String(sorted.length);

      wrap.innerHTML = sorted.map(r => {
        const rt = ratingOf(r);
        return `
          <button class="recipe-btn ${r.id === activeRecipeId ? 'active' : ''}" data-rid="${r.id}">
            <img class="recipe-thumb" src="${recipeImage(r)}" alt="" loading="lazy">
            <span class="recipe-meta">
              <strong>${r.name}${rt ? ` <span class="tiny">${starString(rt)}</span>` : ''}</strong>
              <div class="tiny muted">${r.meal} • ${r.kcal} kcal • P ${r.protein}g • NC ${r.netCarbs}g • ⏱ ${fmtTime(timeOf(r).total)}</div>
            </span>
          </button>`;
      }).join('');

      wrap.querySelectorAll('.recipe-btn').forEach(btn => btn.addEventListener('click', () => {
        activeRecipeId = btn.dataset.rid;
        wrap.querySelectorAll('.recipe-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        renderRecipe(btn.dataset.rid);
      }));
    }

    function renderRecipe(id) {
      const r = recipeMap[id];
      const container = document.getElementById('recipeDetailContainer');
      const detail = document.getElementById('recipeDetail');
      if (!r || !container || !detail) return;

      container.classList.remove('hidden');
      detail.innerHTML = `
        <h3 style="font-size:var(--text-lg);margin-bottom:4px">${r.name}</h3>
        <p class="muted tiny">${r.meal} • ${r.portion} • <a href="${recipeLink(r)}" target="_blank">Search online ↗</a></p>
        <div class="macro-chips-row" style="margin:10px 0">
          <div class="macro-stat-pill"><span>Calories</span><strong>${r.kcal}</strong></div>
          <div class="macro-stat-pill"><span>Protein</span><strong>${r.protein}g</strong></div>
          <div class="macro-stat-pill"><span>Fat</span><strong>${r.fat}g</strong></div>
          <div class="macro-stat-pill"><span>Net Carbs</span><strong>${r.netCarbs}g</strong></div>
        </div>
        <div style="margin-bottom:10px">
          <strong class="small">Ingredients:</strong>
          <ul style="padding-left:18px;margin-top:4px" class="small">${r.ingredients.map(i => `<li>${i}</li>`).join('')}</ul>
        </div>
        <div style="margin-bottom:12px">
          <strong class="small">Method:</strong>
          <p class="small muted" style="margin-top:4px;line-height:1.4">${r.method || 'No instructions provided.'}</p>
        </div>
        <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap">
          <select id="planDaySelect" class="slot-select" style="width:auto">${DAYS.map(d => `<option value="${d}">${d}</option>`).join('')}</select>
          <select id="planSlotSelect" class="slot-select" style="width:auto">
            ${r.meal === 'Breakfast' ? '<option value="Breakfast">Breakfast</option>' : (r.meal === 'Lunch/Dinner' ? '<option value="Lunch">Lunch</option><option value="Dinner">Dinner</option>' : '<option value="Snack 1">Snack 1</option><option value="Snack 2">Snack 2</option>')}
          </select>
          <button id="addPlanBtn" class="act-btn primary" type="button">Add to planner</button>
        </div>
        <span id="recipeActionMsg" class="tiny good" style="display:block;margin-top:6px"></span>
      `;

      document.getElementById('closeRecipeDetailBtn').onclick = () => container.classList.add('hidden');
      document.getElementById('addPlanBtn').onclick = () => {
        const day = document.getElementById('planDaySelect').value;
        const slot = document.getElementById('planSlotSelect').value;
        custom[day][slot] = r.id;
        afterPlannerChange();
        const msg = document.getElementById('recipeActionMsg');
        if (msg) msg.textContent = `Added to ${day} ${slot}!`;
      };
      container.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }

    function recipeLink(r) { return r.link || ('https://www.google.com/search?q=' + encodeURIComponent(r.name + ' keto recipe')); }
    function recipeImage(r) {
      const pal = { a: '#01696f', b: '#0c4e54' };
      return 'data:image/svg+xml,' + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" fill="${pal.a}"/><circle cx="50" cy="50" r="30" fill="${pal.b}"/><text x="50" y="55" font-size="28" text-anchor="middle" fill="#ffffff" font-family="sans-serif">🍳</text></svg>`);
    }

    /* SHOPPING LIST */
    function parseQty(str) {
      const s = String(str).trim(); let m;
      if ((m = s.match(/^(\d+(?:\.\d+)?)\s*(g|ml)\s+(.+)$/i))) return { qty: +m[1], unit: m[2].toLowerCase(), name: canon(m[3]) };
      if ((m = s.match(/^half\s+(.+)$/i))) return { qty: 0.5, unit: 'count', name: canon(m[1]) };
      if ((m = s.match(/^(\d+(?:\.\d+)?)\s+(.+)$/))) return { qty: +m[1], unit: 'count', name: canon(m[2].replace(/^large\s+/, '')) };
      return { qty: 1, unit: 'count', name: canon(s) };
    }

    function addDaysToShopping(lo, hi, servings) {
      let count = 0;
      for (let i = lo; i <= hi; i++) {
        const d = DAYS[i];
        SLOTS.forEach(s => {
          const r = recipeMap[custom[d][s]];
          if (r) {
            r.ingredients.forEach(ing => {
              const p = parseQty(ing);
              // If marked in stock pantry, don't need to shop
              const isStocked = (stock.pantry || []).some(item => item.have && canon(item.name) === p.name);
              if (!isStocked) {
                shopping[p.name] = (shopping[p.name] || 0) + (p.qty * servings);
                count++;
              }
            });
          }
        });
      }
      renderShopping();
      saveState();
      return count;
    }

    function renderShopping() {
      const wrap = document.getElementById('shoppingList');
      const ta = document.getElementById('shoppingText');
      if (!wrap) return;

      const keys = Object.keys(shopping).filter(k => shopping[k] > 0);
      if (!keys.length) {
        wrap.innerHTML = '<p class="muted tiny">Shopping list is empty.</p>';
        if (ta) ta.value = '';
        return;
      }

      wrap.innerHTML = `<ul class="shop-list">${keys.map(k => `
        <li>
          <span><strong>${capitalize(k)}</strong>: ${shopping[k]}</span>
          <button class="x-btn" type="button" data-delshop="${k}">×</button>
        </li>
      `).join('')}</ul>`;

      wrap.querySelectorAll('[data-delshop]').forEach(btn => {
        btn.addEventListener('click', () => { delete shopping[btn.dataset.delshop]; renderShopping(); saveState(); });
      });

      if (ta) ta.value = shoppingText();
    }

    function clearShopping() { shopping = {}; renderShopping(); saveState(); }
    function shoppingText() {
      return Object.keys(shopping).map(k => `${capitalize(k)}: ${shopping[k]}`).join('\n');
    }

    /* RECIPE BUILDER */
    function addBuilderRow() {
      const wrap = document.getElementById('builderRows');
      if (!wrap) return;
      const div = document.createElement('div');
      div.className = 'bld-row';
      div.style.cssText = 'display:flex;gap:4px;margin-bottom:4px';
      div.innerHTML = `
        <input class="search bld-name" placeholder="Ingredient (e.g. eggs, chicken)" style="flex:2">
        <input class="search bld-qty" type="number" placeholder="Qty" style="flex:1">
        <select class="slot-select bld-unit" style="flex:1"><option value="g">g</option><option value="ml">ml</option><option value="count">count</option></select>
        <button class="x-btn bld-del" type="button">×</button>`;
      wrap.appendChild(div);
      div.querySelectorAll('input,select').forEach(el => el.addEventListener('input', refreshBuilder));
      div.querySelector('.bld-del').addEventListener('click', () => { div.remove(); refreshBuilder(); });
    }

    function refreshBuilder() {
      const rows = document.querySelectorAll('.bld-row');
      const servings = Math.max(1, parseFloat(document.getElementById('builderServings')?.value) || 1);
      const ingList = [];
      rows.forEach(r => {
        const name = (r.querySelector('.bld-name')?.value || '').trim();
        const qty = parseFloat(r.querySelector('.bld-qty')?.value) || 0;
        const unit = r.querySelector('.bld-unit')?.value || 'g';
        if (name && qty) ingList.push(`${qty} ${unit === 'count' ? '' : unit} ${name}`.trim());
      });
      const totals = sumMacros(ingList);
      const perServ = { kcal: totals.kcal / servings, protein: totals.protein / servings, fat: totals.fat / servings, netCarbs: totals.netCarbs / servings };
      const out = document.getElementById('builderPreview');
      if (out) out.innerHTML = `<strong>Per Serving (${servings} total):</strong> ${fmt(perServ.kcal)} kcal • P ${fmt(perServ.protein)}g • F ${fmt(perServ.fat)}g • NC ${fmt(perServ.netCarbs)}g`;
    }

    function saveBuilderRecipe() {
      const name = (document.getElementById('builderName')?.value || '').trim();
      const meal = document.getElementById('builderMeal')?.value || 'Lunch/Dinner';
      const servings = Math.max(1, parseFloat(document.getElementById('builderServings')?.value) || 1);
      const rows = document.querySelectorAll('.bld-row');
      const ingList = [];
      rows.forEach(r => {
        const n = (r.querySelector('.bld-name')?.value || '').trim();
        const q = parseFloat(r.querySelector('.bld-qty')?.value) || 0;
        const u = r.querySelector('.bld-unit')?.value || 'g';
        if (n && q) ingList.push(`${q} ${u === 'count' ? '' : u} ${n}`.trim());
      });
      if (!name || !ingList.length) { alert('Recipe name and at least one ingredient required.'); return; }
      const totals = sumMacros(ingList);
      const rec = {
        id: 'c_' + Date.now(),
        name, meal, portion: '1 serving',
        kcal: fmt(totals.kcal / servings),
        protein: fmt(totals.protein / servings),
        fat: fmt(totals.fat / servings),
        netCarbs: fmt(totals.netCarbs / servings),
        ingredients: ingList,
        method: 'Custom prepared recipe.',
        custom: true
      };
      customRecipes.push(rec);
      rebuildMap();
      saveState();
      buildRecipeList();
      buildCustom();
      renderBuilderSaved();
      const msg = document.getElementById('builderMsg');
      if (msg) msg.textContent = 'Saved to your library!';
    }

    function renderBuilderSaved() {
      const wrap = document.getElementById('builderSaved');
      if (!wrap) return;
      if (!customRecipes.length) { wrap.innerHTML = '<p class="muted tiny">No custom recipes yet.</p>'; return; }
      wrap.innerHTML = customRecipes.map(r => `
        <div style="display:flex;justify-content:space-between;align-items:center;padding:6px;border-bottom:1px solid var(--color-divider)">
          <span class="small"><strong>${r.name}</strong> (${r.kcal} kcal, P ${r.protein}g)</span>
          <button class="x-btn" data-delcust="${r.id}">×</button>
        </div>
      `).join('');
      wrap.querySelectorAll('[data-delcust]').forEach(btn => {
        btn.addEventListener('click', () => {
          customRecipes = customRecipes.filter(r => r.id !== btn.dataset.delcust);
          rebuildMap(); saveState(); buildRecipeList(); buildCustom(); renderBuilderSaved();
        });
      });
    }

    /* UNIT CONVERTER */
    function buildConvertTab() {
      const sel = document.getElementById('convIngredient');
      if (sel) {
        sel.innerHTML = Object.keys(CUP_DENSITY).sort().map(k => `<option value="${k}">${capitalize(k)} (${CUP_DENSITY[k]} g/cup)</option>`).join('');
      }
      const list = document.getElementById('convDensityList');
      if (list) {
        list.innerHTML = Object.keys(CUP_DENSITY).sort().map(k => `<div style="display:flex;justify-content:space-between"><span>${capitalize(k)}</span><strong>${CUP_DENSITY[k]} g/cup</strong></div>`).join('');
      }
      runConvert();
    }
    function runConvert() {
      const ing = document.getElementById('convIngredient')?.value || 'butter';
      const amt = parseFloat(document.getElementById('convAmount')?.value) || 0;
      const unit = document.getElementById('convUnit')?.value || 'cup';
      const conv = convertToGrams(ing, amt, unit);
      const res = document.getElementById('convResult');
      if (res) res.textContent = `${amt} ${unit} = ${Math.round(conv.grams * 10) / 10} g`;
    }

    /* SETTINGS & BACKUP */
    function buildSettings() {
      const w = document.getElementById('setWeight'); if (w) w.value = settings.weightKg;
      const pk = document.getElementById('setPerKg'); if (pk) pk.value = settings.proteinPerKg;
      const kc = document.getElementById('setKcal'); if (kc) kc.value = settings.dailyKcal;
      const cb = document.getElementById('setCarbs'); if (cb) cb.value = settings.dailyNetCarbs;
      const out = document.getElementById('setProteinOut');
      if (out) out.innerHTML = `Protein Target: <strong>${protTarget()} g/day</strong> (${settings.weightKg} kg × ${settings.proteinPerKg} g/kg).`;
      renderPackRows();
      renderStoreRows();
    }
    function onSettingChange() {
      settings.weightKg = parseFloat(document.getElementById('setWeight').value) || 0;
      settings.proteinPerKg = parseFloat(document.getElementById('setPerKg').value) || 0;
      settings.dailyKcal = parseFloat(document.getElementById('setKcal').value) || 2000;
      settings.dailyNetCarbs = parseFloat(document.getElementById('setCarbs').value) || 50;
      const out = document.getElementById('setProteinOut');
      if (out) out.innerHTML = `Protein Target: <strong>${protTarget()} g/day</strong> (${settings.weightKg} kg × ${settings.proteinPerKg} g/kg).`;
      updateCustomTotals();
      saveState();
    }

    function renderPackRows() {
      const wrap = document.getElementById('packRows'); if (!wrap) return;
      const keys = Object.keys(packSizes);
      wrap.innerHTML = keys.length ? keys.map(k => `<div class="pack-row"><input class="search pk-name" value="${k}"><input class="search pk-size" type="number" value="${packSizes[k].size}"><select class="slot-select pk-unit"><option value="g">g</option><option value="ml">ml</option><option value="count">count</option></select><button class="x-btn pk-del">×</button></div>`).join('') : '<p class="muted tiny">No pack sizes defined.</p>';
      wrap.querySelectorAll('.pk-del').forEach(b => b.addEventListener('click', e => { e.target.parentElement.remove(); commitPackRows(); }));
    }
    function commitPackRows() {
      packSizes = {};
      document.querySelectorAll('#packRows .pack-row').forEach(row => {
        const n = canon(row.querySelector('.pk-name').value.trim());
        const s = parseFloat(row.querySelector('.pk-size').value) || 0;
        const u = row.querySelector('.pk-unit').value;
        if (n && s) packSizes[n] = { size: s, unit: u };
      });
      saveState();
    }
    function renderStoreRows() {
      const wrap = document.getElementById('storeRows'); if (!wrap) return;
      const keys = Object.keys(stores);
      wrap.innerHTML = keys.length ? keys.map(k => `<div class="store-row"><input class="search st-name" value="${k}"><input class="search st-val" value="${stores[k]}"><button class="x-btn st-del">×</button></div>`).join('') : '<p class="muted tiny">No store notes.</p>';
      wrap.querySelectorAll('.st-del').forEach(b => b.addEventListener('click', e => { e.target.parentElement.remove(); commitStoreRows(); }));
    }
    function commitStoreRows() {
      stores = {};
      document.querySelectorAll('#storeRows .store-row').forEach(row => {
        const n = canon(row.querySelector('.st-name').value.trim());
        const v = row.querySelector('.st-val').value.trim();
        if (n && v) stores[n] = v;
      });
      saveState();
    }

    /* BACKUP EXPORT & IMPORT */
    function exportBackup() {
      const data = JSON.stringify({ v: 2, custom, shopping, customRecipes, settings, stock, packSizes, stores, ticked, meta, customIngredients }, null, 2);
      const fn = 'keto-planner-backup-' + new Date().toISOString().slice(0, 10) + '.json';
      if (window.Android && window.Android.shareOrSave) {
        window.Android.shareOrSave(data, fn);
        const m = document.getElementById('ioMsg'); if (m) { m.textContent = 'Backup exported.'; m.className = 'tiny good'; }
        return;
      }
      const blob = new Blob([data], { type: 'application/json' });
      const a = document.createElement('a'); a.href = URL.createObjectURL(blob);
      a.download = fn;
      document.body.appendChild(a); a.click(); a.remove();
      setTimeout(() => URL.revokeObjectURL(a.href), 1000);
      const m = document.getElementById('ioMsg'); if (m) { m.textContent = 'Backup downloaded.'; m.className = 'tiny good'; }
    }

    function importBackup(file) {
      const m = document.getElementById('ioMsg');
      const reader = new FileReader();
      reader.onload = () => {
        try {
          const d = JSON.parse(reader.result);
          if (d.custom) custom = d.custom;
          if (d.shopping) shopping = d.shopping;
          if (Array.isArray(d.customRecipes)) customRecipes = d.customRecipes;
          if (d.settings) settings = Object.assign({}, DEFAULT_SETTINGS, d.settings);
          if (d.stock) stock = d.stock;
          if (d.packSizes) packSizes = d.packSizes;
          if (d.stores) stores = d.stores;
          if (d.customIngredients) customIngredients = d.customIngredients;
          applyCustomIngredients();
          rebuildMap();
          saveState();
          buildCustom();
          buildRecipeList();
          renderShopping();
          buildMacros();
          buildSettings();
          renderStock();
          if (m) { m.textContent = 'Backup restored!'; m.className = 'tiny good'; }
        } catch (e) {
          if (m) { m.textContent = 'Invalid backup file.'; m.className = 'tiny bad'; }
        }
      };
      reader.readAsText(file);
    }

    /* INITIALIZATION & EVENT BINDINGS */
    document.addEventListener('DOMContentLoaded', () => {
      // Setup Tab Switchers
      document.querySelectorAll('[data-tab-btn]').forEach(btn => btn.addEventListener('click', () => switchTab(btn.dataset.tabBtn)));
      document.getElementById('appBackBtn').addEventListener('click', () => switchTab('home'));

      // Stock Tab Switcher
      document.querySelectorAll('.stock-tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
          document.querySelectorAll('.stock-tab-btn').forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          currentStockTab = btn.dataset.stockTab;
          renderStock();
        });
      });

      // Stock Filter Chips
      document.querySelectorAll('.stock-filter-chip').forEach(chip => {
        chip.addEventListener('click', () => {
          document.querySelectorAll('.stock-filter-chip').forEach(c => c.classList.remove('active'));
          chip.classList.add('active');
          currentStockFilter = chip.dataset.stockFilter;
          renderStock();
        });
      });

      // Stock Actions
      document.getElementById('stockAddBtn')?.addEventListener('click', addStockItem);
      document.getElementById('stockAddInput')?.addEventListener('keydown', e => { if (e.key === 'Enter') addStockItem(); });
      document.getElementById('stockSearch')?.addEventListener('input', renderStock);
      document.getElementById('stockMissingToShopBtn')?.addEventListener('click', addMissingStockToShopping);
      document.getElementById('stockResetBtn')?.addEventListener('click', () => {
        if (confirm('Restore standard keto staples to stock?')) {
          delete SAVED.stock;
          location.reload();
        }
      });

      // Recipes Sort Rule
      document.getElementById('sortRule')?.addEventListener('change', e => { currentSort = e.target.value; buildRecipeList(); });
      ['recipeSearch', 'filterBreakfast', 'filterMain', 'filterSnack', 'fProtein', 'fCarbs', 'fInclude', 'fExclude'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.addEventListener(el.type === 'search' || el.type === 'range' ? 'input' : 'change', () => {
          if (id === 'fProtein') document.getElementById('fProteinV').textContent = el.value + ' g';
          if (id === 'fCarbs') document.getElementById('fCarbsV').textContent = el.value + ' g';
          buildRecipeList();
        });
      });
      document.getElementById('fClear')?.addEventListener('click', () => {
        document.getElementById('fProtein').value = 0;
        document.getElementById('fCarbs').value = 30;
        document.getElementById('fInclude').value = '';
        document.getElementById('fExclude').value = '';
        buildRecipeList();
      });

      // Macro Sort Chips
      document.querySelectorAll('[data-msort]').forEach(chip => {
        chip.addEventListener('click', () => {
          document.querySelectorAll('[data-msort]').forEach(c => c.classList.remove('active'));
          chip.classList.add('active');
          macroSortCol = chip.dataset.msort;
          renderMacros();
        });
      });
      document.getElementById('macroSearch')?.addEventListener('input', renderMacros);
      document.getElementById('ingAddBtn')?.addEventListener('click', saveCustomIngredient);

      // Unit Converter
      ['convIngredient', 'convAmount', 'convUnit'].forEach(id => document.getElementById(id)?.addEventListener('input', runConvert));

      // Planner Buttons
      document.getElementById('clearAllPlannerBtn')?.addEventListener('click', clearAllPlanner);
      document.getElementById('shopDaysBtn')?.addEventListener('click', () => {
        const lo = Math.min(parseInt(document.getElementById('shopFrom').value, 10), parseInt(document.getElementById('shopTo').value, 10));
        const hi = Math.max(parseInt(document.getElementById('shopFrom').value, 10), parseInt(document.getElementById('shopTo').value, 10));
        const sv = parseInt(document.getElementById('shopServings').value, 10) || 1;
        const n = addDaysToShopping(lo, hi, sv);
        const m = document.getElementById('shopDaysMsg');
        if (m) m.textContent = `Added ${n} meal items to list!`;
      });

      // Shopping Buttons
      document.getElementById('clearShoppingBtn')?.addEventListener('click', clearShopping);
      document.getElementById('copyShoppingBtn')?.addEventListener('click', () => {
        const txt = shoppingText();
        if (window.Android && window.Android.copyToClipboard) { window.Android.copyToClipboard(txt); }
        else if (navigator.clipboard) { navigator.clipboard.writeText(txt); }
      });

      // Builder Buttons
      document.getElementById('builderAddRow')?.addEventListener('click', addBuilderRow);
      document.getElementById('builderSave')?.addEventListener('click', saveBuilderRecipe);

      // Settings Inputs
      ['setWeight', 'setPerKg', 'setKcal', 'setCarbs'].forEach(id => document.getElementById(id)?.addEventListener('input', onSettingChange));
      document.getElementById('packAddBtn')?.addEventListener('click', () => {
        document.getElementById('packRows').insertAdjacentHTML('beforeend', `<div class="pack-row"><input class="search pk-name" placeholder="Name"><input class="search pk-size" type="number" placeholder="Size"><select class="slot-select pk-unit"><option value="g">g</option><option value="ml">ml</option><option value="count">count</option></select><button class="x-btn pk-del">×</button></div>`);
        renderPackRows();
      });
      document.getElementById('storeAddBtn')?.addEventListener('click', () => {
        document.getElementById('storeRows').insertAdjacentHTML('beforeend', `<div class="store-row"><input class="search st-name" placeholder="Ingredient"><input class="search st-val" placeholder="Store"><button class="x-btn st-del">×</button></div>`);
        renderStoreRows();
      });

      // Backup & Print
      document.getElementById('exportBtn')?.addEventListener('click', exportBackup);
      document.getElementById('importFile')?.addEventListener('change', e => { if (e.target.files && e.target.files[0]) importBackup(e.target.files[0]); e.target.value = ''; });
      document.getElementById('printBtn')?.addEventListener('click', () => {
        if (window.Android && window.Android.print) { window.Android.print(); }
        else { window.print(); }
      });

      // Theme toggle
      const themeBtn = document.querySelector('[data-theme-toggle]');
      let curTheme = matchMedia('(prefers-color-scheme:dark)').matches ? 'dark' : 'light';
      document.documentElement.setAttribute('data-theme', curTheme);
      themeBtn?.addEventListener('click', () => {
        curTheme = curTheme === 'dark' ? 'light' : 'dark';
        document.documentElement.setAttribute('data-theme', curTheme);
        localStorage.setItem('ketoTheme', curTheme);
        if (window.Android && window.Android.setNavTheme) window.Android.setNavTheme(curTheme === 'dark');
      });

      // Initialize all sub-views
      (function() {
        const sf = document.getElementById('shopFrom'), st = document.getElementById('shopTo');
        const pf = document.getElementById('prepFrom'), pt = document.getElementById('prepTo');
        if (sf && st) {
          sf.innerHTML = DAYS.map((d, i) => `<option value="${i}">${d}</option>`).join('');
          st.innerHTML = DAYS.map((d, i) => `<option value="${i}" ${i === 2 ? 'selected' : ''}>${d}</option>`).join('');
        }
        if (pf && pt) {
          pf.innerHTML = DAYS.map((d, i) => `<option value="${i}">${d}</option>`).join('');
          pt.innerHTML = DAYS.map((d, i) => `<option value="${i}" ${i === 2 ? 'selected' : ''}>${d}</option>`).join('');
        }
      })();

      buildPlannerDayPills();
      buildCustom();
      buildRecipeList();
      renderShopping();
      buildMacros();
      buildConvertTab();
      buildSettings();
      renderStock();
      addBuilderRow();
      switchTab('home');
    });

    window.addEventListener('beforeunload', saveState);
  </script>
</body>
</html>
'@

[System.IO.File]::WriteAllText($srcPath, $html, [System.Text.Encoding]::UTF8)
Write-Output "Successfully wrote updated index.html with size: $( (Get-Item $srcPath).Length ) bytes"
