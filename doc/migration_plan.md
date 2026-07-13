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

### Welcome — `lib/features/welcome/welcome_screen.dart` `- [x]`
- **Material:** Scaffold, SafeArea, Center, SingleChildScrollView, Column,
  Image.asset, FilledButton.icon
- **Eigene Widgets:** keine
- **Katalog-Arbeit:**
  - [x] `Scaffold`+`AppBar` → `DesignSurface` + `DesignText` (kein AppBar nötig)
  - [x] `FilledButton.icon` → `DesignButton` (filled)
  - [~] `Image.asset` (Logo) → vorerst direkt `Image.asset` (kein eigenes
        Branding-Widget im Katalog)

### Login — `lib/features/auth/screens/login_screen.dart` `- [x]`
- **Material:** Scaffold, AppBar, SafeArea, Center, SingleChildScrollView,
  ConstrainedBox, Column, TextField (OutlineInputBorder), Icon,
  FilledButton.icon, OutlinedButton.icon, TextButton, Row, Divider,
  CircularProgressIndicator
- **Eigene Widgets:** keine
- **Katalog-Arbeit:**
  - [x] `Scaffold`+`AppBar` → `DesignSurface` + `DesignAppBar` (back via
        `DesignIconButton`)
  - [x] `TextField` → `DesignTextField`
  - [x] `FilledButton.icon` → `DesignButton` (filled, `loading` zeigt Spinner)
  - [x] `OutlinedButton.icon` → `DesignButton` (outlined)
  - [x] `TextButton` (Registrieren) → `DesignButton` (text)
  - [x] `Divider` → `DesignDivider`
  - [~] `CircularProgressIndicator` im Button entfällt (via `DesignButton.loading`)

### Verify — `lib/features/auth/screens/verify_screen.dart` `- [x]`
- **Material:** Scaffold, AppBar, SafeArea, Center, SingleChildScrollView,
  ConstrainedBox, Column, TextField, Icon, FilledButton.icon,
  CircularProgressIndicator
- **Eigene Widgets:** keine
- **Katalog-Arbeit:**
  - [x] `Scaffold`+`AppBar` → `DesignSurface` (ganze Seite) + `DesignAppBar`
        (back via `DesignIconButton`)
  - [x] `TextField` → `DesignTextField` (`textAlign`, `maxLength: 6`,
        `prefixIcon`)
  - [x] `FilledButton.icon` → `DesignButton` (filled, `loading` zeigt Spinner)
  - [~] `CircularProgressIndicator` im Button entfällt (via `DesignButton.loading`)

### Onboarding — `lib/features/onboarding/screens/onboarding_screen.dart` `- [x]`
- **Material:** Scaffold, SafeArea, Column, Expanded, PageView, Row,
  Container, Icon, Text, Card, CheckboxListTile, TextField, InputDecorator,
  GestureDetector, CircleAvatar, TextButton, FilledButton, Spacer
- **Eigene Widgets (lokal, auflösen):** `_WelcomePage`, `_ConsentPage`,
  `_ProfilePage`, `_SocialHintPage`, `_PwaHintPage`, `_DonePage`
- **Katalog-Arbeit:**
  - [x] `Scaffold`+`SafeArea` → `DesignSurface` (ganze Seite), Pages sind
        jetzt vollständig aus Katalog-Widgets aufgebaut
  - [x] `CircleAvatar` (direkt) → `DesignAvatar` (bytes via data:-URI,
        sonst `existingImageUrl`); Kamera-Badge als `Container`+`Icon`
  - [x] `Card` → `DesignCard`
  - [x] `CheckboxListTile` → `DesignListTile` + `DesignChip` (Chip = Toggle,
        ganzer Tile tippbar)
  - [x] `TextField` → `DesignTextField` (`prefixIcon`)
  - [x] `InputDecorator`+`InkWell` (Geburtstag) → `DesignListTile`
        (`leading` cake, `trailing` calendar, `onTap` picker)
  - [x] `TextButton`/`FilledButton` → `DesignButton` (text/filled,
        `loading` zeigt Spinner)
  - [x] `showModalBottomSheet` (Bildquelle) → `showDesignSheet` +
        `DesignListTile`
  - [~] `Text` → `DesignText`; lokale Pages bleiben als private
        `StatelessWidget`-Pages (Page-Content, keine ad-hoc Katalog-Widgets)

---

## 1. System (Bottom-Nav Index 0)

### Einstellungen — `lib/features/settings/screens/settings_screen.dart` `- [x]`
- **Material:** ListView, ListTile, Divider, Card, AlertDialog,
  CircularProgressIndicator, OutlinedButton, FilledButton/FilledButton.tonal,
  Text, Icon, Row, Column, Padding, Image
- **Eigene Widgets:** `UserAvatar` (core), `UpdateDialog`;
  **lokale** `_SectionHeader`, `_SettingsTile` (→ im Katalog als
  `DesignListTile`/Section aufgehen lassen)
- **Katalog-Arbeit:**
  - [x] `Scaffold`/`AppBar` (Shell) → Body in `DesignSurface` gewrappt
        (Shell liefert Material-`AppBar`; Surface-Seam ist Shell-Thema,
        hier nicht migriert)
  - [x] `UserAvatar` (core) → `DesignAvatar`
  - [x] `_SettingsTile`/`ListTile` → `DesignListTile` (`leading` Icon,
        `trailing` chevron, `onTap`), gruppiert in `DesignCard.list`
        (sektionsweise Karten mit konsistentem Seitenabstand); keine
        lokalen Widgets mehr
  - [x] `_SectionHeader` (lokal) → inline `DesignText` (label, primary)
  - [x] `Divider` → `DesignDivider`
  - [x] `OutlinedButton`/`FilledButton.tonal` → `DesignButton`
        (outlined/text/filled); Logout als `DesignButton` outlined
        (`fullWidth`) – **ohne** eigene Danger-Tönung (Katalog hat aktuell
        keine Danger-Variante; bei Bedarf `DesignButton` um `danger` ergänzen)
  - [x] `AlertDialog` (Logout) → `showDesignSheet` + `DesignButton`
  - [x] `CircularProgressIndicator` (Loading/Update) → `tokens.primary`
  - [x] **Erscheinungsbild-Auswahl** bereits eingehängt (persistenter
        `DesignSegmentedSwitch` in dieser Screen)

### Admin — *Platzhalter (kein Screen)* `- [ ]`
- Noch nicht gebaut → direkt im Katalog-Stil neu erstellen.

### Feedback — `lib/features/feedback/screens/feedback_screen.dart` `- [x]`
- **Material:** Scaffold, Column, Card, InkWell, TextFormField/Form,
  TextField, Icon, FloatingActionButton, CircularProgressIndicator,
  AlertDialog, FilledButton/FilledButton.tonal, SnackBar,
  SingleChildScrollView
- **Eigene Widgets:** `SuggestionList` → `SuggestionCard` → lokal
  `_StatusBadge`, `_VoteButton`, `_MenuAction`; lokal `_CreateSuggestionSheet`,
  `_BugReportSection` *(alle lokalen Widgets aufgelöst: `DesignCard`,
  `DesignBadge`, `DesignButton`, `DesignIconButton`, `showDesignSheet`)*
- **Katalog-Arbeit:**
  - [x] `SuggestionCard` → `DesignCard` (baut auf `DesignText`, `DesignBadge`,
        `DesignButton`)
  - [x] `_StatusBadge` → `DesignBadge`
  - [x] `_VoteButton` → `DesignIconButton`/`DesignButton`
  - [x] `TextFormField` → `DesignTextField`
  - [x] `_CreateSuggestionSheet` → `showDesignSheet`
- **Hinweis:** `feedback_detail_screen.dart` ebenfalls migriert
  (`DesignSurface` + `DesignAppBar`, `DesignBadge`, `DesignButton`,
  `DesignDivider`, `DesignChip` für `ChoiceChip`, `showDesignSheet` für
  Lösch-/Bearbeiten-Dialoge; lokale `_StatusBadge`, `_VoteButtonLarge`,
  `_StatusChangeSection` aufgelöst).

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

### Entdecken — `lib/features/explore/screens/explore_screen.dart` `[x]`
- **Material:** ~~Column, Padding, Row, InkWell, Container, IconButton,
  CustomScrollView, SliverPadding, SliverToBoxAdapter, SliverGrid,
  SliverChildBuilderDelegate, ListView.separated, Card, Text, Icon,
  FilledButton.tonal, TextButton, Stack, CircularProgressIndicator,
  SafeArea, PageRouteBuilder+SlideTransition~~
- **Eigene Widgets:** ~~`_CategoryButton`~~ (entfernt)
- **Katalog-Arbeit:**
  - [x] `DesignSurface` als Seiten-Wrapper
  - [x] `Card` → `DesignCard` (Suchleiste, Bookmark-Karten)
  - [x] `Text`/`Theme.of` → `DesignText`/`DesignTheme.of`
  - [x] `InkWell`/Container (Suchleiste) → `DesignCard(onTap: _openSearch)`
  - [x] `_CategoryButton` (`OutlinedButton.icon`) → `DesignButton`(outlined) inline
  - [x] `IconButton.filled` → `DesignIconButton`(tinted)
  - [x] `IconButton` → `DesignIconButton`
  - [x] `FilledButton.tonal` → `DesignButton`(filled)
  - [x] `TextButton` → `DesignButton`(text)
  - [x] `CircularProgressIndicator` → `tokens.primary`

### Entdecken-Kategorie — `lib/features/explore/screens/category_screen.dart` `[x]`
- **Material:** ~~Column, Row, InkWell, Container, IconButton, Text,
  TextButton.icon, FilledButton.tonal, FilterChip, Card, CircularProgressIndicator,
  GridView.builder, RefreshIndicator, PageRouteBuilder+SlideTransition~~
- **Eigene Widgets:** ~~lokales `SortChip` (`FilterChip`)~~ (entfernt)
- **Katalog-Arbeit:**
  - [x] `DesignSurface` als Seiten-Wrapper
  - [x] `FilterChip`/`SortChip` → `DesignChip` (selected/unselected)
  - [x] `Card` → `DesignCard`
  - [x] `Text`/`Theme.of` → `DesignText`/`DesignTheme.of`
  - [x] `IconButton` → `DesignIconButton`
  - [x] `FilledButton.tonal` → `DesignButton`(filled)
  - [x] `TextButton.icon` → `DesignButton`(text)
  - [x] `CircularProgressIndicator` → `tokens.primary`

### Entdecken-Detail — `lib/features/explore/screens/detail_screen.dart` `[x]`
- **Material:** ~~Scaffold, AppBar, Card, BackButton, FilledButton.tonalIcon,
  OutlinedButton.icon, IconButton, CircleAvatar/UserAvatar, Text, TextButton,
  AlertDialog, DefaultTabController, TabBar, TabBarView, SimpleAttributionWidget~~
- **Eigene Widgets:** lokale Tab-Composites (`_WideDetail`, `_NarrowDetail`,
  `_InfoContent`, `_MapCard`, `_ActionsCard`, `_ReviewsSection`, `_ReviewCard`,
  `_StarRating`, `_ReviewForm`) bestehen als dünne Katalog-Zusammenbauten.
  Top-level Hilfen `_infoRow`/`_metaRow` ersetzen die früheren lokalen Klassen.
- **Katalog-Arbeit:**
  - [x] `DesignSurface` + `DesignAppBar` (zurück) als Seiten-Wrapper
  - [x] `Card` → `DesignCard` (auch MapCard mit `useGlass: false` + `ClipRRect`)
  - [x] `BackButton` → `DesignIconButton` + `context.pop()`
  - [x] `FilledButton.tonalIcon` → `DesignButton`(filled, `loading`, `icon`)
  - [x] `OutlinedButton.icon` → `DesignButton`(outlined)
  - [x] `IconButton` → `DesignIconButton`
  - [x] `UserAvatar` → `DesignAvatar`
  - [x] `TextButton` → `DesignButton`(text)
  - [x] `AlertDialog` (Löschen, Bewertung editieren) → `showDesignSheet`
  - [x] `SimpleAttributionWidget` → entfernt (overflow)
  - [x] `TabBar`/`TabBarView` mit Token-Farben (`indicatorColor`, `labelColor`)
  - [x] `Text`/`Theme.of` → `DesignText`/`DesignTheme.of`
  - [x] `CircleAvatar` (InfoRow Icons) → `Icon` mit Token-Farben

### Ort hinzufügen — `lib/features/explore/screens/create_place_screen.dart` `[x]`
- **Material:** ~~TextField, FilledButton.icon, ListView.separated, ListTile,
  Divider, Text, Theme.of~~
- **Eigene Widgets:** keine
- **Katalog-Arbeit:**
  - [x] `DesignSurface` + `DesignAppBar` als Seiten-Wrapper
  - [x] `TextField` → `DesignTextField`
  - [x] `FilledButton.icon` → `DesignButton`(filled)
  - [x] `ListTile` → `DesignListTile` (+ `DesignCard`)
  - [x] `Divider` → `DesignDivider`
  - [x] `Text`/`Theme.of` → `DesignText`/`DesignTheme.of`

### Reisen — `lib/features/travel/screens/travel_screen.dart` `[x]`
- **Material:** ~~CustomScrollView, SliverToBoxAdapter, SliverList,
  SliverChildBuilderDelegate, Card, ListTile, CircleAvatar, Icon, Text,
  ElevatedButton, Center, Column~~
- **Eigene Widgets:** ~~lokal `_TimelineCard`~~
- **Katalog-Arbeit:**
  - [x] `_TimelineCard` → inline-codiert (lokale Klasse entfernt)
  - [x] `Card` → `DesignCard`
  - [x] `CircleAvatar` → `Container` + `Icon` + Token-Farben (kein Avatar nötig für Trip/Event-Icons)
  - [x] `ListTile` → custom `Row` in `DesignCard` (DesignListTile wegen Gesture-Konflikt mit DesignCard.onTap vermieden)
  - [x] `ElevatedButton` → `DesignButton`
  - [x] `Text`/`Theme.of(context).textTheme` → `DesignText`
  - [x] `CustomScrollView`/SliverList → `SingleChildScrollView` + `Column`

### Reisedetail — `lib/features/travel/screens/trip_detail_screen.dart` `[x]`
- **Material:** ~~TabBar, TabBarView, Card, CircleAvatar, Chip, ElevatedButton,
  Text, Theme.of~~
- **Eigene Widgets:** ~~`_SectionHeader`~~ entfernt; lokale Tab-Widgets (`_OverviewTab`,
  `_AccommodationCard`, `_AccommodationMap`, `_EventsTab`, `_EventCard`,
  `_MapTab`) bestehen als Thin-Composites aus Katalog-Widgets.
- **Katalog-Arbeit:**
  - [x] `DesignSurface` + `DesignAppBar` (zurück) als Seiten-Wrapper
  - [x] `TabBar` mit Token-Farben (`indicatorColor`, `labelColor`, `unselectedLabelColor`)
  - [x] `Card` → `DesignCard` (inkl. Karten für FlutterMap mit `useGlass: false`)
  - [x] `CircleAvatar`/`UserAvatar` → `DesignAvatar`
  - [x] `Chip` → `DesignBadge`
  - [x] `ElevatedButton` → `DesignButton`
  - [x] `Text`/`Theme.of` → `DesignText`/`DesignTheme.of`
  - [x] `UserTile` (Feature-Adapter) → `DesignAvatar` + `DesignText`

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

### Notification-Sheet — `lib/features/notifications/widgets/notification_sheet.dart` `[x]`
- **Material:** ~~DraggableScrollableSheet, Column, Padding, Container, Row,
  Text, TextButton.icon, Divider, RefreshIndicator, ListView.builder,
  Dismissible, CircleAvatar, ListTile, Icon, Expanded, Center~~
- **Eigene Widgets:** lokal `_NotificationItem` (nutzt `DesignListTile` +
  `DesignAvatar`-ähnliches Container+Icon)
- **Katalog-Arbeit:**
  - [x] Sheet-Background → `Container` mit `tokens.surface` + abgerundeten Ecken
  - [x] `ListTile` → `DesignListTile`
  - [x] `CircleAvatar` → `Container` + `Icon` + Token-Farben
  - [x] `Text`/`Theme.of` → `DesignText`/`DesignTheme.of`
  - [x] `TextButton.icon` → `DesignButton`(text)
  - [x] `Divider` → `DesignDivider`

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
- `lib/features/explore/widgets/explore_map.dart` → `ExploreMap` (SimpleAttributionWidget entfernt, da Overflow im constrained Container)
- `lib/features/explore/widgets/explore_search_overlay.dart` → `ExploreSearchOverlay` (DesignSurface+AppBar, DesignTextField, DesignButton, DesignChip; DesignButton-Reihe statt SegmentedButton)
- `lib/features/explore/widgets/place_card.dart` → `PlaceCard` (Card→DesignCard, Text→DesignText, Theme.of→DesignTheme.of)
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
  `NotificationSheet`. (OnboardingScreen migriert → `DesignAvatar`)

---

## Shell / Navigation (quer über alle Screens) `- [x]`

- **Material:** `Scaffold` + `AppBar` (Titel via `_titleForLocation`),
  `BottomNavigationBar` (5 Kategorien, öffnet `showModalBottomSheet` mit
  Untereinträgen), Desktop-`Scaffold` mit 288px-Sidebar (`ListTile` +
  `VerticalDivider`), `Chip` ("Bald") für Platzhalter, `IconButton`+`Badge`
  für Notification-Bell
- **Katalog-Arbeit:**
  - [x] `Scaffold`+`AppBar` (Shell) → `DesignSurface` (ganze Seite) +
        `DesignAppBar` (`title` = `_titleForLocation`, `actions` =
        Notification-Bell). Funktionalität und Struktur (Desktop-Sidebar +
        Mobile-Bottom-Nav + Kategorie-Sheets) unverändert.
  - [x] Mobile `BottomNavigationBar` → Design-Bottom-Nav (Container mit
        `tokens.surface` + oberem `Border`, 5 gleichgewichtete `Expanded`-
        Spalten aus `Icon` + `DesignText` (label), aktiver Tab in
        `tokens.primary`, `PressScale` für Tap-Feedback)
  - [x] Desktop-Sidebar `ListTile` → Design-Nav-Tiles (Inline-Komposition aus
        `PressScale` + `Container`(`tokens.surfaceVariant` bei aktiv) + `Icon`
        + `DesignText`), Gruppen-Header als `DesignText`(`label`, `tokens.primary`)
  - [x] `VerticalDivider` → `tokens.border` (alpha 0.6)
  - [x] Kategorie-Sheet (`showModalBottomSheet`, `ListTile`, `Chip` "Bald") →
        `showDesignSheet` + `DesignListTile` + `DesignBadge`("Bald" bzw.
        "Aktiv"); aktiver Eintrag via `currentLocation`-Präfix, Platzhalter
        abgeblendet
  - [x] Notification-Bell `IconButton`+`Badge` → `DesignIconButton` +
        `Stack`/`Positioned` mit `DesignBadge` (Ungelesen-Count)
  - [~] `MaterialApp.router` liefert weiterhin den Root-`ScaffoldMessenger`,
        daher keine Snackbar-Regression trotz entfallenem Shell-`Scaffold`
