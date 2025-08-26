require 'rails_helper'

RSpec.describe ArabicSluggable, type: :concern do
  # Create a dummy class to test the concern
  let(:dummy_class) do
    Class.new do
      include ArabicSluggable
    end
  end

  let(:dummy_instance) { dummy_class.new }

  describe '#slugify_arabic_advanced' do
    context 'with Arabic text' do
      it 'converts Arabic text to slug' do
        result = dummy_instance.slugify_arabic_advanced('المتنبي والشعر العربي')
        expect(result).to eq('المتنبي-والشعر-العربي')
      end

      it 'handles mixed Arabic and numbers' do
        result = dummy_instance.slugify_arabic_advanced('الدرس 123 في الفقه')
        expect(result).to eq('الدرس-123-في-الفقه')
      end

      it 'handles text with multiple spaces' do
        result = dummy_instance.slugify_arabic_advanced('النص    مع     مسافات    كثيرة')
        expect(result).to eq('النص-مع-مسافات-كثيرة')
      end

      it 'handles underscores' do
        result = dummy_instance.slugify_arabic_advanced('النص_مع_خطوط_سفلية')
        expect(result).to eq('النص-مع-خطوط-سفلية')
      end

      it 'removes consecutive hyphens' do
        result = dummy_instance.slugify_arabic_advanced('النص---مع---خطوط---متعددة')
        expect(result).to eq('النص-مع-خطوط-متعددة')
      end

      it 'removes leading and trailing hyphens' do
        result = dummy_instance.slugify_arabic_advanced('---النص مع خطوط في البداية والنهاية---')
        expect(result).to eq('النص-مع-خطوط-في-البداية-والنهاية')
      end
    end

    context 'with edge cases' do
      it 'returns nil for nil input' do
        result = dummy_instance.slugify_arabic_advanced(nil)
        expect(result).to be_nil
      end

      it 'returns nil for empty string' do
        result = dummy_instance.slugify_arabic_advanced('')
        expect(result).to be_nil
      end

      it 'returns nil for blank string' do
        result = dummy_instance.slugify_arabic_advanced('   ')
        expect(result).to be_nil
      end

      it 'handles only numbers' do
        result = dummy_instance.slugify_arabic_advanced('123456')
        expect(result).to eq('123456')
      end
    end

    context 'with real-world examples' do
      it 'handles book titles' do
        result = dummy_instance.slugify_arabic_advanced('صحيح البخاري - كتاب الإيمان')
        expect(result).to eq('صحيح-البخاري-كتاب-الإيمان')
      end

      it 'handles scholar names' do
        result = dummy_instance.slugify_arabic_advanced('الشيخ محمد بن عثيمين')
        expect(result).to eq('الشيخ-محمد-بن-عثيمين')
      end

      it 'handles lesson titles with numbers' do
        result = dummy_instance.slugify_arabic_advanced('الدرس الأول - الفقه الإسلامي')
        expect(result).to eq('الدرس-الأول-الفقه-الإسلامي')
      end
      it 'handles text with diacritics (removes them)' do
        result = dummy_instance.slugify_arabic_advanced('النَّصُّ العَرَبِيُّ')
        # The method removes Arabic diacritics and normalizes the text
        expect(result).to eq('النص-العربي')
      end
    end
  end
end
