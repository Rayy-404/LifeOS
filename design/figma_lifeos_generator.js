/**
 * ==============================================================================
 * LifeOS Figma Design Generator Script
 * Theme & Spec: C:\Users\Rey\Documents\Projects\lifeOS\planning\DESIGN.md
 * ==============================================================================
 * 
 * Cara Penggunaan di Figma:
 * 1. Buka dokumen Figma (file baru atau file yang sudah ada).
 * 2. Buka Dev Console Figma:
 *    - Di Figma Desktop: Tekan Ctrl+Shift+I (atau Menu > Plugins > Development > Open Console)
 *    - ATAU gunakan plugin "Scripter" di Figma Community.
 * 3. Copy seluruh kode di file ini, paste ke Console/Scripter, lalu tekan Enter / Run.
 * 4. Skrip ini akan secara otomatis:
 *    - Mendaftarkan Color Styles resmi LifeOS (Design Tokens).
 *    - Menggambar 5 Mobile Frames (390 x 844 px) dengan Auto-Layout:
 *      • [S-04] Home / Dashboard (Ring 72%, 2x2 stats, Quick actions, Agenda, Habits, Tasks)
 *      • [S-05] My Tasks (Filter chips, Priority cards, Overdue alert)
 *      • [S-07] Calendar & Timeline (7-day strip, Class schedule timeline)
 *      • [S-08] Habits & Streak (Navy hero banner, Habit cards, 7-dot weekly tracker)
 *      • [S-10] Statistics & Profile (Dark navy header, 85% ring, Donut breakdown, Menu)
 * ==============================================================================
 */

(async function generateLifeOSDesign() {
  console.log("🚀 Starting LifeOS Figma Design Generator...");

  // 1. Color Palette Tokens (Hex to RGB 0-1)
  const hexToRgb = (hex) => {
    const c = hex.replace('#', '');
    return {
      r: parseInt(c.substring(0, 2), 16) / 255,
      g: parseInt(c.substring(2, 4), 16) / 255,
      b: parseInt(c.substring(4, 6), 16) / 255
    };
  };

  const COLORS = {
    primary: hexToRgb('#5B5BF6'),
    primaryDark: hexToRgb('#4338CA'),
    primarySoft: hexToRgb('#ECEBFF'),
    background: hexToRgb('#F4F5FC'),
    surface: hexToRgb('#FFFFFF'),
    surfaceMuted: hexToRgb('#F1F2F8'),
    navy: hexToRgb('#1E2140'),
    textPrimary: hexToRgb('#151833'),
    textSecondary: hexToRgb('#8A8FA8'),
    divider: hexToRgb('#EEF0F6'),

    success: hexToRgb('#22C55E'),
    successBg: hexToRgb('#E8F8EE'),
    warning: hexToRgb('#F59E0B'),
    warningBg: hexToRgb('#FEF3E2'),
    error: hexToRgb('#EF4444'),
    errorBg: hexToRgb('#FDECEC'),
    info: hexToRgb('#3B82F6'),
    infoBg: hexToRgb('#E8F0FE'),

    violet: hexToRgb('#8B5CF6'),
    violetBg: hexToRgb('#F1ECFE'),
    green: hexToRgb('#10B981'),
    greenBg: hexToRgb('#E6F7F1'),
    orange: hexToRgb('#F97316'),
    orangeBg: hexToRgb('#FEF0E6'),
    pink: hexToRgb('#EC4899'),
    pinkBg: hexToRgb('#FDEBF4'),
    sky: hexToRgb('#0EA5E9'),
    skyBg: hexToRgb('#E6F5FC')
  };

  // 2. Load Fonts (Plus Jakarta Sans or fallback to Inter)
  let fontRegular = { family: "Inter", style: "Regular" };
  let fontBold = { family: "Inter", style: "Bold" };
  let fontSemiBold = { family: "Inter", style: "Semi Bold" };

  try {
    await figma.loadFontAsync({ family: "Plus Jakarta Sans", style: "Regular" });
    await figma.loadFontAsync({ family: "Plus Jakarta Sans", style: "SemiBold" });
    await figma.loadFontAsync({ family: "Plus Jakarta Sans", style: "Bold" });
    fontRegular = { family: "Plus Jakarta Sans", style: "Regular" };
    fontSemiBold = { family: "Plus Jakarta Sans", style: "SemiBold" };
    fontBold = { family: "Plus Jakarta Sans", style: "Bold" };
  } catch (e) {
    console.warn("Plus Jakarta Sans not found locally, falling back to Inter font.");
    await figma.loadFontAsync(fontRegular);
    await figma.loadFontAsync(fontSemiBold);
    await figma.loadFontAsync(fontBold);
  }

  // Helper: Create Text Node
  function createText(text, font, size, color, width = null) {
    const node = figma.createText();
    node.fontName = font;
    node.characters = text;
    node.fontSize = size;
    node.fills = [{ type: 'SOLID', color: color }];
    if (width) {
      node.textAutoResize = 'HEIGHT';
      node.resize(width, node.height);
    }
    return node;
  }

  // Helper: Create Card Frame with Soft Shadow
  function createCard(width = 350, bg = COLORS.surface, radius = 20) {
    const card = figma.createFrame();
    card.name = "Card";
    card.resize(width, 60);
    card.cornerRadius = radius;
    card.fills = [{ type: 'SOLID', color: bg }];
    card.effects = [{
      type: 'DROP_SHADOW',
      color: { r: 91/255, g: 91/255, b: 246/255, a: 0.06 },
      offset: { x: 0, y: 4 },
      radius: 16,
      spread: 0,
      visible: true,
      blendMode: 'NORMAL'
    }];
    card.layoutMode = 'VERTICAL';
    card.primaryAxisSizingMode = 'AUTO';
    card.counterAxisSizingMode = 'FIXED';
    card.paddingTop = 16;
    card.paddingBottom = 16;
    card.paddingLeft = 16;
    card.paddingRight = 16;
    card.itemSpacing = 10;
    return card;
  }

  // 3. Create Main Canvas Section / Parent Frames
  let startX = 0;
  const screens = [
    { id: "S-04", title: "Home / Dashboard" },
    { id: "S-05", title: "My Tasks" },
    { id: "S-07", title: "Calendar & Timeline" },
    { id: "S-08", title: "Habits & Streaks" },
    { id: "S-10", title: "Profile & Statistics" }
  ];

  // Helper: Create Standard Base Phone Frame (390 x 844)
  function createPhoneFrame(name, x) {
    const frame = figma.createFrame();
    frame.name = name;
    frame.resize(390, 844);
    frame.x = x;
    frame.y = 0;
    frame.cornerRadius = 40;
    frame.fills = [{ type: 'SOLID', color: COLORS.background }];
    frame.clipsContent = true;

    // Status bar header
    const statusBar = figma.createFrame();
    statusBar.name = "StatusBar";
    statusBar.resize(390, 44);
    statusBar.fills = [];
    statusBar.layoutMode = 'HORIZONTAL';
    statusBar.primaryAxisAlignItems = 'SPACE_BETWEEN';
    statusBar.counterAxisAlignItems = 'CENTER';
    statusBar.paddingLeft = 24;
    statusBar.paddingRight = 24;
    
    const timeText = createText("09:41", fontBold, 13, COLORS.textPrimary);
    const iconsText = createText("📶 🔋", fontRegular, 11, COLORS.textSecondary);
    statusBar.appendChild(timeText);
    statusBar.appendChild(iconsText);
    frame.appendChild(statusBar);

    // Scroll container
    const content = figma.createFrame();
    content.name = "Content";
    content.y = 44;
    content.resize(390, 720);
    content.fills = [];
    content.layoutMode = 'VERTICAL';
    content.paddingLeft = 20;
    content.paddingRight = 20;
    content.paddingTop = 10;
    content.paddingBottom = 90;
    content.itemSpacing = 18;
    frame.appendChild(content);

    // Bottom Navigation Bar
    const navBar = figma.createFrame();
    navBar.name = "BottomNavigation";
    navBar.resize(390, 80);
    navBar.y = 844 - 80;
    navBar.cornerRadius = 24;
    navBar.fills = [{ type: 'SOLID', color: COLORS.surface }];
    navBar.effects = [{
      type: 'DROP_SHADOW',
      color: { r: 91/255, g: 91/255, b: 246/255, a: 0.08 },
      offset: { x: 0, y: -4 },
      radius: 20,
      visible: true,
      blendMode: 'NORMAL'
    }];
    navBar.layoutMode = 'HORIZONTAL';
    navBar.primaryAxisAlignItems = 'SPACE_BETWEEN';
    navBar.counterAxisAlignItems = 'CENTER';
    navBar.paddingLeft = 24;
    navBar.paddingRight = 24;

    const tHome = createText("⌂ Home", fontBold, 11, COLORS.primary);
    const tTasks = createText("✓ Tasks", fontSemiBold, 11, COLORS.textSecondary);
    
    // FAB
    const fab = figma.createFrame();
    fab.name = "CenterFAB";
    fab.resize(52, 52);
    fab.cornerRadius = 26;
    fab.fills = [{ type: 'SOLID', color: COLORS.primary }];
    fab.effects = [{
      type: 'DROP_SHADOW',
      color: { r: 91/255, g: 91/255, b: 246/255, a: 0.35 },
      offset: { x: 0, y: 6 },
      radius: 16,
      visible: true,
      blendMode: 'NORMAL'
    }];
    fab.layoutMode = 'VERTICAL';
    fab.primaryAxisAlignItems = 'CENTER';
    fab.counterAxisAlignItems = 'CENTER';
    const fabPlus = createText("+", fontBold, 24, COLORS.surface);
    fab.appendChild(fabPlus);

    const tCal = createText("📅 Cal", fontSemiBold, 11, COLORS.textSecondary);
    const tHab = createText("⚡ Habits", fontSemiBold, 11, COLORS.textSecondary);

    navBar.appendChild(tHome);
    navBar.appendChild(tTasks);
    navBar.appendChild(fab);
    navBar.appendChild(tCal);
    navBar.appendChild(tHab);
    frame.appendChild(navBar);

    return { frame, content, navBar };
  }

  // ==========================================
  // BUILD SCREEN 1: [S-04] HOME / DASHBOARD
  // ==========================================
  {
    const { frame, content } = createPhoneFrame("[S-04] Home / Dashboard", startX);

    // Header Greeting
    const headerRow = figma.createFrame();
    headerRow.name = "HeaderGreeting";
    headerRow.resize(350, 48);
    headerRow.fills = [];
    headerRow.layoutMode = 'HORIZONTAL';
    headerRow.primaryAxisAlignItems = 'SPACE_BETWEEN';
    headerRow.counterAxisAlignItems = 'CENTER';

    const greetCol = figma.createFrame();
    greetCol.fills = [];
    greetCol.layoutMode = 'VERTICAL';
    greetCol.itemSpacing = 2;
    greetCol.appendChild(createText("GOOD MORNING,", fontSemiBold, 11, COLORS.textSecondary));
    greetCol.appendChild(createText("Rayhan 👋", fontBold, 20, COLORS.textPrimary));

    const avatar = figma.createFrame();
    avatar.resize(40, 40);
    avatar.cornerRadius = 20;
    avatar.fills = [{ type: 'SOLID', color: COLORS.primary }];
    avatar.layoutMode = 'VERTICAL';
    avatar.primaryAxisAlignItems = 'CENTER';
    avatar.counterAxisAlignItems = 'CENTER';
    avatar.appendChild(createText("R", fontBold, 16, COLORS.surface));

    headerRow.appendChild(greetCol);
    headerRow.appendChild(avatar);
    content.appendChild(headerRow);

    // Daily Progress Card (72%)
    const progCard = createCard(350, COLORS.surface, 20);
    progCard.name = "ProgressCard";
    progCard.layoutMode = 'HORIZONTAL';
    progCard.primaryAxisAlignItems = 'SPACE_BETWEEN';
    progCard.counterAxisAlignItems = 'CENTER';

    const progRing = figma.createFrame();
    progRing.resize(60, 60);
    progRing.cornerRadius = 30;
    progRing.fills = [{ type: 'SOLID', color: COLORS.primarySoft }];
    progRing.layoutMode = 'VERTICAL';
    progRing.primaryAxisAlignItems = 'CENTER';
    progRing.counterAxisAlignItems = 'CENTER';
    progRing.appendChild(createText("72%", fontBold, 16, COLORS.primary));

    const progText = figma.createFrame();
    progText.fills = [];
    progText.layoutMode = 'VERTICAL';
    progText.itemSpacing = 4;
    progText.appendChild(createText("Daily Progress", fontBold, 15, COLORS.textPrimary));
    progText.appendChild(createText("4 of 6 tasks done · Keep going!", fontRegular, 12, COLORS.textSecondary, 230));

    progCard.appendChild(progRing);
    progCard.appendChild(progText);
    content.appendChild(progCard);

    // 2x2 Stat Grid Row
    const statGrid = figma.createFrame();
    statGrid.name = "StatGrid2x2";
    statGrid.resize(350, 64);
    statGrid.fills = [];
    statGrid.layoutMode = 'HORIZONTAL';
    statGrid.itemSpacing = 12;

    function makeStatTile(num, label, iconBg, iconColor) {
      const tile = createCard(169, COLORS.surface, 16);
      tile.layoutMode = 'HORIZONTAL';
      tile.counterAxisAlignItems = 'CENTER';
      tile.itemSpacing = 10;
      
      const icon = figma.createFrame();
      icon.resize(36, 36);
      icon.cornerRadius = 12;
      icon.fills = [{ type: 'SOLID', color: iconBg }];
      icon.layoutMode = 'VERTICAL';
      icon.primaryAxisAlignItems = 'CENTER';
      icon.counterAxisAlignItems = 'CENTER';
      icon.appendChild(createText("●", fontBold, 12, iconColor));

      const texts = figma.createFrame();
      texts.fills = [];
      texts.layoutMode = 'VERTICAL';
      texts.appendChild(createText(num, fontBold, 17, COLORS.textPrimary));
      texts.appendChild(createText(label, fontSemiBold, 11, COLORS.textSecondary));

      tile.appendChild(icon);
      tile.appendChild(texts);
      return tile;
    }

    statGrid.appendChild(makeStatTile("12", "Total Tasks", COLORS.infoBg, COLORS.info));
    statGrid.appendChild(makeStatTile("8", "Completed", COLORS.successBg, COLORS.success));
    content.appendChild(statGrid);

    // Today's Agenda
    content.appendChild(createText("Today's Agenda", fontBold, 16, COLORS.textPrimary));
    const agendaCard = createCard(350, COLORS.surface, 18);
    agendaCard.layoutMode = 'HORIZONTAL';
    agendaCard.counterAxisAlignItems = 'CENTER';
    agendaCard.itemSpacing = 14;

    const timeBadge = figma.createFrame();
    timeBadge.resize(60, 44);
    timeBadge.cornerRadius = 10;
    timeBadge.fills = [{ type: 'SOLID', color: COLORS.violetBg }];
    timeBadge.layoutMode = 'VERTICAL';
    timeBadge.primaryAxisAlignItems = 'CENTER';
    timeBadge.counterAxisAlignItems = 'CENTER';
    timeBadge.appendChild(createText("08:00", fontBold, 12, COLORS.violet));

    const agendaInfo = figma.createFrame();
    agendaInfo.fills = [];
    agendaInfo.layoutMode = 'VERTICAL';
    agendaInfo.itemSpacing = 3;
    agendaInfo.appendChild(createText("Operating Systems", fontBold, 14, COLORS.textPrimary));
    agendaInfo.appendChild(createText("08:00–10:00 · Bldg B R.204", fontRegular, 11, COLORS.textSecondary));

    agendaCard.appendChild(timeBadge);
    agendaCard.appendChild(agendaInfo);
    content.appendChild(agendaCard);

    // Today's Habits
    content.appendChild(createText("Today's Habits", fontBold, 16, COLORS.textPrimary));
    const habitCard = createCard(350, COLORS.surface, 18);
    habitCard.layoutMode = 'HORIZONTAL';
    habitCard.primaryAxisAlignItems = 'SPACE_BETWEEN';
    habitCard.counterAxisAlignItems = 'CENTER';

    const hLeft = figma.createFrame();
    hLeft.fills = [];
    hLeft.layoutMode = 'HORIZONTAL';
    hLeft.counterAxisAlignItems = 'CENTER';
    hLeft.itemSpacing = 12;

    const hIcon = figma.createFrame();
    hIcon.resize(40, 40);
    hIcon.cornerRadius = 12;
    hIcon.fills = [{ type: 'SOLID', color: COLORS.greenBg }];
    hIcon.layoutMode = 'VERTICAL';
    hIcon.primaryAxisAlignItems = 'CENTER';
    hIcon.counterAxisAlignItems = 'CENTER';
    hIcon.appendChild(createText("💧", fontRegular, 16, COLORS.green));

    const hText = figma.createFrame();
    hText.fills = [];
    hText.layoutMode = 'VERTICAL';
    hText.itemSpacing = 3;
    hText.appendChild(createText("Drink 2.5L Water", fontBold, 14, COLORS.textPrimary));
    hText.appendChild(createText("🔥 5 days streak", fontSemiBold, 11, COLORS.orange));

    hLeft.appendChild(hIcon);
    hLeft.appendChild(hText);

    const checkBtn = figma.createFrame();
    checkBtn.resize(32, 32);
    checkBtn.cornerRadius = 16;
    checkBtn.fills = [{ type: 'SOLID', color: COLORS.success }];
    checkBtn.layoutMode = 'VERTICAL';
    checkBtn.primaryAxisAlignItems = 'CENTER';
    checkBtn.counterAxisAlignItems = 'CENTER';
    checkBtn.appendChild(createText("✓", fontBold, 14, COLORS.surface));

    habitCard.appendChild(hLeft);
    habitCard.appendChild(checkBtn);
    content.appendChild(habitCard);

    startX += 440;
  }

  // ==========================================
  // BUILD SCREEN 2: [S-05] MY TASKS
  // ==========================================
  {
    const { frame, content } = createPhoneFrame("[S-05] My Tasks", startX);

    // Title & Filter
    content.appendChild(createText("My Tasks", fontBold, 24, COLORS.textPrimary));

    // Search bar
    const searchBar = figma.createFrame();
    searchBar.resize(350, 44);
    searchBar.cornerRadius = 14;
    searchBar.fills = [{ type: 'SOLID', color: COLORS.surfaceMuted }];
    searchBar.layoutMode = 'HORIZONTAL';
    searchBar.counterAxisAlignItems = 'CENTER';
    searchBar.paddingLeft = 14;
    searchBar.itemSpacing = 8;
    searchBar.appendChild(createText("🔍 Search tasks, deadlines...", fontRegular, 12, COLORS.textSecondary));
    content.appendChild(searchBar);

    // Filter Chips Row
    const chipsRow = figma.createFrame();
    chipsRow.fills = [];
    chipsRow.layoutMode = 'HORIZONTAL';
    chipsRow.itemSpacing = 8;

    function makeChip(label, active = false) {
      const chip = figma.createFrame();
      chip.cornerRadius = 999;
      chip.paddingTop = 6;
      chip.paddingBottom = 6;
      chip.paddingLeft = 14;
      chip.paddingRight = 14;
      chip.fills = [{ type: 'SOLID', color: active ? COLORS.primary : COLORS.surface }];
      chip.appendChild(createText(label, fontBold, 12, active ? COLORS.surface : COLORS.textSecondary));
      return chip;
    }
    chipsRow.appendChild(makeChip("All (12)", true));
    chipsRow.appendChild(makeChip("Today (4)"));
    chipsRow.appendChild(makeChip("Upcoming"));
    chipsRow.appendChild(makeChip("Completed"));
    content.appendChild(chipsRow);

    // Helper: Task Item Card
    function makeTaskCard(title, time, priority, pColor, pBg, isDone = false) {
      const card = createCard(350, COLORS.surface, 16);
      card.layoutMode = 'HORIZONTAL';
      card.primaryAxisAlignItems = 'SPACE_BETWEEN';
      card.counterAxisAlignItems = 'CENTER';

      const left = figma.createFrame();
      left.fills = [];
      left.layoutMode = 'HORIZONTAL';
      left.counterAxisAlignItems = 'CENTER';
      left.itemSpacing = 12;

      const check = figma.createFrame();
      check.resize(22, 22);
      check.cornerRadius = 11;
      check.fills = [{ type: 'SOLID', color: isDone ? COLORS.success : COLORS.surface }];
      check.strokes = [{ type: 'SOLID', color: isDone ? COLORS.success : pColor }];
      check.strokeWeight = 2;
      check.layoutMode = 'VERTICAL';
      check.primaryAxisAlignItems = 'CENTER';
      check.counterAxisAlignItems = 'CENTER';
      if (isDone) check.appendChild(createText("✓", fontBold, 12, COLORS.surface));

      const texts = figma.createFrame();
      texts.fills = [];
      texts.layoutMode = 'VERTICAL';
      texts.itemSpacing = 3;
      texts.appendChild(createText(title, fontSemiBold, 13.5, isDone ? COLORS.textSecondary : COLORS.textPrimary, 210));
      texts.appendChild(createText(time, fontRegular, 11, COLORS.textSecondary));

      left.appendChild(check);
      left.appendChild(texts);

      const pill = figma.createFrame();
      pill.cornerRadius = 999;
      pill.paddingTop = 4;
      pill.paddingBottom = 4;
      pill.paddingLeft = 10;
      pill.paddingRight = 10;
      pill.fills = [{ type: 'SOLID', color: pBg }];
      pill.appendChild(createText(priority, fontBold, 11, pColor));

      card.appendChild(left);
      card.appendChild(pill);
      return card;
    }

    content.appendChild(makeTaskCard("Submit OS Assignment 2", "Due Today · 11:59 PM", "High", COLORS.error, COLORS.errorBg));
    content.appendChild(makeTaskCard("Prepare LifeOS Design Specs", "Today · 04:00 PM", "Medium", COLORS.warning, COLORS.warningBg));
    content.appendChild(makeTaskCard("Clean Architecture Chapter 4", "Tomorrow · 08:00 PM", "Low", COLORS.info, COLORS.infoBg));
    content.appendChild(makeTaskCard("Setup Database & Migrations", "Completed Yesterday", "Done", COLORS.success, COLORS.successBg, true));

    startX += 440;
  }

  // ==========================================
  // BUILD SCREEN 3: [S-07] CALENDAR
  // ==========================================
  {
    const { frame, content } = createPhoneFrame("[S-07] Calendar", startX);

    content.appendChild(createText("October 2026", fontBold, 22, COLORS.textPrimary));

    // 7-Day Strip
    const strip = figma.createFrame();
    strip.name = "WeekStrip";
    strip.resize(350, 70);
    strip.fills = [];
    strip.layoutMode = 'HORIZONTAL';
    strip.primaryAxisAlignItems = 'SPACE_BETWEEN';

    const days = [
      { d: "Mon", n: "21" },
      { d: "Tue", n: "22" },
      { d: "Wed", n: "23", active: true },
      { d: "Thu", n: "24" },
      { d: "Fri", n: "25" }
    ];

    days.forEach(item => {
      const col = figma.createFrame();
      col.resize(58, 68);
      col.cornerRadius = 14;
      col.fills = [{ type: 'SOLID', color: item.active ? COLORS.primary : COLORS.surface }];
      col.layoutMode = 'VERTICAL';
      col.primaryAxisAlignItems = 'CENTER';
      col.counterAxisAlignItems = 'CENTER';
      col.itemSpacing = 4;
      col.appendChild(createText(item.d, fontSemiBold, 11, item.active ? COLORS.surface : COLORS.textSecondary));
      col.appendChild(createText(item.n, fontBold, 16, item.active ? COLORS.surface : COLORS.textPrimary));
      strip.appendChild(col);
    });
    content.appendChild(strip);

    // Schedule Timeline Cards
    content.appendChild(createText("Timeline Schedule", fontBold, 16, COLORS.textPrimary));

    function makeTimelineItem(time, label, title, place, barColor, bg) {
      const row = figma.createFrame();
      row.resize(350, 68);
      row.fills = [];
      row.layoutMode = 'HORIZONTAL';
      row.counterAxisAlignItems = 'CENTER';
      row.itemSpacing = 12;

      const timeBox = createText(time, fontBold, 12, COLORS.textSecondary);
      timeBox.resize(46, 20);

      const card = createCard(290, bg, 14);
      card.layoutMode = 'VERTICAL';
      card.itemSpacing = 2;
      card.appendChild(createText(label.toUpperCase(), fontBold, 10, barColor));
      card.appendChild(createText(title, fontBold, 13.5, COLORS.textPrimary));
      card.appendChild(createText(place, fontRegular, 11, COLORS.textSecondary));

      row.appendChild(timeBox);
      row.appendChild(card);
      return row;
    }

    content.appendChild(makeTimelineItem("08:00", "Class", "Operating Systems", "08:00 - 10:00 · Bldg B R.204", COLORS.violet, COLORS.violetBg));
    content.appendChild(makeTimelineItem("11:00", "Deadline", "AI Systems Project Pitch", "11:00 - 12:30 · Meet", COLORS.orange, COLORS.orangeBg));
    content.appendChild(makeTimelineItem("14:00", "Habit", "Campus Gym Workout", "14:00 - 15:30 · Sports Center", COLORS.green, COLORS.greenBg));

    startX += 440;
  }

  // ==========================================
  // BUILD SCREEN 4: [S-08] HABITS
  // ==========================================
  {
    const { frame, content } = createPhoneFrame("[S-08] Habits", startX);

    content.appendChild(createText("My Habits", fontBold, 24, COLORS.textPrimary));

    // Hero Navy Banner
    const banner = figma.createFrame();
    banner.name = "HabitHeroBanner";
    banner.resize(350, 96);
    banner.cornerRadius = 20;
    banner.fills = [{ type: 'SOLID', color: COLORS.navy }];
    banner.layoutMode = 'VERTICAL';
    banner.paddingLeft = 18;
    banner.paddingTop = 18;
    banner.itemSpacing = 6;
    banner.appendChild(createText("Build Better Habits", fontBold, 17, COLORS.surface));
    banner.appendChild(createText("Small steps every day lead to big results.", fontRegular, 12, COLORS.primarySoft, 250));
    content.appendChild(banner);

    // Habit Item Card with 7-dots
    function makeHabitFullCard(name, streak, weekStat, iconChar, iconColor, iconBg) {
      const card = createCard(350, COLORS.surface, 18);
      card.layoutMode = 'VERTICAL';
      card.itemSpacing = 12;

      const top = figma.createFrame();
      top.fills = [];
      top.layoutMode = 'HORIZONTAL';
      top.primaryAxisAlignItems = 'SPACE_BETWEEN';
      top.counterAxisAlignItems = 'CENTER';

      const left = figma.createFrame();
      left.fills = [];
      left.layoutMode = 'HORIZONTAL';
      left.counterAxisAlignItems = 'CENTER';
      left.itemSpacing = 12;

      const ic = figma.createFrame();
      ic.resize(40, 40);
      ic.cornerRadius = 12;
      ic.fills = [{ type: 'SOLID', color: iconBg }];
      ic.layoutMode = 'VERTICAL';
      ic.primaryAxisAlignItems = 'CENTER';
      ic.counterAxisAlignItems = 'CENTER';
      ic.appendChild(createText(iconChar, fontRegular, 16, iconColor));

      const texts = figma.createFrame();
      texts.fills = [];
      texts.layoutMode = 'VERTICAL';
      texts.itemSpacing = 2;
      texts.appendChild(createText(name, fontBold, 14, COLORS.textPrimary));
      texts.appendChild(createText(`${streak} · ${weekStat}`, fontSemiBold, 11, COLORS.orange));

      left.appendChild(ic);
      left.appendChild(texts);

      const chk = figma.createFrame();
      chk.resize(32, 32);
      chk.cornerRadius = 16;
      chk.fills = [{ type: 'SOLID', color: COLORS.success }];
      chk.layoutMode = 'VERTICAL';
      chk.primaryAxisAlignItems = 'CENTER';
      chk.counterAxisAlignItems = 'CENTER';
      chk.appendChild(createText("✓", fontBold, 14, COLORS.surface));

      top.appendChild(left);
      top.appendChild(chk);
      card.appendChild(top);

      // 7-dot weekly row
      const dotsRow = figma.createFrame();
      dotsRow.resize(318, 20);
      dotsRow.fills = [];
      dotsRow.layoutMode = 'HORIZONTAL';
      dotsRow.primaryAxisAlignItems = 'SPACE_BETWEEN';
      dotsRow.counterAxisAlignItems = 'CENTER';

      ["M","T","W","T","F","S","S"].forEach((d, idx) => {
        const dot = figma.createFrame();
        dot.resize(14, 14);
        dot.cornerRadius = 7;
        dot.fills = [{ type: 'SOLID', color: idx < 4 ? COLORS.green : COLORS.surfaceMuted }];
        dotsRow.appendChild(dot);
      });
      card.appendChild(dotsRow);

      return card;
    }

    content.appendChild(makeHabitFullCard("Read 20 Pages", "🔥 7 days streak", "5/7 this week", "📖", COLORS.sky, COLORS.skyBg));
    content.appendChild(makeHabitFullCard("Workout & Stretch", "🔥 3 days streak", "3/4 this week", "💪", COLORS.green, COLORS.greenBg));

    startX += 440;
  }

  // ==========================================
  // BUILD SCREEN 5: [S-10] PROFILE & STATS
  // ==========================================
  {
    const { frame, content } = createPhoneFrame("[S-10] Profile & Stats", startX);

    // Profile Navy Card
    const profCard = figma.createFrame();
    profCard.name = "ProfileNavyCard";
    profCard.resize(350, 140);
    profCard.cornerRadius = 22;
    profCard.fills = [{ type: 'SOLID', color: COLORS.navy }];
    profCard.layoutMode = 'VERTICAL';
    profCard.paddingTop = 16;
    profCard.paddingBottom = 16;
    profCard.paddingLeft = 16;
    profCard.paddingRight = 16;
    profCard.itemSpacing = 14;

    const pTop = figma.createFrame();
    pTop.fills = [];
    pTop.layoutMode = 'HORIZONTAL';
    pTop.counterAxisAlignItems = 'CENTER';
    pTop.itemSpacing = 12;

    const pAv = figma.createFrame();
    pAv.resize(46, 46);
    pAv.cornerRadius = 23;
    pAv.fills = [{ type: 'SOLID', color: COLORS.primary }];
    pAv.layoutMode = 'VERTICAL';
    pAv.primaryAxisAlignItems = 'CENTER';
    pAv.counterAxisAlignItems = 'CENTER';
    pAv.appendChild(createText("R", fontBold, 18, COLORS.surface));

    const pMeta = figma.createFrame();
    pMeta.fills = [];
    pMeta.layoutMode = 'VERTICAL';
    pMeta.appendChild(createText("Rayhan Maulana", fontBold, 16, COLORS.surface));
    pMeta.appendChild(createText("rayhan@student.univ.ac.id", fontRegular, 11, COLORS.textSecondary));

    pTop.appendChild(pAv);
    pTop.appendChild(pMeta);
    profCard.appendChild(pTop);

    // 3 stats row
    const pStats = figma.createFrame();
    pStats.resize(318, 44);
    pStats.cornerRadius = 12;
    pStats.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1, a: 0.1 } }];
    pStats.layoutMode = 'HORIZONTAL';
    pStats.primaryAxisAlignItems = 'SPACE_AROUND';
    pStats.counterAxisAlignItems = 'CENTER';

    function makeMiniStat(num, lbl) {
      const b = figma.createFrame();
      b.fills = [];
      b.layoutMode = 'VERTICAL';
      b.counterAxisAlignItems = 'CENTER';
      b.appendChild(createText(num, fontBold, 14, COLORS.surface));
      b.appendChild(createText(lbl, fontSemiBold, 10, COLORS.textSecondary));
      return b;
    }
    pStats.appendChild(makeMiniStat("12", "Tasks"));
    pStats.appendChild(makeMiniStat("5", "Habits"));
    pStats.appendChild(makeMiniStat("7 🔥", "Streak"));
    profCard.appendChild(pStats);

    content.appendChild(profCard);

    // Productivity Score Card (85%)
    const scoreCard = createCard(350, COLORS.surface, 18);
    scoreCard.layoutMode = 'HORIZONTAL';
    scoreCard.primaryAxisAlignItems = 'SPACE_BETWEEN';
    scoreCard.counterAxisAlignItems = 'CENTER';

    const sLeft = figma.createFrame();
    sLeft.fills = [];
    sLeft.layoutMode = 'VERTICAL';
    sLeft.itemSpacing = 2;
    sLeft.appendChild(createText("PRODUCTIVITY SCORE", fontBold, 10, COLORS.textSecondary));
    sLeft.appendChild(createText("85%", fontBold, 24, COLORS.textPrimary));
    sLeft.appendChild(createText("↑ 12% vs last week", fontBold, 11, COLORS.success));

    const sRing = figma.createFrame();
    sRing.resize(54, 54);
    sRing.cornerRadius = 27;
    sRing.fills = [{ type: 'SOLID', color: COLORS.successBg }];
    sRing.layoutMode = 'VERTICAL';
    sRing.primaryAxisAlignItems = 'CENTER';
    sRing.counterAxisAlignItems = 'CENTER';
    sRing.appendChild(createText("85%", fontBold, 14, COLORS.success));

    scoreCard.appendChild(sLeft);
    scoreCard.appendChild(sRing);
    content.appendChild(scoreCard);

    // Menu list
    const menu = createCard(350, COLORS.surface, 18);
    menu.layoutMode = 'VERTICAL';
    menu.itemSpacing = 12;
    menu.appendChild(createText("🔔 Reminders (2 pending)", fontSemiBold, 13, COLORS.textPrimary));
    menu.appendChild(createText("🎨 Appearance: Light Mode", fontSemiBold, 13, COLORS.textPrimary));
    menu.appendChild(createText("📍 Timezone: Asia/Jakarta", fontSemiBold, 13, COLORS.textPrimary));
    content.appendChild(menu);

    startX += 440;
  }

  // Zoom to fit newly generated frames
  figma.viewport.scrollAndZoomIntoView(figma.currentPage.children);

  console.log("✅ Berhasil membuat 5 Screen LifeOS Mobile Design di Figma!");
  figma.notify("🎉 LifeOS Design Frames berhasil digenerate di canvas!");
})();
