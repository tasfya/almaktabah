# Rich text (ActionText) and Avo's Trix fields (`sanitize`) render admin- and
# import-supplied HTML through rails-html-sanitizer's default allowlist, which
# has no SVG elements, no `style` attribute and drops `javascript:` hrefs. That
# allowlist is what keeps the SVG-reference, CSS and javascript-URI advisories
# in loofah, rails-html-sanitizer and crass from reaching us; these examples
# fail if it is widened.
require "rails_helper"

RSpec.describe "HTML sanitization of rich text", type: :helper do
  payloads = {
    "an SVG <use> with an external href" => '<p>kept</p><svg><use href="https://evil.example/x.svg#a"></use></svg>',
    "an SVG <feImage> with an external href" => '<p>kept</p><svg><filter><feImage href="https://evil.example/t.png"/></filter></svg>',
    "a style attribute smuggling CSS through a bad url" => '<p style="color: rgb(url(a\\\\)); position: fixed">kept</p>',
    "a javascript: href split by &Tab;" => '<a href="java&Tab;script:alert(1)">kept</a>',
    "a javascript: href with a numeric reference without semicolon" => '<a href="javascript&#58alert(1)">kept</a>'
  }

  def expect_stripped(html)
    fragment = Nokogiri::HTML5.fragment(html)
    expect(fragment.text).to include("kept")
    expect(fragment.css("svg, use, feimage, feImage, [style], a[href]")).to be_empty
  end

  payloads.each do |label, html|
    it "strips #{label} from rendered ActionText content" do
      expect_stripped(ActionText::Content.new(html).to_s)
    end

    it "strips #{label} from the default sanitize helper Avo uses" do
      expect_stripped(helper.sanitize(html))
    end
  end

  it "drops an external href on SVG <use> even when the allowlist permits it" do
    html = helper.sanitize('<svg><use href="https://evil.example/x.svg#a"></use></svg>',
                           tags: %w[svg use], attributes: %w[href])

    expect(Nokogiri::HTML5.fragment(html).css("use")).to be_present
    expect(Nokogiri::HTML5.fragment(html).css("use[href]")).to be_empty
  end
end
