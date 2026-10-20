# DESIGN.md — LifeOS UI/UX Design System

> Design specification for **LifeOS** (Personal Productivity & Academic OS for Android). Intended for AI UI generation (Google Stitch), Figma, and Flutter Material 3 implementation.
>
> **Visual reference:** `design/references/ui-reference-01.png` — soft-lavender productivity dashboard style (white rounded cards, circular progress rings, pastel icon tiles, center FAB in bottom nav, dark navy profile header).

---

## 1. Product Identity & Design Principles

### Product Overview
- **Product Name:** LifeOS
- **Platform:** Android Mobile (Material 3 custom theme, 360dp–430dp width, design frame 390x844)
- **Primary Persona:** University students and young professionals juggling lecture schedules, assignment deadlines, and daily habits.
- **Design Mood:** *"Soft Friendly Productivity"* — airy, calm, optimistic. Soft lavender background, floating white cards, generous rounded corners, pastel accent tiles, and one confident indigo-violet primary color.

### Core Design Rules
1. **Scannable in 3 Seconds:** The user must see today's progress (%), pending/overdue tasks, today's agenda, and habit check-ins at a glance. Use a progress ring card, a 2x2 stat grid, and short lists — never long paragraphs.
2. **One-Tap Execution:** Checking off a task, checking in a habit, and quick-add (center FAB) must be one tap, directly from cards.
3. **Soft, Not Decorative:** Depth comes from soft shadows and rounded white cards on a tinted background — not from borders, heavy gradients, or glassmorphism. Illustrations are allowed ONLY on onboarding/auth screens and one small hero banner.

---

## 2. Color Palette

### Brand & Neutrals (Light Mode — Default)
| Token | Hex | Usage |
| :--- | :--- | :--- |
| `primary` | `#5B5BF6` (Indigo-Violet) | Center FAB, active nav icon, selected chip, progress ring, primary buttons, selected calendar day |
| `primaryDark` | `#4338CA` | Pressed state, gradient end on hero banner |
| `primarySoft` | `#ECEBFF` | Progress ring track, selected tab background, Daily Progress card tint |
| `background` | `#F4F5FC` (Soft Lavender) | Screen scaffold background |
| `surface` | `#FFFFFF` | Cards, bottom sheets, bottom navigation bar |
| `surfaceMuted` | `#F1F2F8` | Search field, inactive chips, input fields |
| `navy` | `#1E2140` | Profile header, primary dark CTA ("Get Started"), hero banner base |
| `textPrimary` | `#151833` | Headings, titles, metric numbers |
| `textSecondary` | `#8A8FA8` | Subtitles, timestamps, meta labels |
| `divider` | `#EEF0F6` | Hairline list dividers (use sparingly) |

### Semantic Colors (Solid + Pastel Background Pair)
| Role | Solid | Pastel BG | Usage |
| :--- | :--- | :--- | :--- |
| Success / Done | `#22C55E` | `#E8F8EE` | Completed tasks, habit checked-in, "Low" priority pill |
| Warning / Medium | `#F59E0B` | `#FEF3E2` | "Medium" priority pill, due < 24h |
| Error / High / Overdue | `#EF4444` | `#FDECEC` | "High" priority pill, overdue count, delete/logout |
| Info / In Progress | `#3B82F6` | `#E8F0FE` | In-progress tasks, info stat tile |

### Category / Accent Pastels (Icon Tiles, Event Cards, Chart Segments)
| Name | Solid | Pastel BG | Example |
| :--- | :--- | :--- | :--- |
| Violet | `#8B5CF6` | `#F1ECFE` | Lectures / Classes |
| Green | `#10B981` | `#E6F7F1` | Health habits |
| Orange | `#F97316` | `#FEF0E6` | Assignments / Deadlines |
| Pink | `#EC4899` | `#FDEBF4` | Personal / Organization |
| Sky | `#0EA5E9` | `#E6F5FC` | Learning / Reading |

### Dark Mode
- Background `#0F1124`, Surface `#1A1D35`, Surface Muted `#24284A`, Text Primary `#F4F5FC`, Text Secondary `#9CA0BC`, Primary `#7C7CFF`. Pastel backgrounds become 16% opacity of the solid color.

---

## 3. Typography

- **Font Family:** `Plus Jakarta Sans` for everything (headings, numbers, body). Fallback: `Inter`.

| Token | Size / Line | Weight | Usage |
| :--- | :--- | :--- | :--- |
| `display.hero` | `32 / 38` | 800 | Onboarding headline ("Your Life, **Organized** in One Place" — key word in primary color) |
| `display.metric` | `28 / 34` | 700 | Ring percentage (72%), stat numbers |
| `headline.screen` | `22 / 28` | 700 | Screen titles ("My Tasks", "Calendar"), user name in greeting |
| `title.section` | `16 / 22` | 700 | Section headers ("Quick Actions", "Today's Tasks") |
| `title.card` | `14 / 20` | 600 | Task title, habit name, event title |
| `body` | `13 / 18` | 400 | Descriptions, helper text |
| `label` | `12 / 16` | 600 | Chips, priority pills, "See All" links (primary color) |
| `caption` | `11 / 14` | 500 | Time/date meta with small clock icon, weekday labels |

---

## 4. Shape, Spacing, Elevation

- **Grid:** 4px base (`4, 8, 12, 16, 20, 24, 32`). Screen horizontal padding `20px`. Gap between cards `12px`, between sections `24px`.
- **Corner Radius:**
  - Large cards / hero banner: `20px`
  - Small stat tiles / list item cards: `16px`
  - Icon tiles (quick action, goal/habit icon): `14px` squircle, size `44–48px`
  - Buttons & search field: `14px` (primary full-width buttons may be fully rounded `999px`)
  - Chips & priority pills: `999px`
  - Bottom sheet top corners: `28px`
  - Phone-frame-like bottom nav: `24px` top corners
- **Elevation:** NO card borders. Soft shadow only: `0 4px 16px rgba(91, 91, 246, 0.06)`. Center FAB shadow: `0 6px 16px rgba(91, 91, 246, 0.35)`.
- **Icons:** Rounded line icons (Lucide / Phosphor Regular style), 20–22px, 1.75px stroke.

---

## 5. Navigation

**Bottom Navigation Bar (white, rounded top, 4 tabs + center FAB):**

`Home` · `Tasks` · **( + )** · `Calendar` · `Habits`

- Center **FAB**: 56px circle, `primary` fill, white "+" icon, slightly raised above the bar. Opens a Quick Add bottom sheet (Task / Event / Habit).
- Active tab: icon + label in `primary`; inactive: `textSecondary`.
- **Statistics & Profile** is opened from the **avatar in the top-right of the Home header** (not a tab).

---

## 6. Screen Specifications

### S-01 Onboarding / Welcome
- Small app logo tile (primary rounded square with 4-dot grid icon) top-left.
- Headline: "Your Life, **Organized** in One Place" (Organized in primary color).
- Subtitle: "Track your tasks, classes, and habits — all in one calm dashboard."
- Soft 3D illustration of a student working at a laptop with floating UI cards (checkmark, bar chart), lavender gradient backdrop.
- Bottom: full-width dark navy button "Get Started →" + text "Already have an account? **Log In**".

### S-02/S-03 Login & Register
- Same light lavender background, small logo, title "Welcome back", email & password fields (`surfaceMuted`, 14px radius, leading icon), primary button, link to register. Register adds name field and auto-detected timezone chip ("Asia/Jakarta").

### S-04 Home / Dashboard
- **Header:** "Good Morning," (caption) / "**Rayhan** 👋" (headline) / "Here's what's happening today." + bell icon with dot + circular avatar (tap → Profile & Stats).
- **Daily Progress card** (tinted `primarySoft` → white): circular progress ring "72%", text "4 of 6 tasks done · Keep going! You're doing great!", chevron.
- **2x2 Stat Grid** (white tiles, colored circle icon + label + number): Total Tasks `12` (blue), In Progress `4` (violet), Completed `8` (green), Overdue `1` (red).
- **Quick Actions row:** 4 pastel icon tiles with labels — Add Task, Add Event, New Habit, Statistics.
- **Today's Agenda:** horizontal cards — time range, class title, location (e.g. "08:00–10:00 · Operating Systems · Bldg B R.204"), left violet accent bar.
- **Today's Habits:** compact cards with icon tile, name, "🔥 5 days" streak pill, round check-in button at right.
- **Today's Tasks** + "See All": rows with circle checkbox (filled green with check when done), title, clock icon + time.

### S-05 My Tasks
- Title "My Tasks" + search field "Search tasks..." + filter icon button.
- Chips: `All` (selected, primary fill, white text) · `Today` · `Upcoming` · `Completed`.
- Task rows (white card list): left **outlined circle checkbox colored by priority** (red/orange/green), title, clock icon + due time/date ("Tomorrow"), right **pastel priority pill** (High / Medium / Low). Done tasks: green filled check, strikethrough, 60% opacity. Overdue: red "Overdue" meta text with clock-alert icon.

### S-06 Quick Add / Task Form Bottom Sheet
- Drag handle, segmented tabs `Task | Event | Habit`.
- Title input, optional description, chips for Date & Time (calendar/clock icons), priority segmented pills (Low/Medium/High with pastel colors), "Remind me" toggle with time chip, full-width primary button "Save Task".

### S-07 Calendar
- Title "Calendar", month row "October 2026" with ‹ › arrows, toggle `Week | Month`.
- **Week strip:** 7 day columns (Mon 21 … Sun 27); selected day is a tall primary-filled rounded pill with white text; small dots under days that have items.
- **Timeline:** left time column (09:00 AM, 11:00 AM…), right pastel cards with colored left accent bar — title + "1 hour · Room B204" meta. Violet = class/event, orange = task deadline, green = habit/personal, pink = organization.
- Full-width primary button "+ Add Event" above the bottom nav.

### S-08 Habits
- Title "Habits" + "+" icon.
- **Hero banner** (navy → indigo gradient, 20px radius, small mountain/flag illustration): "Build Better Habits · Small steps every day lead to big results."
- **My Habits list:** white cards with pastel icon tile (e.g. book, dumbbell, water drop), name, "🔥 7 day streak" + "5/7 this week" caption, colored progress bar, and round check-in button on the right. Under each card, optional 7-dot weekly grid `M T W T F S S` (green filled = done, outlined = pending today, faded = rest day).

### S-09 Habit Detail
- Back arrow, habit name, streak stat chips (Current streak / Best streak / Consistency %), month heatmap calendar, edit active days chips.

### S-10 Statistics & Profile
- **Profile header:** dark navy card (rounded bottom), circular avatar, name "Rayhan", email, settings gear. Inside: 3 stats row — `12 Tasks` · `5 Habits` · `7 Days Streak`.
- **Analytics section:** pill tabs `Overview | Tasks | Habits`, period dropdown "This Week".
  - Productivity Score ring "85%" with "↑ 12% vs last week" in green.
  - Task Completion line chart (Mon–Sun) with soft primary gradient fill under the line.
  - Category Breakdown donut chart (Lectures, Assignments, Personal, Health, Others) with legend + percentages.
- **Menu list** (icon + label + chevron): Reminders (badge count), Notifications, Appearance ("Light"), Timezone ("Asia/Jakarta"), Help & Support.
- Outlined **Log Out** button (red text/icon).

---

## 7. States & Micro-interactions

- **Touch targets:** min `48x48dp` (checkbox, check-in, icon buttons).
- **Loading:** skeleton shimmer shaped like real cards (ring card, stat tiles, list rows). No full-screen spinner.
- **Empty:** small line illustration in primary tint, short title ("No tasks today 🎉"), helper text, primary button ("Add your first task").
- **Error:** white card with red icon, human message, "Try Again" button.
- **Offline:** slim amber banner at top "Offline · showing last saved data".
- **Feedback:** checkbox → instant green fill + check scale animation (≤200ms) + light haptic; snackbar 2s for create/delete.

---

## 8. Anti-Patterns

- ❌ No card borders/outlines as primary separation — use soft shadow on lavender background.
- ❌ No glassmorphism, no neon or rainbow gradients. Gradients allowed only on: hero banner, onboarding backdrop, chart area fill.
- ❌ No large illustrations on task/calendar/home lists (only onboarding + small habit hero banner).
- ❌ No hamburger drawer; no full-screen form for adding a task (use bottom sheet).
- ❌ Red only for High priority, Overdue, delete, and Log Out.
