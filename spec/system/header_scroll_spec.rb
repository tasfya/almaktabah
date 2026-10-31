require "rails_helper"

# The sticky header compacts once the page is scrolled. When compacting changed
# the header's in-flow height, the content jumped up, scroll anchoring pulled
# scrollY back under the threshold, the header expanded again, and a gesture
# made of small scroll steps (Firefox on Android) could never leave the top.
RSpec.describe "Header scroll", type: :system, js: true do
  let!(:domain) { create(:domain, host: "www.example.com") }

  def header_state(pw)
    pw.evaluate(<<~JS)
      () => {
        const header = document.querySelector("header");
        return { compact: !!document.querySelector(".header--compact"), height: header.offsetHeight };
      }
    JS
  end

  [ [ 820, 1180 ], [ 600, 1000 ] ].each do |width, height|
    it "lets the page scroll down in small steps at #{width}x#{height}" do
      visit about_path

      page.driver.with_playwright_page do |pw|
        pw.viewport_size = { width: width, height: height }
        pw.evaluate(<<~JS)
          () => {
            const spacer = document.createElement("div");
            spacer.style.height = "4000px";
            document.querySelector("main").appendChild(spacer);
          }
        JS
        expanded = header_state(pw)
        expect(pw.evaluate(<<~JS)).to eq(expanded["height"])
          () => document.querySelector("[data-header-scroll-target=spacer]").offsetHeight
        JS

        # Without compiled CSS the header never shrinks and the trap can't occur,
        # so make sure compacting really changes the header before testing it.
        pw.evaluate("() => window.scrollTo(0, 400)")
        pw.wait_for_timeout(100)
        compacted = header_state(pw)
        expect(compacted["compact"]).to be(true)
        expect(compacted["height"]).to be < expanded["height"]

        pw.evaluate("() => window.scrollTo(0, 0)")
        pw.wait_for_timeout(100)
        expect(header_state(pw)["compact"]).to be(false)

        pw.mouse.move(width / 2, height / 2)
        30.times do
          pw.mouse.wheel(0, 15)
          pw.wait_for_timeout(50)
        end

        expect(pw.evaluate("() => window.scrollY")).to be > 300
      end
    end
  end
end
