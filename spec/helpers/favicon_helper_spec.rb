require 'rails_helper'

RSpec.describe FaviconHelper, type: :helper do
  let(:domain) { create(:domain) }

  before do
    @domain = domain
    allow(helper).to receive(:site_info).and_return({ name: 'Test Site' })
  end

  describe '#favicon_ico_url' do
    context 'when domain has favicon_ico attached' do
      let(:favicon_file) { fixture_file_upload('spec/files/favicon.ico', 'image/x-icon') }

      before do
        domain.favicon_ico.attach(favicon_file)
        allow(helper).to receive(:url_for).with(domain.favicon_ico).and_return('/favicon_url.ico')
      end

      it 'returns the URL for the attached favicon' do
        expect(helper.favicon_ico_url).to eq('/favicon_url.ico')
      end
    end

    context 'when domain has no favicon_ico attached' do
      it 'returns nil' do
        expect(helper.favicon_ico_url).to be_nil
      end
    end

    context 'when @domain is nil' do
      before { @domain = nil }

      it 'returns nil' do
        expect(helper.favicon_ico_url).to be_nil
      end
    end
  end

  describe '#favicon_png_url' do
    context 'when domain has favicon_png attached' do
      let(:favicon_file) { fixture_file_upload('spec/files/icon.png', 'image/png') }

      before do
        domain.favicon_png.attach(favicon_file)
        allow(helper).to receive(:url_for).with(domain.favicon_png).and_return('/favicon_url.png')
      end

      it 'returns the URL for the attached favicon' do
        expect(helper.favicon_png_url).to eq('/favicon_url.png')
      end
    end

    context 'when domain has no favicon_png attached' do
      it 'returns nil' do
        expect(helper.favicon_png_url).to be_nil
      end
    end
  end

  describe '#favicon_svg_url' do
    context 'when domain has favicon_svg attached' do
      let(:favicon_file) { fixture_file_upload('spec/files/icon.svg', 'image/svg+xml') }

      before do
        domain.favicon_svg.attach(favicon_file)
        allow(helper).to receive(:url_for).with(domain.favicon_svg).and_return('/favicon_url.svg')
      end

      it 'returns the URL for the attached favicon' do
        expect(helper.favicon_svg_url).to eq('/favicon_url.svg')
      end
    end

    context 'when domain has no favicon_svg attached' do
      it 'returns nil' do
        expect(helper.favicon_svg_url).to be_nil
      end
    end
  end

  describe '#apple_touch_icon_url' do
    context 'when domain has apple_touch_icon attached' do
      let(:icon_file) { fixture_file_upload('spec/files/apple-touch-icon.png', 'image/png') }

      before do
        domain.apple_touch_icon.attach(icon_file)
        allow(helper).to receive(:url_for).with(domain.apple_touch_icon).and_return('/apple_touch_icon_url.png')
      end

      it 'returns the URL for the attached apple touch icon' do
        expect(helper.apple_touch_icon_url).to eq('/apple_touch_icon_url.png')
      end
    end

    context 'when domain has no apple_touch_icon attached' do
      it 'returns nil' do
        expect(helper.apple_touch_icon_url).to be_nil
      end
    end
  end

  describe '#favicon_link_tags' do
    before do
      allow(helper).to receive(:favicon_ico_url).and_return('/favicon.ico')
      allow(helper).to receive(:favicon_png_url).and_return('/favicon.png')
      allow(helper).to receive(:favicon_svg_url).and_return('/favicon.svg')
      allow(helper).to receive(:apple_touch_icon_url).and_return('/apple-touch-icon.png')
    end

    it 'generates favicon link tags' do
      result = helper.favicon_link_tags

      expect(result).to include('<link rel="icon" href="/favicon.ico" type="image/x-icon">')
      expect(result).to include('<link rel="icon" href="/favicon.png" type="image/png">')
      expect(result).to include('<link rel="icon" href="/favicon.svg" type="image/svg+xml">')
    end

    it 'generates apple touch icon link tags with various sizes' do
      result = helper.favicon_link_tags

      expect(result).to include('<link rel="apple-touch-icon" href="/apple-touch-icon.png" sizes="180x180">')
      expect(result).to include('<link rel="apple-touch-icon" href="/apple-touch-icon.png" sizes="152x152">')
      expect(result).to include('<link rel="apple-touch-icon" href="/apple-touch-icon.png" sizes="144x144">')
      expect(result).to include('<link rel="apple-touch-icon" href="/apple-touch-icon.png" sizes="120x120">')
      expect(result).to include('<link rel="apple-touch-icon" href="/apple-touch-icon.png" sizes="114x114">')
      expect(result).to include('<link rel="apple-touch-icon" href="/apple-touch-icon.png" sizes="76x76">')
      expect(result).to include('<link rel="apple-touch-icon" href="/apple-touch-icon.png" sizes="72x72">')
      expect(result).to include('<link rel="apple-touch-icon" href="/apple-touch-icon.png" sizes="60x60">')
      expect(result).to include('<link rel="apple-touch-icon" href="/apple-touch-icon.png" sizes="57x57">')
    end

    it 'generates Android Chrome icon link tags' do
      result = helper.favicon_link_tags

      expect(result).to include('<link rel="icon" href="/favicon.png" sizes="192x192" type="image/png">')
      expect(result).to include('<link rel="icon" href="/favicon.png" sizes="32x32" type="image/png">')
      expect(result).to include('<link rel="icon" href="/favicon.png" sizes="16x16" type="image/png">')
    end

    it 'generates PWA meta tags for iOS optimization' do
      result = helper.favicon_link_tags

      expect(result).to include('<meta name="apple-mobile-web-app-capable" content="yes">')
      expect(result).to include('<meta name="apple-mobile-web-app-status-bar-style" content="default">')
      expect(result).to include('<meta name="apple-mobile-web-app-title" content="Test Site">')
    end

    it 'returns HTML safe string' do
      result = helper.favicon_link_tags
      expect(result).to be_html_safe
    end

    context 'when favicon URLs are nil' do
      before do
        allow(helper).to receive(:favicon_ico_url).and_return(nil)
        allow(helper).to receive(:favicon_png_url).and_return(nil)
        allow(helper).to receive(:favicon_svg_url).and_return(nil)
        allow(helper).to receive(:apple_touch_icon_url).and_return(nil)
      end

      it 'still generates link tags with nil hrefs' do
        result = helper.favicon_link_tags

        expect(result).to include('<link rel="icon" type="image/x-icon">')
        expect(result).to include('<link rel="icon" type="image/png">')
        expect(result).to include('<link rel="icon" type="image/svg+xml">')
        expect(result).to include('<link rel="apple-touch-icon" sizes="180x180">')
      end

      it 'still generates PWA meta tags' do
        result = helper.favicon_link_tags

        expect(result).to include('<meta name="apple-mobile-web-app-capable" content="yes">')
        expect(result).to include('<meta name="apple-mobile-web-app-status-bar-style" content="default">')
        expect(result).to include('<meta name="apple-mobile-web-app-title" content="Test Site">')
      end
    end
  end
end
