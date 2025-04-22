module.exports = {
    content: [
        './app/views/**/*.{html,html.erb,erb}',
        './app/frontend/**/*.{js,jsx,ts,tsx,vue}',
        './app/components/**/*.{erb,html,html.erb}',
        './app/helpers/**/*.{js,jsx,ts,tsx}',
    ],
    theme: {
        extend: {},
    },
    plugins: [require("daisyui")],
    daisyui: {
        themes: ["light"],
    }
}