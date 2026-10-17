# Updating the theme from GitHub

The theme lives in a private GitHub repo (`emberfish/emberfish-forum-theme`). The forum pulls new versions from it, so you never delete or re-upload the theme.

## Branches: staging first, then live

The repo has two branches, and the forum has one theme for each:

| Branch    | Theme on the forum                              | Who sees it               |
| --------- | ----------------------------------------------- | ------------------------- |
| `staging` | **Emberfish Ashen Gate (staging)**          | Only you, through Preview |
| `main`    | **Emberfish Ashen Gate**                    | Everyone                  |

Every change goes to `staging` first. Nothing is pushed straight to `main`.

## Every update (5 min)

1. Claude (or you) commits the change on `staging` and pushes it.
2. GitHub runs the tests (repo → **Actions** tab). It takes about 15 minutes. A green check means they passed. A red cross means something broke. Don't take it live until it's fixed.
3. On the forum, go to **Admin → Appearance → Themes & components**, open **Emberfish Ashen Gate (staging)**, then click **Check for updates** and **Update to latest version**.
4. Click **Preview** and check the change on real pages: the homepage, a category, a topic, and whatever the change touched. Only your browser sees the preview.
5. When it looks right, merge `staging` into `main` and push:
   ```
   git switch main
   git merge --ff-only staging
   git push
   git switch staging
   ```
   On the forum, open **Emberfish Ashen Gate** (the live one) and click **Check for updates** → **Update to latest version**.

The two themes keep separate settings. You can try a setting on staging without touching live. If you want to keep it, set it on the live theme too.

A theme installed from GitHub can't be edited in the admin panel's CSS/HTML editor. Make every change in this folder and push it.

**Before every commit**, run the code-style check: `npx -y pnpm@10 lint` (run `npx -y pnpm@10 install` first if `package.json` changed).

## Changing the art

The theme's images and fonts (`assets/`), the category images (`../category-images/`) and the branding files are made by `node ../tools/build-assets.js` from the studio's art. If the art changes, run it again rather than editing the files by hand. To check the look before pushing, run `node ../tools/make-preview.js`, then `sh ../tools/render-preview.sh lobby 1500` (or `hall`, `topic`), and look at the PNGs in `../preview/`.

## What the tests check

The tests live in `spec/system/`. GitHub runs them in a throwaway Discourse with fake users and topics, so they never touch the real forum.

- `core_features_spec.rb`: Discourse's own check that logging in, profiles and search still work with the theme.
- `emberfish_spec.rb`: the lobby doors (only for games the visitor can see, and a hidden game appears nowhere in the page), the hall page sections and banners, latest discussions and Forum stats (public forums only), the self-hosted fonts, the /categories redirect for players, the header links and halls bar, the hidden category and tag lists in the menu, and the topic page's date bar and hidden pin notes.

If you change the website link (`nav_website_url`) or the banner button text, update the matching test in `emberfish_spec.rb` in the same commit.

The repo is private, so tests use GitHub's free Actions minutes (2,000 a month, shared with the other forums' themes). One run takes about 15–20 minutes. Edits that only change `.md` files don't start a run.
