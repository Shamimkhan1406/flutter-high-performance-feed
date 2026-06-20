# Flutter High Performance Feed

A high-performance social media feed built with Flutter, Riverpod, and Supabase, featuring infinite scrolling, optimistic likes, tiered image loading, and production-ready performance optimizations.

---

## Features

- **Infinite scrolling feed** with automatic pagination
- **Pull-to-refresh** for live content updates
- **Supabase backend integration** for posts, likes, and image storage
- **Optimistic like updates** — UI responds instantly before the server confirms
- **Debounced like API calls** — 800ms debounce to prevent excessive RPC calls
- **Offline revert on failed like requests** — state rolls back automatically on error
- **Hero animations** — smooth transitions from feed card to detail screen
- **Tiered image loading** — Thumbnail → Mobile → Raw, served progressively per screen
- **High-resolution image download** using `dio` and `path_provider`
- **Cached network images** via `cached_network_image` to minimize redundant network calls
- **RepaintBoundary optimizations** on every feed card to isolate repaints
- **MVC architecture** with clear separation of concerns
- **Riverpod state management** for reactive, testable state

---

## Architecture

This project follows **MVC (Model-View-Controller)** architecture, extended with a dedicated providers layer for Riverpod integration.

```
lib/
├── core/            # App-wide constants, theme, environment config
├── models/          # Data classes (Post, User, etc.)
├── services/        # Supabase API calls and data access logic
├── controllers/     # Business logic (feed pagination, like debounce)
├── providers/       # Riverpod providers exposing state to the UI
└── views/           # Screens and widgets (feed screen, detail screen, card widget)
```

**Layer responsibilities:**

- **Models** → Immutable data layer; plain Dart classes representing API entities
- **Services** → All Supabase interactions (fetch posts, toggle likes, download images)
- **Controllers** → Business logic coordinating services and managing in-memory state
- **Providers** → Riverpod providers that wrap controllers and expose reactive state to widgets
- **Views** → Purely UI; consumes providers via `ref.watch`, never touches services directly

This layering ensures that the UI layer never directly calls the database, business logic is independently testable, and state flows in a single direction.

---

## State Management

Riverpod (`flutter_riverpod: ^2.6.1`) is the state management solution. Here's how the approach works end-to-end:

### Provider Structure

| Provider | Type | Responsibility |
|---|---|---|
| `feedProvider` | `StateNotifierProvider` | Holds the list of posts + pagination state |
| `feedControllerProvider` | `Provider` | Exposes the `FeedController` to other providers |
| `likeStateProvider` | Scoped per post | Tracks optimistic like/count per post |
| `loadingProvider` | `StateProvider<bool>` | Controls loading skeleton visibility |

### How Riverpod Powers the Feed

1. `feedProvider` is a `StateNotifier` that holds a `FeedState` object — a list of posts, the current page, a `hasMore` flag, and an `isLoading` flag.
2. On initial load, the notifier calls `FeedService.fetchPosts(page: 0, limit: 10)` and emits a new state with the returned posts.
3. The scroll controller in the feed view detects when the user reaches ~80% of list end, then calls `ref.read(feedProvider.notifier).loadMore()`.
4. `loadMore()` guards against duplicate calls using the `isLoading` flag, fetches the next page, and emits a new state with the appended list.
5. Like state is managed separately per post ID to avoid rebuilding the entire list on every tap — only the tapped card's like widget rebuilds.

### Why This Approach

Riverpod was chosen over Provider because it is compile-safe (no `context` required to read state), supports scoped and family providers cleanly, and makes the `FeedController` independently instantiable without a widget tree — important for future unit testing.

---

## Performance Optimizations

This section is the core of the assignment. Every optimization below is deliberately implemented, not accidental.

### RepaintBoundary

Each feed card is wrapped in a `RepaintBoundary`:

```dart
RepaintBoundary(
  child: FeedCard(post: post),
)
```

**Why:** Flutter's raster thread repaints the smallest dirty layer it can find. Without `RepaintBoundary`, a like-count update on card #3 can trigger a repaint of the entire list viewport. Wrapping each card creates its own compositing layer, so only the tapped card's layer is invalidated and repainted — all other cards are unaffected.

**Verification:** Enabled Flutter's performance overlay (`showPerformanceOverlay: true`) and observed raster thread bar behavior. With `RepaintBoundary`, a like tap produces a narrow raster spike affecting only one card. Without it, the spike spans the full visible list. Additionally, DevTools' "Highlight Repaints" mode was used: cards without the boundary flash on every like; cards with it flash only the tapped one.

### CachedNetworkImage

All images are loaded through `CachedNetworkImage`:

```dart
CachedNetworkImage(
  imageUrl: post.thumbnailUrl,
  memCacheWidth: 400,
  placeholder: (context, url) => const ShimmerPlaceholder(),
  errorWidget: (context, url, error) => const ErrorPlaceholder(),
)
```

**Why:** Avoids re-downloading the same image every time a card scrolls back into view. The image is stored on disk after the first download, and subsequent renders serve from cache instantly.

### memCacheWidth

`memCacheWidth` is set to match the actual display width of the image widget (approximately 400px on a typical mobile screen):

```dart
memCacheWidth: 400,
```

**Why:** Flutter decodes images at full resolution by default. A 3000×2000 image decoded into a 400px-wide widget wastes ~18× the memory it needs. `memCacheWidth` tells the image decoder to resize the bitmap on decode — before it enters memory — so only the pixels that will actually be displayed are stored in the memory cache.

**Verification:** Used Flutter DevTools' Memory tab to compare heap usage with and without `memCacheWidth`. Without it, scrolling 20 feed items pushed memory usage to ~180MB. With `memCacheWidth: 400`, the same 20 items stabilized around ~60MB — a ~66% reduction. The raster thread frame time also dropped because smaller textures upload to the GPU faster.

### Pagination

The feed loads **10 posts per request**. Supabase's `.range(from, to)` is used to fetch pages:

```dart
supabase
  .from('posts')
  .select()
  .range(page * limit, (page + 1) * limit - 1)
  .order('created_at', ascending: false);
```

This keeps the initial load fast and prevents over-fetching data the user may never scroll to.

### ListView.builder

The feed uses `ListView.builder` instead of `ListView` or `Column`:

```dart
ListView.builder(
  controller: _scrollController,
  itemCount: posts.length + (hasMore ? 1 : 0),
  itemBuilder: (context, index) {
    if (index == posts.length) return const LoadingIndicator();
    return RepaintBoundary(child: FeedCard(post: posts[index]));
  },
)
```

`ListView.builder` lazily creates and destroys widgets as they scroll in and out of the viewport. Only the visible cards exist in memory at any time — cards scrolled past are disposed.

---

## Optimistic Like Flow

Tapping like provides instant feedback without waiting for the server:

```
User taps Like
      ↓
UI updates instantly (local state toggled)
      ↓
800ms debounce timer starts (resets on rapid taps)
      ↓
After 800ms of no further taps → RPC call to Supabase
      ↓
  Success → server state confirmed, local state retained
  Failure → local state reverted, SnackBar error shown
```

**Why debounce?** A user double-tapping or tap-spamming the like button would otherwise fire one RPC call per tap. The 800ms debounce collapses rapid taps into a single call, reducing API load.

**Why optimistic?** Waiting for a network round-trip before updating the UI makes the app feel sluggish. Optimistic updates make it feel native — the server confirmation is a background concern.

---

## Image Loading Strategy

Images are served at different resolutions depending on the context:

```
Feed Screen
    ↓
Thumbnail (low-res, fast load, ~50–100KB)
    ↓ (user taps card)

Detail Screen
    ↓
Mobile Resolution (~400–800px wide, balanced quality)
    ↓ (user taps download)

Download
    ↓
Raw / Full Resolution (original upload quality)
```

This progressive strategy ensures the feed scrolls smoothly (small images), the detail view looks sharp (medium images), and the download gives the user the original (full quality) — without penalizing feed performance with large images.

---

## Tech Stack

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.6.1 | State management |
| `supabase_flutter` | ^2.15.0 | Backend (DB + Storage) |
| `cached_network_image` | ^3.4.1 | Image caching |
| `dio` | ^5.8.0+1 | HTTP client for image download |
| `path_provider` | ^2.1.5 | Local file system paths |
| `permission_handler` | ^12.0.1 | Storage permission for downloads |
| `connectivity_plus` | ^6.1.4 | Network state detection |
| `flutter_animate` | ^4.5.2 | UI animations |
| `flutter_dotenv` | ^6.0.1 | Environment variable loading |

---

## Environment Setup

Create a `.env` file in the project root:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

The `.env` file is declared as a Flutter asset in `pubspec.yaml` and loaded at app startup via `flutter_dotenv`.

> **Note:** Never commit your `.env` file. It is already listed in `.gitignore`.

---

## Supabase Setup

Your Supabase project needs:

1. A `posts` table with columns: `id`, `user_id`, `image_url`, `thumbnail_url`, `caption`, `like_count`, `created_at`
2. A `likes` table with columns: `id`, `user_id`, `post_id`, `created_at`
3. A Supabase Storage bucket for post images (public or signed URLs)
4. An RPC function `toggle_like(post_id uuid)` that atomically toggles the like and updates `like_count`

A seeder script is available in the `seeder/` directory to populate your database with sample posts for development.

---

## Run Instructions

```bash
# Install dependencies
flutter pub get

# Run the app (connect a device or start an emulator first)
flutter run

# Run in profile mode to measure real performance (no JIT overhead)
flutter run --profile
```

---

---

## Demo Video

Link: *(https://drive.google.com/file/d/1w16rwfuu-dxpvOfsVboxHoOhLvWpEFpP/view?usp=sharing)*

---

## Future Improvements

- **Real authentication** — Supabase Auth with email/Google sign-in
- **Comments backend** — comment thread on each post
- **Share functionality** — native share sheet integration
- **Push notifications** — new likes and comments via FCM
- **Realtime updates** — Supabase Realtime subscriptions for live like counts and new posts without pull-to-refresh
- **Offline mode** — cache last-seen feed locally with `sqflite` or `hive`
- **Widget tests** — unit tests for `FeedController` and provider state transitions