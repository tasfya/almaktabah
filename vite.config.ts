import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import tailwindcss from 'tailwindcss'

export default defineConfig({
  plugins: [
    RubyPlugin(),
  ],
  css: {
    transformer: 'lightningcss',
    lightningcss: {
      drafts: {
        customMedia: true,
      },
    },
  },
  optimizeDeps: {
    include: [
      '@hotwired/turbo',
      '@hotwired/turbo-rails', 
      '@hotwired/stimulus',
      'trix',
      '@rails/actiontext',
      '@rails/activestorage'
    ],
  },
})