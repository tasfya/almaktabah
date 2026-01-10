# SEO Improvements Documentation

This document outlines the SEO improvements implemented for the Almaktabah application.

## Overview

High-impact SEO improvements have been implemented to enhance the application's visibility in search engines and improve social media sharing.

## Implemented Improvements

### 1. Meta Tags (app/views/layouts/application.html.erb)

#### Basic SEO Meta Tags
- **Meta Title**: Dynamic titles with format: `[Page Title] | [Site Name]`
- **Meta Description**: Dynamic descriptions for each page
- **Canonical URL**: Prevents duplicate content issues
- **Hreflang Tag**: Specifies Arabic language content (`hreflang="ar"`)

#### Open Graph Meta Tags (Social Media)
Enables rich previews when sharing on Facebook, WhatsApp, LinkedIn, etc.:
- `og:title` - Page title
- `og:description` - Page description
- `og:image` - Preview image
- `og:url` - Canonical URL
- `og:type` - Content type (website)
- `og:site_name` - Site name
- `og:locale` - Arabic locale (ar_AR)

#### Twitter Card Meta Tags
Optimizes how content appears when shared on Twitter/X:
- `twitter:card` - Large image card
- `twitter:title` - Page title
- `twitter:description` - Page description
- `twitter:image` - Preview image
- `twitter:site` - Twitter handle (@Moh1Rz2H3)

### 2. Structured Data (JSON-LD Schema)

Implemented Schema.org structured data to help search engines understand content:

#### Organization Schema (All Pages)
- Organization name and logo
- Social media profiles (Twitter, YouTube)
- Helps with knowledge graph and brand recognition

#### Content-Specific Schemas
- **Lectures** (`VideoObject` schema) - app/views/lectures/show.html.erb
  - Title, description, duration, thumbnail
  - Author (scholar) information
  - Upload/publish date

- **Articles** (`Article` schema) - app/views/articles/show.html.erb
  - Headline, description, image
  - Author and publisher information
  - Published and modified dates

- **News** (`NewsArticle` schema) - app/views/news/show.html.erb
  - Headline, description, image
  - Publisher information
  - Published and modified dates

- **Books** (`Book` schema) - app/views/books/show.html.erb
  - Book name, description, cover image
  - Author (scholar) information
  - Publication date

### 3. SEO Helper Module (app/helpers/seo_helper.rb)

Centralized helper methods for SEO functionality:
- `meta_title` - Generates page titles
- `meta_description` - Generates descriptions with fallback
- `meta_image` - Provides images with fallback
- `canonical_url` - Generates canonical URLs
- `site_name` - Returns site name
- `default_description` - Fallback description in Arabic
- `structured_data_*` - Methods for generating JSON-LD schemas

### 4. Robots.txt Enhancement (public/robots.txt)

Improved robots.txt file with:
- Allow all search engines
- Disallow admin and authentication pages
- Sitemap reference

### 5. Sitemap Configuration (config/sitemap.rb)

Added comprehensive sitemap using `sitemap_generator` gem:
- Home page (priority: 1.0)
- All content types:
  - Lectures (priority: 0.8)
  - Books (priority: 0.8)
  - Articles (priority: 0.7)
  - News (priority: 0.7)
  - Fatwas (priority: 0.7)
  - Scholars (priority: 0.6)
  - Series (priority: 0.7)
- Dynamic lastmod dates based on content updates
- Appropriate changefreq values

### 6. Search Results Page Meta (app/views/search/index.html.erb)

Dynamic meta descriptions for search results:
- Query-specific descriptions showing search terms and result counts
- Generic description for browse mode

## Usage

### For Developers

#### Setting Page Meta Tags
In any view file, use `content_for` to set SEO meta tags:

```erb
<%# Set page title %>
<% content_for :title, "Page Title Here" %>

<%# Set page description %>
<% content_for :description, "Page description here" %>

<%# Set page image (optional) %>
<% if @resource.thumbnail.attached? %>
  <% content_for :image, url_for(@resource.thumbnail) %>
<% end %>

<%# Add structured data (optional) %>
<% content_for :structured_data do %>
  <script type="application/ld+json">
    <%= structured_data_for_lecture(@lecture).html_safe %>
  </script>
<% end %>
```

#### Available Structured Data Methods
- `structured_data_for_lecture(lecture)` - For lecture pages
- `structured_data_for_article(article)` - For article pages
- `structured_data_for_news(news_item)` - For news pages
- `structured_data_for_book(book)` - For book pages
- `structured_data_organization` - Organization schema (auto-included on all pages)

### Generating Sitemap

After installing the `sitemap_generator` gem:

```bash
# Install dependencies
bundle install

# Generate sitemap
rake sitemap:refresh

# In production, the sitemap will be generated at public/sitemaps/
```

The sitemap should be regenerated periodically (e.g., via cron job) to keep it up-to-date.

### Submitting Sitemap to Search Engines

Once generated, submit the sitemap to:
- **Google Search Console**: https://search.google.com/search-console
- **Bing Webmaster Tools**: https://www.bing.com/webmasters

Sitemap URL: `https://almaktabah.com/sitemap.xml`

## Testing

### Validate Meta Tags
1. View page source and check `<head>` section
2. Use browser extensions:
   - Meta SEO Inspector (Chrome/Firefox)
   - OpenGraph Preview

### Test Social Media Previews
- **Facebook**: https://developers.facebook.com/tools/debug/
- **Twitter**: https://cards-dev.twitter.com/validator
- **LinkedIn**: https://www.linkedin.com/post-inspector/

### Validate Structured Data
- **Google Rich Results Test**: https://search.google.com/test/rich-results
- **Schema.org Validator**: https://validator.schema.org/

### Test Sitemap
- Access: https://almaktabah.com/sitemap.xml
- Validate: https://www.xml-sitemaps.com/validate-xml-sitemap.html

## Expected Impact

### Search Engine Optimization
1. **Better indexing**: Sitemaps help search engines discover all content
2. **Rich snippets**: Structured data enables enhanced search results
3. **Improved CTR**: Better titles and descriptions increase click-through rates

### Social Media Sharing
1. **Professional appearance**: Open Graph tags create rich previews
2. **Higher engagement**: Visual previews increase social shares
3. **Brand consistency**: Proper meta tags ensure consistent branding

### Mobile & International
1. **Mobile optimization**: Proper viewport and app-capable tags
2. **Language targeting**: Hreflang and locale tags for Arabic content

## Maintenance

### Regular Tasks
1. **Regenerate sitemap**: Weekly or when content is published
2. **Monitor Search Console**: Check for indexing issues
3. **Update meta descriptions**: Keep them fresh and relevant
4. **Review structured data**: Ensure it stays valid as schemas evolve

### Future Enhancements
1. Add breadcrumb structured data
2. Implement FAQ schema where applicable
3. Add video structured data for YouTube embeds
4. Consider implementing AMP for mobile pages
5. Add more language alternatives if expanding internationally

## Dependencies

### New Gem
- `sitemap_generator` - For XML sitemap generation

### Modified Files
- `app/views/layouts/application.html.erb` - Main layout with meta tags
- `app/helpers/application_helper.rb` - Includes SeoHelper
- `app/helpers/seo_helper.rb` - New SEO helper module
- `app/views/lectures/show.html.erb` - Lecture meta tags
- `app/views/articles/show.html.erb` - Article meta tags
- `app/views/news/show.html.erb` - News meta tags
- `app/views/books/show.html.erb` - Book meta tags
- `app/views/search/index.html.erb` - Search results meta
- `public/robots.txt` - Enhanced robots file
- `config/sitemap.rb` - Sitemap configuration
- `Gemfile` - Added sitemap_generator gem

## References

- [Google SEO Starter Guide](https://developers.google.com/search/docs/beginner/seo-starter-guide)
- [Schema.org Documentation](https://schema.org/)
- [Open Graph Protocol](https://ogp.me/)
- [Twitter Cards Documentation](https://developer.twitter.com/en/docs/twitter-for-websites/cards/overview/abouts-cards)
