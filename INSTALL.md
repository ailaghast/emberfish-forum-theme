# Emberfish Ashen Gate theme

The forum theme for forum.emberfishgames.com: warm charcoal panels in thin gold frames with gem corners, crimson header bars, buttons that glow ember orange, Cinzel labels and EB Garamond text (served from the forum, never from Google). It has the structure of the Riverfront and Local Heretics forums, plus a lobby and one hall per game.

The step-by-step setup, install included, is in `../forum-setup.md` (steps 4 and 8). Updating later is in `UPDATING.md`. A static preview of the look is in `../preview/` (rebuild with `node ../tools/make-preview.js`).

## What's in it

- **Header:** the Emberfish Games logo, then Forums · Rules · Website ↗.
- **Halls bar:** Lobby · one tab per game hall · Support.
- **Lobby (homepage):** "The Emberfish Halls", one door per game (art, logo, tagline, pitch, Enter the hall + store button), the announcement bar, Latest discussions from every game, and Support, Forum stats and Share on the right.
- **Hall page** (`/c/<game>`): the game's banner with its buttons, the announcement bar, the tab row (Forums · Latest · New · Top · In · New Topic), the game's forums in sections (Official / Community / a section per DLC / Help us build it) with hero medallions, and Latest posts and Forum stats on the right.
- **Inside a game** (its forums and topics): a slim banner.
- **Posts:** classic author panel on the left on desktop, full date in the post's top bar, Staff tag.
- Players who open /categories land on the lobby. Staff can still use it.

## Where a game's look comes from (secrecy)

**The theme holds no game art and names no game.** Theme files and settings are sent to every visitor, so anything in them could reveal an unannounced game. Everything about a game lives on its **category** instead, and Discourse sends a category's data only to people allowed to see it.

A top-level category becomes a **game hall** as soon as it has a **Background image**. In the category's settings → **Images**:

| Field | What the theme does with it | File (from `../category-images/<game>/`) |
|---|---|---|
| Logo image | Square icon: halls bar, topic chips, category badges | `<game> - Logo (icon).png` |
| Dark logo image | The game's wordmark: banner and lobby door | `<game> - Dark logo (wordmark).webp` |
| Background image | Banner art: hall banner and lobby door | `<game> - Background (banner).webp` |

Each **subcategory**'s Logo image is its medallion (`<slug> - Logo.webp`). Subcategories without one show an icon (`category_icons` setting).

A **DLC** is a subcategory with forums of its own (Hadean Tactics › Moonhunter DLC › General Discussion; needs the site setting `max category nesting` = 3). The hall page shows it as its own section, named after it, where `hall_sections` has its `*` line. Its forums get medallions the same way, and its topics count towards the game's lobby door.

Discourse would normally paint the Background image behind the whole category page and show the Logo above the topic list. The theme turns both off.

The tagline, pitch and store buttons come from the `hall_details` setting, one line per game. **Add a game's line only when the game is public**, because settings are public too. Before then, staff see the hidden game's hall with its art but without those words.

## Theme settings (theme page → Settings)

| Setting | Default |
|---|---|
| `nav_rules_url`, `nav_website_url` | `/guidelines`, `https://emberfishgames.com` |
| `lobby_title`, `lobby_subtitle` | "The Emberfish Halls", "Pick a game to find its news, strategy and feedback." |
| `hall_details` | `slug;tagline;pitch;button;link;button 2;link 2`, one line per game. Hadean Tactics only |
| `support_category` | `support` |
| `hall_sections` | `Section;slug,slug`, one line per section, shared by all games. A line that is just `*` is where DLC sections go |
| `category_icons` | `forum-help:circle-question`, `forum-feedback:comment` |
| `lobby_latest_count` | 6 |
| `share_networks` | `x\|reddit\|facebook\|whatsapp\|weibo\|email` |
| `show_stats`, `hide_profile_location`, `hide_profile_bio`, `content_width` | on, on, off, 1280 |

Black Flame's line for reveal day:

```
black-flame;Coming 2027 · Free demo out now;Lead your company down the circles and steal the Black Flame.;Wishlist on Steam;https://store.steampowered.com/app/3382760/Hadean_Tactics_Black_Flame/
```

## Changing the art

`node ../tools/build-assets.js` rebuilds `assets/` (logo, swirl mark, fonts), `../category-images/` and `../branding/` from the original art. After it runs, re-upload any changed category image in that category's settings.
