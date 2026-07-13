# Migrationsplan: Material 3 → Eigenes Design-System

Ziel: Die gesamte App schrittweise vom aktuellen Material-3-Look auf das
eigene, nicht-Material Design-System (`lib/design/`) umstellen. Der
**Design Showcase** (`/design-showcase`) ist bereits die Referenz und das
Migrationsziel.

## Grundregel (gilt ab sofort für JEDE Umstellung)

> Jedes Widget – egal ob grundlegend oder auf einen speziellen Use-Case
> spezialisiert – **muss im Widget-Katalog** (`lib/design/widgets/`)
> liegen und **auf einem einheitlichen Grund-Widget** basieren. Komplexe
> Widgets werden komponentenartig aus den grundlegenderen Katalog-Widgets
> zusammengebaut (Foundation → Primitive → Composite). **Keine** lokalen,
> ad-hoc Widget-Definitionen mehr in Screens. Jedes neue/überführte Widget
> wird in `DESIGN.md` dokumentiert.

Status-Legende: `- [ ]` = offen · `- [x]` = erledigt.

Die Liste ist nach **Position im mobilen Menü** sortiert (Bottom-Nav Index:
0 System · 1 Gemeinschaft · 2 Start · 3 Unterwegs · 4 Organisation).

---

## 0. Vor der Anmeldung (Pre-Login)

### Welcome — `lib/features/welcome/welcome_screen.dart` `- [ ]`
- **Material:** Scaffold, SafeArea, Center, SingleChildScrollView, Column,
  Image.asset, FilledButton.icon
- **Eigene Widgets:** keine
- **Katalog-Arbeit:**
  - [ ] `Scaffold`+`AppBar` → `DesignSurface` + `DesignAppBar`
  - [ ] `FilledButton.icon` → `DesignButton`
  - [ ] `Image.asset` (Logo) → `DesignAvatar`/`_Branding`-Muster

### Login — `lib/features/auth/screens/login_screen.dart` `- [ ]`
- **Material:** Scaffold, AppBar, SafeArea, Center, SingleChildScrollView,
  ConstrainedBox, Column, TextField (OutlineInputBorder), Icon,
  FilledButton.icon, OutlinedButton.icon, TextButton, Row, Divider,
  CircularProgressIndicator
- **Eigene Widgets:** keine
- **Katalog-Arbeit:**
  - [ ] `TextField` → `DesignTextField`
  - [ ] Buttons → `DesignButton` (filled/outlined/ghost)
  - [ ] `Divider` → `DesignDivider`

### Verify — `lib/features/auth/screens/verify_screen.dart` `- [ ]`
- **Material:** Scaffold, AppBar, SafeArea, Center, SingleChildScrollView,
  ConstrainedBox, Column, TextField, Icon, FilledButton.icon,
  CircularProgressIndicator
- **Katalog-Arbeit:**
  - [ ] `TextField` → `DesignTextField`
  - [ ] `FilledButton.icon` → `DesignButton`

### Onboarding — `lib/features/onboarding/screens/onboarding_screen.dart` `- [ ]`
- **Material:** Scaffold, SafeArea, Column, Expanded, PageView, Row,
  Container, Icon, Text, Card, CheckboxListTile, TextField, InputDecorator,
  GestureDetector, CircleAvatar, TextButton, FilledButton, Spacer
- **Eigene Widgets (lokal, auflösen):** `_WelcomePage`, `_ConsentPage`,
  `_ProfilePage`, `_SocialHintPage`, `_PwaHintPage`, `_DonePage`
- **Katalog-Arbeit:**
  - [ ] `CircleAvatar` (direkt) → `DesignAvatar`
  - [ ] `Card` → `DesignCard`
  - [ ] `CheckboxListTile` → `DesignListTile` + `DesignChip`
  - [ ] `TextField` → `DesignTextField`
  - [ ] Lokale Pages → `DesignSurface`/Katalog-Screens

---

## 1. System (Bottom-Nav Index 0)

### Einstellungen — `lib/features/settings/screens/settings_screen.dart` `- [ ]`
- **Material:** ListView, ListTile, Divider, Card, AlertDialog,
  CircularProgressIndicator, OutlinedButton, FilledButton/FilledButton.tonal,
  Text, Icon, Row, Column, Padding, Image
- **Eigene Widgets:** `UserAvatar` (core), `UpdateDialog`;
  **lokale** `_SectionHeader`, `_SettingsTile` (→ im Katalog als
  `DesignListTile`/Section aufgehen lassen)
- **Katalog-Arbeit:**
  - [ ] `UserAvatar` → `DesignAvatar`
  - [ ] `_SettingsTile`/`ListTile` → `DesignListTile`
  - [ ] `OutlinedButton`/`FilledButton` → `DesignButton`
  - [ ] `AlertDialog` (Logout) → `showDesignSheet`/Design-Dialog
  - [x] **Erscheinungsbild-Auswahl** bereits eingehängt (persistenter
        `DesignSegmentedSwitch` in dieser Screen)

### Admin — *Platzhalter (kein Screen)* `- [ ]`
- Noch nicht gebaut → direkt im Katalog-Stil neu erstellen.

### Feedback — `lib/features/feedback/screens/feedback_screen.dart` `- [ ]`
- **Material:** Scaffold, Column, Card, InkWell, TextFormField/Form,
  TextField, Icon, FloatingActionButton, CircularProgressIndicator,
  AlertDialog, FilledButton/FilledButton.tonal, SnackBar,
  SingleChildScrollView
- **Eigene Widgets:** `SuggestionList` → `SuggestionCard` → lokal
  `_StatusBadge`, `_VoteButton`, `_MenuAction`; lokal `_CreateSuggestionSheet`,
  `_BugReportSection`
- **Katalog-Arbeit:**
  - [ ] `SuggestionCard` → `DesignCard` (baut auf `DesignText`, `DesignBadge`,
        `DesignButton`)
  - [ ] `_StatusBadge` → `DesignBadge`
  - [ ] `_VoteButton` → `DesignIconButton`/`DesignButton`
  - [ ] `TextFormField` → `DesignTextField`
  - [ ] `_CreateSuggestionSheet` → `showDesignSheet`

### Changelog — *Platzhalter (kein Screen)* `- [ ]`
- Noch nicht gebaut → direkt im Katalog-Stil neu erstellen.

---

## 2. Gemeinschaft (Bottom-Nav Index 1)

### Forum — `lib/features/forum/screens/forum_list_screen.dart` `- [ ]`
- **Material:** DefaultTabController, TabBar, TabBarView, Column,
  ListView/ListView.builder, ListTile, RefreshIndicator,
  CircularProgressIndicator, FilledButton.tonal, Expanded, Text, Icon
- **Eigene Widgets:** `ForumCard` → lokal `_FallbackIcon`; lokal `_ForumList`
- **Katalog-Arbeit:**
  - [ ] `ForumCard` → `DesignCard` (mit `DesignAvatar`, `DesignText`,
        `DesignChip`)
  - [ ] `TabBar`/`ListTile` → `DesignNavItem`/`DesignListTile`

### Kritik — *Platzhalter (kein Screen)* `- [ ]`
- Noch nicht gebaut → direkt im Katalog-Stil neu erstellen.

### Rezepte — `lib/features/recipes/screens/recipe_list_screen.dart` `- [ ]`
- **Material:** Stack, SingleChildScrollView, Column, TextField
  (OutlineInputBorder), GridView.builder, ListView.separated, Card,
  TextButton, FloatingActionButton, CircularProgressIndicator, Padding
- **Eigene Widgets:** `RecipeCard` → lokal `_FallbackImage`; lokal
  `_CategoryTile`
- **Katalog-Arbeit:**
  - [ ] `RecipeCard` → `DesignCard` (+ `DesignAvatar`/`DesignImage`,
        `DesignChip` für Tags)
  - [ ] `TextField` (Suche) → `DesignTextField`
  - [ ] `_CategoryTile` → `DesignListTile`/`DesignChip`

### Fotos — *Platzhalter (kein Screen)* `- [ ]`
- Noch nicht gebaut → direkt im Katalog-Stil neu erstellen.

### Kontakte — `lib/features/user/screens/contacts_screen.dart` `- [x]`
- **Material:** ListView.builder, Card, Padding, Text, Icon,
  CircularProgressIndicator, FilledButton.tonal, Center, Column
- **Eigene Widgets:** `UserCard` → `UserAvatar` (core)
- **Katalog-Arbeit:**
  - [x] `UserCard` → `DesignUserCard` (neues Composite aus `DesignCard` +
        `DesignAvatar`, `DesignText`, `DesignBadge`); `UserCard` ist nun
        dünner Feature-Adapter `UserBasePublic` → `DesignUserCard`
  - [x] `UserAvatar` → `DesignAvatar` (jetzt mit data:/base64-Support via
        `resolveImageProvider`, vollwertiger Ersatz)
  - [x] `FilledButton.tonal` (Retry) → `DesignButton` (outlined)
  - [~] `CircularProgressIndicator` (Loading) bleibt vorerst als
        System-Affordanz; eigener `DesignProgressIndicator` folgt bei Bedarf.

  ### Nutzerprofil (Sub-Screen) — `lib/features/user/screens/user_detail_screen.dart` `- [x]`
  - **Material:** Scaffold-Body, Center, Column, `BackButton`, `UserAvatar`,
    `Text` (headlineSmall), `Container`-Badge, `FilledButton.tonal`;
    **lokale** `_InfoTile`, `_SocialTile`, `_SocialRow`
  - **Katalog-Arbeit:**
    - [x] `UserAvatar` → `DesignAvatar`
    - [x] `_InfoTile`/`_SocialTile`/`_SocialRow` (lokal) → `DesignListTile`
          (+ `DesignDivider`, `DesignCard`); keine lokalen Widgets mehr
    - [x] `BackButton` → `DesignIconButton` (`context.pop()`)
    - [x] `Text` (Name) → `DesignText`; "Das bist du" → `DesignBadge`
    - [x] `FilledButton.tonal` → `DesignButton` (outlined)
    - [x] Body → `DesignSurface`

---

## 3. Start (Bottom-Nav Index 2)

### Home — `lib/features/home/home_screen.dart` `- [ ]`
- **Material:** Center, Padding, Column, Icon, SizedBox, Text
- **Eigene Widgets:** keine (Platzhalter-Dashboard)
- **Katalog-Arbeit:**
  - [ ] Dashboard-Grundgerüst → `DesignSurface` + `DesignCard` +
        `DesignText` neu aufbauen

---

## 4. Unterwegs (Bottom-Nav Index 3)

### Entdecken — `lib/features/explore/screens/explore_screen.dart` `- [ ]`
- **Material:** Column, Padding, Row, InkWell, Container, IconButton,
  CustomScrollView, SliverPadding, SliverToBoxAdapter, SliverGrid,
  SliverChildBuilderDelegate, ListView.separated, Card, Text, Icon,
  FilledButton.tonal, TextButton, Stack, CircularProgressIndicator,
  SafeArea, PageRouteBuilder+SlideTransition
- **Eigene Widgets:** `ExploreMap` (flutter_map), `ExploreSearchOverlay`,
  `PlaceCard`; lokal `_CategoryButton`
- **Katalog-Arbeit:**
  - [ ] `PlaceCard` → `DesignCard` (+ `DesignText`, `DesignChip`)
  - [ ] `_CategoryButton` → `DesignChip`/`DesignButton`
  - [ ] `IconButton` → `DesignIconButton`
  - [ ] `ExploreSearchOverlay` (Sheet) → `showDesignSheet` + `DesignTextField`

### Reisen — `lib/features/travel/screens/travel_screen.dart` `- [ ]`
- **Material:** CustomScrollView, SliverToBoxAdapter, SliverList,
  SliverChildBuilderDelegate, Card, ListTile, CircleAvatar, Icon, Text,
  ElevatedButton, Center, Column
- **Eigene Widgets:** lokal `_TimelineCard` (nutzt `CircleAvatar` **direkt**)
- **Katalog-Arbeit:**
  - [ ] `_TimelineCard`/`Card` → `DesignCard` (+ `DesignText`)
  - [ ] `CircleAvatar` (direkt) → `DesignAvatar`
  - [ ] `ListTile` → `DesignListTile`
  - [ ] `ElevatedButton` → `DesignButton`

---

## 5. Organisation (Bottom-Nav Index 4)

### Kalender — `lib/features/calendar/screens/calendar_screen.dart` `- [ ]`
- **Material:** Scaffold (eigen), AppBar, CustomScrollView,
  SliverPersistentHeader + `_CalendarHeaderDelegate`, SliverToBoxAdapter,
  SliverPadding, SliverList, TableCalendar (package), Column, Row,
  IconButton, TextButton.icon, FilledButton.icon, ElevatedButton.icon,
  FloatingActionButton, VerticalDivider, SingleChildScrollView,
  CircularProgressIndicator, AlertDialog
- **Eigene Widgets:** `AgendaList` → lokal `_DaySection` → `_EventTile`;
  `EventFormSheet` → lokal `_DateTimePicker`, `_VisibilitySelector`;
  lokal `_WeekStrip`
- **Katalog-Arbeit:**
  - [ ] `AgendaList`/`_EventTile` → `DesignListTile`/`DesignCard`
  - [ ] `EventFormSheet` → `showDesignSheet` + `DesignTextField` +
        `DesignChip` (Visibility)
  - [ ] Buttons → `DesignButton`/`DesignIconButton`

### Umfrage — *Platzhalter (kein Screen)* `- [ ]`
- Noch nicht gebaut → direkt im Katalog-Stil neu erstellen.

### Abos — *Platzhalter (kein Screen)* `- [ ]`
- Noch nicht gebaut → direkt im Katalog-Stil neu erstellen.

---

## Dialoge / Overlays

### Update-Dialog — `lib/features/update/update_dialog.dart` `- [ ]`
- **Material:** AlertDialog, SizedBox, Column, Text, Row,
  LinearProgressIndicator, TextButton, FilledButton
- **Katalog-Arbeit:**
  - [ ] `AlertDialog` → `showDesignSheet` + `DesignCard`
  - [ ] Buttons → `DesignButton`

### Notification-Sheet — `lib/features/notifications/widgets/notification_sheet.dart` `- [ ]`
- **Material:** DraggableScrollableSheet, Column, Padding, Container, Row,
  Text, TextButton.icon, Divider, RefreshIndicator, ListView.builder,
  Dismissible, CircleAvatar, ListTile, Icon, Expanded, Center
- **Eigene Widgets:** lokal `_NotificationItem` (nutzt `CircleAvatar`
  **direkt**)
- **Katalog-Arbeit:**
  - [ ] Sheet → `showDesignSheet`
  - [ ] `_NotificationItem`/`ListTile` → `DesignListTile`
  - [ ] `CircleAvatar` (direkt) → `DesignAvatar`

---

## Design Showcase (Referenz / Ziel) `- [x]`
- `lib/features/showcase/screens/design_showcase_screen.dart` nutzt bereits
  vollständig den Katalog (`DesignSurface`, `DesignSegmentedSwitch`,
  `DesignShowcaseSection`, `DesignColorSwatch`, `DesignTokenSpec`,
  `DesignButton`, `DesignChip`, `DesignBadge`, `DesignTextField`,
  `DesignCard`, `DesignAvatar`, `DesignIconButton`, `DesignText`,
  `DesignListTile`, `DesignDivider`, `DesignNavItem`, `DesignAppBar`,
  `showDesignSheet`). Bleibt bestehen.

---

## Geteilte Custom-Widgets (Quelle für die Migration)

Diese bestehenden, wiederverwendbaren Widgets werden zu Katalog-Widgets
zusammen geführt bzw. durch sie ersetzt:

- `lib/core/widgets/user_avatar.dart` → `UserAvatar` → **ersetzt durch `DesignAvatar`** (paritätischer Support für http/data/base64)
- `lib/core/widgets/web_update_banner.dart` → `WebUpdateBanner` (web-only)
- `lib/features/calendar/widgets/agenda_list.dart` → `AgendaList`
- `lib/features/calendar/widgets/event_form_sheet.dart` → `EventFormSheet`
- `lib/features/explore/widgets/explore_map.dart` → `ExploreMap`
- `lib/features/explore/widgets/explore_search_overlay.dart` → `ExploreSearchOverlay`
- `lib/features/explore/widgets/place_card.dart` → `PlaceCard`
- `lib/features/feedback/widgets/comment_input.dart` → `CommentInput`
- `lib/features/feedback/widgets/comment_tile.dart` → `CommentTile`
- `lib/features/feedback/widgets/suggestion_card.dart` → `SuggestionCard`
- `lib/features/feedback/widgets/suggestion_list.dart` → `SuggestionList`
- `lib/features/forum/widgets/comment_tree.dart` → `CommentTreeTile`
  (**Duplikat** von `CommentInput` → konsolidieren!)
- `lib/features/forum/widgets/forum_card.dart` → `ForumCard`
- `lib/features/forum/widgets/member_sheet.dart` → `MemberSheet`
- `lib/features/forum/widgets/og_preview_card.dart` → `OgPreviewCard`
- `lib/features/forum/widgets/post_card.dart` → `PostCard`
- `lib/features/forum/widgets/spotify_player_embed.dart` → `SpotifyPlayerEmbed`
- `lib/features/forum/widgets/spotify_thumbnail.dart` → `SpotifyThumbnail`
- `lib/features/forum/widgets/youtube_player_embed.dart` → `YouTubePlayerEmbed`
- `lib/features/forum/widgets/youtube_thumbnail.dart` → `YouTubeThumbnail`
- `lib/features/recipes/widgets/recipe_card.dart` → `RecipeCard`
- `lib/features/settings/widgets/visibility_badge.dart` → `VisibilityBadge`
- `lib/features/travel/widgets/user_tile.dart` → `UserTile`
- `lib/features/user/widgets/user_card.dart` → `UserCard` (jetzt dünner
  Feature-Adapter auf `DesignUserCard`)

### Bekannte Inkonsistenzen (beim Migrieren normalisieren)
- `CommentInput` existiert doppelt (`feedback` + `forum`) → eine Definition.
- `CircleAvatar` wird direkt statt `UserAvatar` genutzt in: `TravelScreen`,
  `NotificationSheet`, `OnboardingScreen`.
