require 'rails_helper'
RSpec.describe Book, type: :model do
  let(:scholar) { create(:scholar) }
  
  describe "associations" do
    it { should belong_to(:author).class_name("Scholar").with_foreign_key("author_id") }
    it { should have_one_attached(:file) }
    it { should have_one_attached(:cover_image) }
  end

  describe "validations" do
    it { should validate_presence_of(:author) }
  end

  describe "attachments" do
    it "can attach a file" do
      book = Book.new(author: scholar)
      book.file.attach(io: File.open(Rails.root.join('spec', 'files', 'sample.pdf')), filename: 'sample.pdf', content_type: 'application/pdf')
      expect(book.file).to be_attached
    end

    it "can attach a cover image" do
      book = Book.new(author: scholar)
      book.cover_image.attach(io: File.open(Rails.root.join('spec', 'files', 'thumbnail.jpg')), filename: 'thumbnail.jpg', content_type: 'image/jpeg')
      expect(book.cover_image).to be_attached
    end
  end
end
