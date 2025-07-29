require 'rails_helper'

RSpec.describe AudioPlayerHelper, type: :helper do
  describe "#play_button" do
    let(:lesson) { create(:lesson, published: true) }
    let(:lecture) { create(:lecture, published: true) }
    let(:benefit) { create(:benefit, published: true) }

    context "when resource has optimized_audio" do
      before do
        # Mock optimized_audio attachment
        allow(lesson).to receive(:optimized_audio).and_return(double(present?: true))
      end

      it "renders play button partial with default classes" do
        expect(helper).to receive(:render).with(
          "shared/play_button",
          resource: lesson,
          klass: "btn btn-secondary w-fit",
          icon_class: "size-4"
        )

        helper.play_button(resource: lesson)
      end

      it "renders play button partial with custom classes" do
        custom_class = "custom-btn primary"
        custom_icon_class = "custom-icon size-6"

        expect(helper).to receive(:render).with(
          "shared/play_button",
          resource: lesson,
          klass: custom_class,
          icon_class: custom_icon_class
        )

        helper.play_button(
          resource: lesson,
          klass: custom_class,
          icon_class: custom_icon_class
        )
      end

      it "accepts different resource types with optimized_audio" do
        allow(lecture).to receive(:optimized_audio).and_return(double(present?: true))
        allow(benefit).to receive(:optimized_audio).and_return(double(present?: true))

        expect(helper).to receive(:render).with(
          "shared/play_button",
          resource: lecture,
          klass: "btn btn-secondary w-fit",
          icon_class: "size-4"
        )

        helper.play_button(resource: lecture)

        expect(helper).to receive(:render).with(
          "shared/play_button",
          resource: benefit,
          klass: "btn btn-secondary w-fit",
          icon_class: "size-4"
        )

        helper.play_button(resource: benefit)
      end
    end

    context "when resource has no optimized_audio" do
      before do
        allow(lesson).to receive(:optimized_audio).and_return(double(present?: false))
      end

      it "returns nil" do
        result = helper.play_button(resource: lesson)
        expect(result).to be_nil
      end

      it "does not render the play button partial" do
        expect(helper).not_to receive(:render)
        helper.play_button(resource: lesson)
      end
    end

    context "when resource is nil" do
      it "returns nil" do
        result = helper.play_button(resource: nil)
        expect(result).to be_nil
      end

      it "does not render the play button partial" do
        expect(helper).not_to receive(:render)
        helper.play_button(resource: nil)
      end
    end

    context "when optimized_audio is nil" do
      before do
        allow(lesson).to receive(:optimized_audio).and_return(nil)
      end

      it "returns nil" do
        result = helper.play_button(resource: lesson)
        expect(result).to be_nil
      end

      it "does not render the play button partial" do
        expect(helper).not_to receive(:render)
        helper.play_button(resource: lesson)
      end
    end

    context "integration with actual optimized_audio attachment" do
      let(:lesson_with_audio) { create(:lesson, published: true) }
      let(:lesson_without_audio) { create(:lesson, published: true) }

      before do
        # Create a real optimized_audio attachment for the lesson
        lesson_with_audio.optimized_audio.attach(
          io: File.open(Rails.root.join('spec', 'files', 'audio.mp3')),
          filename: 'optimized_audio.mp3',
          content_type: 'audio/mpeg'
        )
      end

      it "renders play button when optimized_audio attachment exists" do
        expect(lesson_with_audio.optimized_audio).to be_present

        expect(helper).to receive(:render).with(
          "shared/play_button",
          resource: lesson_with_audio,
          klass: "btn btn-secondary w-fit",
          icon_class: "size-4"
        )

        helper.play_button(resource: lesson_with_audio)
      end

      it "returns nil when no optimized_audio attachment exists" do
        expect(lesson_without_audio.optimized_audio).not_to be_present

        result = helper.play_button(resource: lesson_without_audio)
        expect(result).to be_nil
      end
    end

    context "with edge cases" do
      it "handles resource with optimized_audio method returning false" do
        resource_mock = double
        allow(resource_mock).to receive(:optimized_audio).and_return(double(present?: false))

        result = helper.play_button(resource: resource_mock)
        expect(result).to be_nil
      end
      
      it "preserves parameter names in render call" do
        allow(lesson).to receive(:optimized_audio).and_return(double(present?: true))

        expect(helper).to receive(:render).with(
          "shared/play_button",
          resource: lesson,
          klass: "btn btn-secondary w-fit",
          icon_class: "size-4"
        )

        helper.play_button(resource: lesson)
      end
    end
  end
end
