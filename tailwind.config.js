/** @type {import('tailwindcss').Config} */
export default {
    content: [
        './app/views/**/*.html.erb',
        './app/helpers/**/*.rb',
        './app/javascript/**/*.js',
        './app/frontend/**/*.{js,jsx,ts,tsx,vue}',
    ],
    theme: {
        extend: {},
    },
    plugins: [],
}