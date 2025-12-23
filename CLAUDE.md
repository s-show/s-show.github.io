# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Japanese-language personal blog built with Hugo (static site generator) using the hugo-clarity theme. The blog is hosted on GitHub Pages at https://kankodori-blog.com and focuses on programming, 3D printing, and keyboards.

## Development Environment

The project uses Nix for dependency management:
- `.envrc` contains `use nix` for direnv integration
- Hugo version used in CI: 0.137.1 (extended)
- Local Hugo version may differ (managed by Nix)
- Theme: hugo-clarity (managed as Go module)

## Common Commands

### Development

```bash
# Start local development server
hugo server -D

# Build the site (output to ./public)
hugo

# Build with minification and garbage collection (production)
hugo --gc --minify
```

### Content Management

```bash
# Create a new blog post using the archetype
hugo new content/post/YYYY-MM-DD/index.md

# Note: Posts use date-based folder structure (content/post/YYYY-MM-DD/)
```

## Architecture

### Configuration Structure

Configuration is split across multiple files in `config/_default/`:
- `hugo.toml`: Core Hugo settings, taxonomies, markup config
- `params.toml`: Theme-specific parameters (analytics, social, comments)
- `languages.toml`: Language settings (site is Japanese, `DefaultContentLanguage = "ja"`)
- `menus/menu.ja.toml`: Navigation menu structure

### Content Organization

- `content/post/YYYY-MM-DD/index.md`: Blog posts organized by date
- `content/about.md`: About page
- `archetypes/post.md`: Template for new blog posts
- Posts use frontmatter with tags and archives taxonomy
- Archives follow `YYYY/MM` format

### Theme Management

- Theme is pulled as a Go module: `github.com/chipzoller/hugo-clarity`
- No local theme directory; managed via `go.mod`
- Custom styles: `assets/sass/_custom.sass`

### Deployment

GitHub Actions workflow (`.github/workflows/hugo.yaml`) handles deployment:
1. Installs Hugo CLI and Dart Sass
2. Checks out repository with submodules
3. Builds site with `hugo --gc --minify`
4. Deploys to GitHub Pages

Deployment triggers on:
- Pushes to `main` branch
- Manual workflow dispatch

### Post Frontmatter

Key fields in blog post frontmatter:
- `title`: Post title
- `date`: Creation date with timezone (+09:00)
- `featured`: Boolean for featuring on homepage
- `draft`: Boolean for draft status
- `toc`: Table of contents toggle
- `tags`: Array of tags
- `archives`: Date in `YYYY/MM` format
- `comment`: Boolean for Utterances comments

### Features Enabled

- Utterances comments (GitHub Issues-based)
- Google Analytics (G-367F1P4JXZ)
- Search functionality
- RSS/JSON feeds
- Syntax highlighting with line numbers

## Important Notes

- Site is Japanese language (`ja`)
- Base URL: https://kankodori-blog.com/
- Post summary length: 5 words (configured for Japanese)
- Date format: 2006-01-02 (YYYY-MM-DD)
- Site has been running since 2016

## Points to Note When Writing Articles

When writing articles, please be sure to refer to @WRITING.md.
Also, please select a few recent articles at random and do your best to imitate their writing style when creating your own.
