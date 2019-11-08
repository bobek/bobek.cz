---
title: "Tailwind CSS & Phoenix"
category: computers
tags: ["elixir", "phoenix"]
date: 2019-11-08
---

> [Tailwind CSS](https://tailwindcss.com/) is a highly customizable, low-level CSS framework that gives you all of the building blocks you need to build bespoke designs without any annoying opinionated styles you have to fight to override. 

I am no front-end developer by any stretch of imagination. Utility-first CSS framework thus looks quite interesting as it allows rather rapid composition of various elements. It also plays nicely with other CSS frameworks, so you can start using it without rewriting rest of your code. But This article is going to cover the green field Phoenix project wanting to use it.

I have found similar tutorials on the Internets, but they have been always missing something. Versions in time of writing are Elixir `1.9.1`, Phoenix `1.4.1`, Tailwind `1.1.2`, Webpack `4.4.0`.

## Getting started

### Dependencies

If you are starting from scratch, just create your Phoenix app with something like `mix phx.new tailwind`. You can skip installation of dependencies for now. Then install Tailwind and [PostCSS](https://github.com/postcss/postcss):

```bash
cd assets
npm install tailwindcss --save-dev
npm install postcss-loader --save-dev
```

That will install both packages and also adds them to `package.json`. Next thing is to add Tailwind as a plugin to PostCSS. You can do it through `postcss.config.js` file.

```javascript
// assets/postcss.config.js

module.exports = {
  plugins: [
    require('tailwindcss'),
    require('autoprefixer')
  ]
}
```

Or, as Phoenix already ships with `webpack`, just modify `webpack.config.js` directly. Relevant is css `rules` section, which looks like

```javascript
{
  test: /\.css$/,
    use: [MiniCssExtractPlugin.loader, 'css-loader']
}
```

we will add PostCSS like shown at the following snippet:

```javascript
{
  test: /\.css$/,
  use: [
    MiniCssExtractPlugin.loader, 
    'css-loader',
    {
      loader: 'postcss-loader',
      options: {
        ident: 'postcss',
        plugins: [
         require('tailwindcss'),
         require('autoprefixer'),
        ],
      },
    }
  ]
}
```

### Use Tailwind in your stylesheet

We can remove `assets/css/phoenix.css` as we replace `assets/css/app.css` with

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

Tailwind's [documentation](https://tailwindcss.com/docs/installation/#2-add-tailwind-to-your-css) suggests using `@import` instead `@tailwind`, but that didn't work for me.

### (Optional) Tailwind's configuration

Tailwind supports tweaking of its behavior (for example changing look-and-feel of the standard theme) through [configuration file](https://tailwindcss.com/docs/configuration). You can easily generate configuration file with

```bash
cd assets && npx tailwind init
# or npx tailwind init --full in case you want to see all default values
```

And that's it, Tailwind should be working.

## Example -- flash messages

Let's use Tailwind in your Application. Flash messages are currently displayed with the following code (`lib/surveys_web/templates/layout/app.html.eex`):

```eex
<p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>
<p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>
```

Let's replace it with

```eex
<p class="alert bg-green-200 border border-green-300 text-green-900 px-4 py-3 rounded relative" role="alert"><%= get_flash(@conn, :info) %></p>
<p class="alert bg-red-200 border border-red-300 text-red-900 px-4 py-3 rounded relative" role="alert"><%= get_flash(@conn, :error) %></p>
```

We now see the empty alert boxes shown on the site. Let's add CSS to hide them (`assets/css/app.css`):

```css
.alert:empty { display: none; }
```
