require "rails_helper"

RSpec.describe TelegramImport::TextCleaner do
  it "drops invisible marks and collapses every kind of space" do
    expect(described_class.clean("‌‏شرح  الأصول\tالستة (1) ")).to eq("شرح الأصول الستة (1)")
  end

  it "keeps line breaks" do
    expect(described_class.clean("سطر\nسطر")).to eq("سطر\nسطر")
  end

  it "removes quote marks from titles" do
    expect(described_class.title("متن رسالة \" واجبنا نحو ما أمرنا الله \"")).to eq("متن رسالة واجبنا نحو ما أمرنا الله")
  end

  it "reads Arabic-Indic digits as numbers" do
    expect(described_class.numbers("من الدرس ١٧ إلى ٣٠")).to eq([ 17, 30 ])
  end
end
