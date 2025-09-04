module TextHelper
  include ArabicHelper

  def normalize_for_slug(text, separator: "-")
    super(text, separator)
  end
end
