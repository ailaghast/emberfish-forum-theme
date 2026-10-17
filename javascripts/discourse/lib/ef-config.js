import { getURLWithCDN } from "discourse/lib/get-url";
import Category from "discourse/models/category";

// Theme list settings arrive as "a|b|c" strings.
export function splitList(value) {
  return (value || "")
    .split("|")
    .map((s) => s.trim())
    .filter(Boolean);
}

// "slug:value|slug:value" -> Map
export function pairs(value) {
  const map = new Map();
  splitList(value).forEach((entry) => {
    const i = entry.indexOf(":");
    if (i > 0) {
      map.set(entry.slice(0, i).trim(), entry.slice(i + 1).trim());
    }
  });
  return map;
}

export function uploadUrl(upload) {
  return upload?.url ? getURLWithCDN(upload.url) : null;
}

export function findTopLevel(slug) {
  return Category.list().find((c) => c.slug === slug && !c.parent_category_id);
}

export function topLevelOf(category) {
  let c = category;
  while (c?.parentCategory) {
    c = c.parentCategory;
  }
  return c || null;
}

// True when the category is the top-level category `slug` or sits inside it.
export function isWithin(category, slug) {
  const top = topLevelOf(category);
  return !!top && top.slug === slug;
}

export function childrenOf(parent) {
  return Category.list().filter((c) => c.parent_category_id === parent.id);
}

// Every category inside `parent`, at any depth (a game's DLC holds forums too)
export function descendantsOf(parent) {
  return childrenOf(parent).flatMap((c) => [c, ...descendantsOf(c)]);
}

// "slug;tagline;pitch;label;url;label;url" lines from hall_details
function hallDetails(themeSettings) {
  const map = new Map();
  splitList(themeSettings.hall_details).forEach((line) => {
    const [slug, tagline, pitch, label1, url1, label2, url2] = line
      .split(";")
      .map((s) => (s || "").trim());
    if (!slug) {
      return;
    }
    const buttons = [
      [label1, url1],
      [label2, url2],
    ]
      .filter(([label, url]) => label && url)
      .map(([label, url]) => ({ label, url }));
    map.set(slug, { tagline, pitch, buttons });
  });
  return map;
}

// A game hall is a top-level category with a Background image (its banner
// art). Halls come only from the categories this visitor can see, so a game
// whose category is staff-only has no hall, tab or door for anyone else.
// Its art lives in the category's Images, never in the theme's own files.
export function halls(themeSettings) {
  const details = hallDetails(themeSettings);
  return Category.list()
    .filter(
      (c) =>
        !c.parent_category_id &&
        c.slug !== themeSettings.support_category &&
        c.uploaded_background?.url
    )
    .map((category) => {
      const extra = details.get(category.slug) || {};
      const all = [category, ...descendantsOf(category)];
      const sum = (key) => all.reduce((n, c) => n + (Number(c[key]) || 0), 0);
      return {
        category,
        id: category.id,
        slug: category.slug,
        name: category.name,
        url: category.url,
        color: `#${category.color}`,
        icon: uploadUrl(category.uploaded_logo),
        wordmark: uploadUrl(category.uploaded_logo_dark),
        banner: uploadUrl(category.uploaded_background),
        tagline: extra.tagline || "",
        pitch: extra.pitch || category.description_text || "",
        buttons: extra.buttons || [],
        topicCount: sum("topic_count"),
        postCount: sum("post_count"),
      };
    });
}

export function hallFor(category, themeSettings) {
  const top = topLevelOf(category);
  if (!top) {
    return null;
  }
  return halls(themeSettings).find((h) => h.id === top.id) || null;
}

// One hall_sections line: "Section name;slug,slug"
function sectionLine(entry) {
  const [name, slugs] = entry.split(";").map((s) => (s || "").trim());
  return {
    name,
    slugs: (slugs || "")
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean),
  };
}

// The hall page's sections. hall_sections lists slugs for every game; each
// hall takes the ones it has. A forum that holds forums of its own (a DLC) is
// a section of its own, named after it and linking to it, at the "*" line
// (after the other sections if there's none); its forums follow the slug
// order of all the lines. The hall's other forums go in a last "Forums"
// section.
export function hallSections(hall, themeSettings) {
  const entries = splitList(themeSettings.hall_sections);
  const order = entries
    .filter((e) => e !== "*")
    .flatMap((e) => sectionLine(e).slugs);
  const rank = (c) => {
    const i = order.indexOf(c.slug);
    return i < 0 ? order.length : i;
  };

  const children = childrenOf(hall.category);
  const groups = [];
  const forums = [];
  children.forEach((c) => {
    const inner = childrenOf(c);
    if (inner.length) {
      groups.push({
        name: c.name,
        url: c.url,
        categories: [...inner].sort((a, b) => rank(a) - rank(b)),
      });
    } else {
      forums.push(c);
    }
  });

  const used = new Set();
  const sections = [];
  let groupsPlaced = false;
  entries.forEach((entry) => {
    if (entry === "*") {
      sections.push(...groups);
      groupsPlaced = true;
      return;
    }
    const { name, slugs } = sectionLine(entry);
    const categories = slugs
      .map((slug) => forums.find((c) => c.slug === slug))
      .filter((c) => c && !used.has(c.id));
    categories.forEach((c) => used.add(c.id));
    if (name && categories.length) {
      sections.push({ name, categories });
    }
  });
  if (!groupsPlaced) {
    sections.push(...groups);
  }

  const rest = forums.filter((c) => !used.has(c.id));
  if (rest.length) {
    sections.push({ name: "Forums", categories: rest });
  }
  return sections;
}

export function fmtNumber(value) {
  const n = Number(value) || 0;
  if (n >= 1000) {
    return `${(n / 1000).toFixed(n >= 10000 ? 0 : 1)}k`;
  }
  return String(n);
}

export function ago(date) {
  if (!date) {
    return "";
  }
  const minutes = Math.max(0, (Date.now() - new Date(date).getTime()) / 60000);
  if (minutes < 1) {
    return "just now";
  }
  if (minutes < 60) {
    return `${Math.floor(minutes)}m ago`;
  }
  const hours = minutes / 60;
  if (hours < 24) {
    return `${Math.floor(hours)}h ago`;
  }
  const days = hours / 24;
  if (days < 30) {
    return `${Math.floor(days)}d ago`;
  }
  return new Date(date).toLocaleDateString();
}
