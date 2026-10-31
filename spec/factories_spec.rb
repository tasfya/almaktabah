# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Factories" do
  it "builds a valid record from every factory and trait" do
    expect { FactoryBot.lint(traits: true) }.not_to raise_error
  end
end
