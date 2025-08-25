require 'rails_helper'

RSpec.describe Domain, type: :model do
  subject(:domain) { build(:domain) }

  describe 'associations' do
    it { should have_one_attached(:logo) }
    it { should have_one_attached(:art_work) }
    it { should have_one_attached(:favicon_ico) }
    it { should have_one_attached(:favicon_png) }
    it { should have_one_attached(:favicon_svg) }
    it { should have_one_attached(:apple_touch_icon) }
    it { should have_many(:domain_assignments).dependent(:destroy) }
  end

  describe 'class methods' do
    describe '.find_by_host' do
      let!(:domain1) { create(:domain, host: 'example.com') }
      let!(:domain2) { create(:domain, host: 'test.com') }

      it 'finds domain by host' do
        expect(Domain.find_by_host('example.com')).to eq(domain1)
        expect(Domain.find_by_host('test.com')).to eq(domain2)
      end

      it 'returns nil for non-existent host' do
        expect(Domain.find_by_host('nonexistent.com')).to be_nil
      end
    end
  end

  describe 'instance methods' do
    let(:domain) { create(:domain) }

    describe '#assigned_items' do
      it 'returns domain assignments with includes' do
        expect(domain.assigned_items).to be_a(ActiveRecord::Relation)
      end
    end

    describe '#has_custom_css?' do
      it 'returns true when custom_css is present' do
        domain.custom_css = 'body { color: red; }'
        expect(domain.has_custom_css?).to be true
      end

      it 'returns false when custom_css is blank' do
        domain.custom_css = ''
        expect(domain.has_custom_css?).to be false
      end
    end

    describe '#has_custom_favicons?' do
      let(:favicon_ico_file) { fixture_file_upload('spec/files/favicon.ico', 'image/x-icon') }
      let(:favicon_png_file) { fixture_file_upload('spec/files/icon.png', 'image/png') }
      let(:favicon_svg_file) { fixture_file_upload('spec/files/icon.svg', 'image/svg+xml') }
      let(:apple_touch_icon_file) { fixture_file_upload('spec/files/apple-touch-icon.png', 'image/png') }

      context 'when no favicons are attached' do
        it 'returns false' do
          expect(domain.has_custom_favicons?).to be false
        end
      end

      context 'when favicon_ico is attached' do
        before { domain.favicon_ico.attach(favicon_ico_file) }

        it 'returns true' do
          expect(domain.has_custom_favicons?).to be true
        end
      end

      context 'when favicon_png is attached' do
        before { domain.favicon_png.attach(favicon_png_file) }

        it 'returns true' do
          expect(domain.has_custom_favicons?).to be true
        end
      end

      context 'when favicon_svg is attached' do
        before { domain.favicon_svg.attach(favicon_svg_file) }

        it 'returns true' do
          expect(domain.has_custom_favicons?).to be true
        end
      end

      context 'when apple_touch_icon is attached' do
        before { domain.apple_touch_icon.attach(apple_touch_icon_file) }

        it 'returns true' do
          expect(domain.has_custom_favicons?).to be true
        end
      end

      context 'when multiple favicons are attached' do
        before do
          domain.favicon_ico.attach(favicon_ico_file)
          domain.favicon_png.attach(favicon_png_file)
        end

        it 'returns true' do
          expect(domain.has_custom_favicons?).to be true
        end
      end
    end

    describe '#should_auto_generate_favicons?' do
      let(:logo_file) { fixture_file_upload('spec/files/logo.png', 'image/png') }
      let(:favicon_ico_file) { fixture_file_upload('spec/files/favicon.ico', 'image/x-icon') }

      context 'when logo is attached and no custom favicons' do
        before { domain.logo.attach(logo_file) }

        it 'returns true' do
          expect(domain.should_auto_generate_favicons?).to be true
        end
      end

      context 'when logo is not attached' do
        it 'returns false' do
          expect(domain.should_auto_generate_favicons?).to be false
        end
      end

      context 'when logo is attached but custom favicons exist' do
        before do
          domain.logo.attach(logo_file)
          domain.favicon_ico.attach(favicon_ico_file)
        end

        it 'returns false' do
          expect(domain.should_auto_generate_favicons?).to be false
        end
      end

      context 'when no logo and no custom favicons' do
        it 'returns false' do
          expect(domain.should_auto_generate_favicons?).to be false
        end
      end
    end
  end
end
