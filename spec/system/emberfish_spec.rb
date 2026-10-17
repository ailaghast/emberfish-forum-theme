# frozen_string_literal: true

# Checks for the parts of the theme that players would notice first if they
# broke, and for the rule that a hidden game leaves nothing in the page.
RSpec.describe "Emberfish theme" do
  let!(:theme) { upload_theme }

  fab!(:admin)
  fab!(:user, :active_user)

  # A public game hall with two forums, a staff-only (unrevealed) one, and
  # Support. A hall is a top-level category with a Background image.
  fab!(:game) do
    Fabricate(
      :category,
      name: "Public Game",
      slug: "public-game",
      uploaded_background: Fabricate(:upload),
      uploaded_logo: Fabricate(:upload),
    )
  end
  fab!(:news) { Fabricate(:category, name: "News", slug: "news", parent_category: game) }
  fab!(:general) do
    Fabricate(:category, name: "General Discussion", slug: "general", parent_category: game)
  end
  fab!(:secret) do
    Fabricate(
      :private_category,
      group: Group[:staff],
      name: "Secret Game",
      slug: "secret-game",
      uploaded_background: Fabricate(:upload),
    )
  end
  fab!(:support) { Fabricate(:category, name: "Support", slug: "support") }
  fab!(:help) { Fabricate(:category, name: "Forum Help", slug: "forum-help", parent_category: support) }
  fab!(:topic) do
    Fabricate(:topic_with_op, category: general, title: "Which hero do you start with")
  end

  def set_theme_setting(name, value)
    theme.update_setting(name, value)
    theme.save!
  end

  describe "lobby" do
    it "shows a door for each game the visitor can see" do
      visit "/"

      expect(page).to have_css(".ef-door", count: 1)
      expect(page).to have_css(".ef-door__art[href='#{game.url}']")
      expect(page).to have_css(".ef-door .ef-btn", text: /enter the hall/i)
    end

    it "shows a game's words and buttons from hall_details" do
      set_theme_setting(
        :hall_details,
        "public-game;Out now;A test pitch.;Buy on Steam;https://store.steampowered.com/app/1/",
      )

      visit "/"

      expect(page).to have_css(".ef-door .ef-tagline", text: /out now/i)
      expect(page).to have_css(".ef-door__pitch", text: "A test pitch.")
      expect(page).to have_link("Buy on Steam", href: "https://store.steampowered.com/app/1/")
    end

    it "leaves a hidden game out of the page entirely" do
      visit "/"

      expect(page).to have_css(".ef-door")
      expect(page).to have_no_css(".ef-halls__link", text: /secret game/i)
      expect(page.html).not_to include("Secret Game")
      expect(page.html).not_to include("secret-game")
    end

    it "shows staff the hidden game's door and tab" do
      sign_in(admin)
      visit "/"

      expect(page).to have_css(".ef-door", count: 2)
      expect(page).to have_css(".ef-halls__link", text: /secret game/i)
    end

    it "lists the latest discussions, public forums only, even for staff" do
      Fabricate(:topic_with_op, category: secret, title: "Reveal plans for the team")

      sign_in(admin)
      visit "/"

      expect(page).to have_css(".ef-topic", text: topic.title)
      expect(page).to have_css(".ef-topic .ef-chip", text: /public game/i)
      expect(page).to have_no_css(".ef-topic", text: /reveal plans for the team/i)
    end

    it "shows the Support forums" do
      visit "/"

      expect(page).to have_css(".ef-support", text: "Forum Help")
    end

    it "counts only public forums in Forum stats, even for staff" do
      Fabricate.times(3, :topic_with_op, category: secret)
      Category.update_stats
      Site.clear_cache
      public_topics = Category.where(read_restricted: false).sum(:topic_count)

      sign_in(admin)
      visit "/"

      stat = find(".ef-stat", text: /topics/i)
      expect(stat).to have_css("dd", exact_text: public_topics.to_s)
    end

    it "shows staff no theme errors" do
      sign_in(admin)
      visit "/"

      expect(page).to have_css(".ef-doors")
      expect(page).to have_no_css(".ef-home-error")
    end
  end

  describe "hall page" do
    before do
      set_theme_setting(:hall_sections, "Official;news|Community;general")
    end

    it "lists the hall's forums in sections under the full banner" do
      visit game.url

      expect(page).to have_css(".ef-hall-banner:not(.ef-hall-banner--slim)")
      expect(page).to have_css(".ef-section .ef-bar__title", text: /official/i)
      expect(page).to have_css(".ef-section .ef-bar__title", text: /community/i)
      expect(page).to have_css(".ef-forum__name", text: "News")
      expect(page).to have_css(".ef-forum__latest", text: topic.title)
      expect(page).to have_css(".ef-halls__link.active", text: /public game/i)
    end

    it "puts forums that fit no section in a last Forums section" do
      Fabricate(:category, name: "Fan Art", slug: "fan-art", parent_category: game)

      visit game.url

      expect(page).to have_css(".ef-section .ef-bar__title", text: /forums/i)
      expect(page).to have_css(".ef-forum__name", text: "Fan Art")
    end

    it "shows a forum with forums of its own (a DLC) as its own section" do
      SiteSetting.max_category_nesting = 3
      set_theme_setting(:hall_sections, "Official;news|*|Community;general")
      dlc = Fabricate(:category, name: "Some DLC", slug: "some-dlc", parent_category: game)
      dlc_general =
        Fabricate(:category, name: "DLC Talk", slug: "general", parent_category: dlc)
      Fabricate(:topic_with_op, category: dlc_general, title: "First run with the new hero")

      visit game.url

      titles = all(".ef-section .ef-bar__title").map { |t| t.text.downcase }
      expect(titles).to eq(["official", "some dlc", "community"])
      expect(page).to have_css(".ef-bar__title a[href='#{dlc.url}']")
      expect(page).to have_css(".ef-forum__name", text: "DLC Talk")
      expect(page).to have_css(".ef-forum__latest", text: "First run with the new hero")
    end

    it "keeps core's topic list inside a forum, under a slim banner" do
      visit general.url

      expect(page).to have_css(".ef-hall-banner--slim")
      expect(page).to have_css(".topic-list", text: topic.title)
      expect(page).to have_no_css(".ef-forum")
    end
  end

  describe "fonts" do
    it "loads them from the forum, not Google Fonts" do
      visit "/"

      expect(page).to have_css(".ef-doors")
      expect(page).to have_no_css("link[href*='fonts.googleapis.com']", visible: :all)
      families = page.evaluate_script("[...document.fonts].map((f) => f.family)")
      expect(families.map { |f| f.delete('"') }).to include("Cinzel", "EB Garamond")
    end
  end

  describe "/categories" do
    it "sends players to the lobby" do
      sign_in(user)
      visit "/categories"

      expect(page).to have_current_path("/")
      expect(page).to have_css(".ef-doors")
    end

    it "stays open for staff" do
      sign_in(admin)
      visit "/categories"

      expect(page).to have_no_css(".ef-doors")
      expect(page).to have_current_path("/categories")
    end
  end

  describe "header" do
    it "shows the Emberfish logo and the top links" do
      visit "/"

      expect(page).to have_css(".d-header .ef-brand__logo")
      within(".ef-header-nav") do
        expect(page).to have_link("Forums")
        expect(page).to have_link("Rules", href: "/guidelines")
        expect(page).to have_link("Website ↗", href: "https://emberfishgames.com")
      end
    end

    it "shows the halls bar with the Lobby, each hall and Support" do
      visit "/"

      expect(page).to have_css(".ef-halls__link.active", text: /lobby/i)
      expect(page).to have_css(".ef-halls__link", text: /public game/i)
      expect(page).to have_css(".ef-halls__link--support", text: /support/i)
    end
  end

  describe "navigation menu" do
    it "hides the category and tag lists" do
      sign_in(user)
      visit "/latest"

      expect(page).to have_css(".sidebar-sections")
      expect(page).to have_no_css(".sidebar-sections [data-section-name='categories']")
      expect(page).to have_no_css(".sidebar-sections [data-section-name='tags']")
    end
  end

  describe "topic page" do
    it "shows the full date in the post's top bar" do
      visit topic.url

      expect(page).to have_css(".topic-post .ef-post-date")
    end

    it "leaves pin notes out of the topic" do
      TopicStatusUpdater.new(topic, admin).update!("pinned", true)

      visit topic.url

      expect(page).to have_css(".topic-post .ef-post-date")
      expect(page).to have_css(".ef-quiet-action", visible: :all)
    end
  end
end
