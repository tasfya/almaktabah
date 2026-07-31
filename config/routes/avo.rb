# frozen_string_literal: true

# Custom Avo routes for tools
authenticate :user do
  scope "/avo/tools", module: "avo/tools" do
    get "mimham_import", to: "mimham_import#index", as: :avo_tool_mimham_import
    post "mimham_import/import", to: "mimham_import#import", as: :avo_tool_mimham_import_import
  end
end
