import getURL from "discourse/lib/get-url";
import Category from "discourse/models/category";
import { ago } from "./ef-config";

// The lobby and hall pages show recent topics and forum stats, which costs a
// request or two. Results are kept for a minute (also across page refreshes,
// in sessionStorage) and two identical fetches never run at once.
const CACHE_MS = 60 * 1000;
const memory = new Map();

// Plain fetch, so the pages depend on as few Discourse internals as possible
async function getJSON(path) {
  const response = await fetch(getURL(path), {
    credentials: "same-origin",
    headers: {
      Accept: "application/json",
      "X-Requested-With": "XMLHttpRequest",
    },
  });
  if (!response.ok) {
    throw new Error(`${path} returned ${response.status}`);
  }
  return response.json();
}

// The cache is per user: lists differ for staff, so after logging out the
// next visitor in the same tab never gets the previous user's topics.
function storageKey(path, userKey) {
  return `ef-activity:${userKey}:${path}`;
}

function readStored(key) {
  try {
    const stored = JSON.parse(window.sessionStorage.getItem(key));
    if (stored && Date.now() - stored.at < CACHE_MS) {
      return stored;
    }
  } catch {
    // Storage unavailable: fetch instead
  }
  return null;
}

// Only the parts the pages use are kept
function slimList(json) {
  return {
    users: (json.users || []).map((u) => ({
      username: u.username,
      avatar_template: u.avatar_template,
    })),
    topics: (json.topic_list?.topics || []).map((t) => ({
      id: t.id,
      slug: t.slug,
      title: t.title,
      category_id: t.category_id,
      posts_count: t.posts_count,
      highest_post_number: t.highest_post_number,
      last_posted_at: t.last_posted_at,
      bumped_at: t.bumped_at,
      last_poster_username: t.last_poster_username,
    })),
  };
}

function slimAbout(json) {
  return { users_count: json?.about?.stats?.users_count ?? null };
}

function cached(path, userKey, load) {
  const key = storageKey(path, userKey);
  const now = Date.now();
  const hit = memory.get(key);
  if (hit && now - hit.at < CACHE_MS) {
    return hit.promise;
  }

  const stored = readStored(key);
  if (stored) {
    const promise = Promise.resolve(stored.data);
    memory.set(key, { at: stored.at, promise });
    return promise;
  }

  const promise = load().then((data) => {
    try {
      window.sessionStorage.setItem(key, JSON.stringify({ at: now, data }));
    } catch {
      // Storage full or blocked: the in-memory cache still works
    }
    return data;
  });
  memory.set(key, { at: now, promise });
  promise.catch(() => memory.delete(key));
  return promise;
}

export function fetchTopics(path, userKey) {
  return cached(path, userKey, () => getJSON(path).then(slimList));
}

export function fetchAbout(userKey) {
  return cached("/about.json", userKey, () =>
    getJSON("/about.json").then(slimAbout)
  );
}

function avatarFor(template) {
  return template ? getURL(template.replace("{size}", "96")) : null;
}

// Newest activity first, one display object per topic
export function topicRows(list) {
  const users = new Map((list.users || []).map((u) => [u.username, u]));
  return [...(list.topics || [])]
    .sort(
      (a, b) =>
        new Date(b.last_posted_at || b.bumped_at) -
        new Date(a.last_posted_at || a.bumped_at)
    )
    .map((t) => {
      const user = users.get(t.last_poster_username);
      const at = t.last_posted_at || t.bumped_at;
      const category = Category.findById(t.category_id);
      return {
        id: t.id,
        categoryId: t.category_id,
        category,
        title: t.title,
        url: getURL(`/t/${t.slug}/${t.id}/${t.highest_post_number}`),
        user: t.last_poster_username,
        initial: (t.last_poster_username || "?").charAt(0).toUpperCase(),
        avatar: user ? avatarFor(user.avatar_template) : null,
        when: ago(at),
        replies: Math.max(0, (Number(t.posts_count) || 1) - 1),
        categoryName: category?.name,
        // Public categories only: staff-only titles never show in these
        // panels (e.g. on a screenshot or a screen-share)
        isPublic: !!category && !category.read_restricted,
      };
    });
}

// Safety net: if a page is ever re-created over and over in a few seconds
// (a render loop), stop loading data so it cannot hammer the server.
const recentStarts = [];
let loopDetected = false;

export function noteStart() {
  const now = Date.now();
  recentStarts.push(now);
  while (recentStarts.length && now - recentStarts[0] > 4000) {
    recentStarts.shift();
  }
  if (recentStarts.length > 5 && !loopDetected) {
    loopDetected = true;
    // eslint-disable-next-line no-console
    console.error(
      "[Emberfish theme] page was created",
      recentStarts.length,
      "times in 4 seconds; stopping",
      window.location.href
    );
  }
  return loopDetected;
}
