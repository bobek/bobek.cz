---
title: Extensible version manager - ASDF - for the rescue
subtitle: rvm/rbench/nvm/etc under one roof
category: computers
date: 2019-11-25
---

I have been using `rvm` for a long time to manage per project ruby versions (and appropriate gemsets as well). While that works really well for ruby, it doesn't solve for other run-times. `node.js` for example. While I am not a front-end developer, node is a frequent dependency for building JS for Rails as well as Phoenix. Some people solve the issue with bunch of Docker containers, but that feel clumsy and slow for local development.

Fortunately, there is a project called [asdf](https://github.com/asdf-vm/asdf). It can replace `rvm` as well as `nvm` (node) or even `virtualenv` (Python) and much more -- check [available plugins](https://asdf-vm.com/#/plugins-all).

## Installation

Installation is very simple, just follow [documentation](https://asdf-vm.com/#/core-manage-asdf-vm?id=install-asdf-vm). When done, you want to install plugins. For example:

```
asdf plugin-add ruby
asdf plugin-add elixir
asdf plugin-add python
asdf plugin-add erlang
asdf plugin-add golang
asdf plugin-add yarn
```

## Updating

You can update plugins with

```
asdf plugin-update --all
```

and you can also update `asdf` with

```
asdf update
```

## Install vm

Having plugin installed is not yet sufficient for your work. You also need to install the appropriate version of your vm you want to use. For example, you can get all available ruby versions with

```
asdf list-all ruby
```

when you pick one, you want to install, you need to invoke `asdf install <plugin> <version>`. For example:

```
asdf install ruby 2.6.5
```

After you have installed particular version, you can set it as your default with

```
asdf global ruby 2.6.5
```

or you can set it "per project" with

```
asdf local ruby 2.6.5
```

Commands above will write to file `.tool-versions`. Global variant will use fire in your home directory, while local one uses current directory. Local configuration has precedence, thus you can define different versions per project.

You can verify your current active version with

```
asdf current

# or for the particular plugin
asdf current ruby
```

## Shims

Shim is used instead of binary installed by a library. This sometimes break and you need to **reshim** your binaries. For example

```
gem install middleman  # will install Middleman
asdf reshim ruby       # fixes ruby shims
which middleman        # $HOME/.asdf/shims/middleman
```

## Legacy version files

You man want to add `legacy_version_file = yes` to your `~/.asdfrc` as that will instruct asdf to follow classic version files. Such as `.ruby-version`.

## Gemsets

`rvm` has a feature called gemset, which allows for separation of installed gems per environment. `asdf` doesn't have such support ([asdf#312](https://github.com/asdf-vm/asdf/issues/312), [asdf-ruby#25](https://github.com/asdf-vm/asdf-ruby/issues/25)). But I have found that I don't really miss them at all as all of my projects are using `Gemfile` / `bundler` anyway.

There is a neat feature of `asdf-ruby` though -- you can list gems, which will get installed to every Ruby version, by placing them to `$HOME/.default-gems`. For example:

```
bundler
pry
```

## Conclusion

`asdf` works great so far and I am super happy with it. It significantly simplified my workflow in projects depending on multiple languages (e.g. Elixir + node).
