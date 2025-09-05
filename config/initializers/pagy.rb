# Pagy initializer file (config/initializers/pagy.rb)
# Encoding: utf-8
# frozen_string_literal: true

# Pagy DEFAULT configuration
Pagy::DEFAULT[:limit]       = 12    # items per page
Pagy::DEFAULT[:limit_max]       = 100
Pagy::DEFAULT[:size]        = [ 1, 4, 4, 1 ] # nav bar links
Pagy::DEFAULT[:page_param]  = :page # page parameter name
Pagy::DEFAULT[:params]      = {}    # params for links

# Load Pagy extras
require "pagy/extras/array"
require "pagy/extras/headers"
require "pagy/extras/limit"
require "pagy/extras/overflow"

# Handle overflow pages
Pagy::DEFAULT[:overflow] = :last_page
