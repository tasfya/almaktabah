require 'rails_helper'

RSpec.describe AudioPlayerHelper, type: :helper do
  describe "#play_button" do
    let(:resource_with_audio) { double('resource', has_any_audio?: true) }
    let(:resource_without_audio) { double('resource', has_any_audio?: false) }

    context "when resource has any audio" do
      it "renders play button partial with default classes" do
        expect(helper).to receive(:render).with(
          "shared/play_button",
          resource: resource_with_audio,
          klass: "btn btn-secondary w-fit whitespace-nowrap",
          icon_class: "size-4"
        )

        helper.play_button(resource: resource_with_audio)
      end

      it "renders play button partial with custom classes" do
        custom_class = "custom-btn primary"
        custom_icon_class = "custom-icon size-6"

        expect(helper).to receive(:render).with(
          "shared/play_button",
          resource: resource_with_audio,
          klass: custom_class,
          icon_class: custom_icon_class
        )

        helper.play_button(
          resource: resource_with_audio,
          klass: custom_class,
          icon_class: custom_icon_class
        )
      end
    end

    context "when resource has no audio" do
      it "returns nil" do
        result = helper.play_button(resource: resource_without_audio)
        expect(result).to be_nil
      end

      it "does not render the play button partial" do
        expect(helper).not_to receive(:render)
        helper.play_button(resource: resource_without_audio)
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

    context "edge cases" do
      it "handles resource that doesn't respond to has_any_audio?" do
        resource_without_method = double('resource')

        result = helper.play_button(resource: resource_without_method)
        expect(result).to be_nil
      end
    end
  end
end
