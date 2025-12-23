# WRITING.md

This file documents the writing style, structure patterns, and conventions used in blog posts for this site.

## Article Structure

### Standard Post Structure

Most posts follow this pattern:

1. **Front matter** (YAML metadata with title, date, tags, archives)
2. **前置き** (Introduction/Preface) - Appears in ~95% of posts
3. **Main content** with clear section headings
4. **Closing remarks** (optional)
5. **参考にしたサイト** or **参考情報** (References section)

### Heading Hierarchy

- **H2 (`##`)** - Main sections (前置き, 環境, 手順, まとめ, etc.)
- **H3 (`###`)** - Subsections within main topics
- **H4 (`####`)** - Detailed breakdowns

## Opening Patterns

### The 前置き Section

About 90% of technical posts start with a dedicated "前置き" (preface/introduction) section.

**Common opening phrases:**
- `この記事は...` (This article is...)
- `今日は...` (Today...)
- `さて、` (Now then,...)
- `長い前置き` (Long preface) - when extensive context is needed

**Purpose of 前置き:**
- Sets context for why the article was written
- Explains the problem encountered
- Describes motivation and background
- References Advent Calendar participation or community events
- Links to related past articles

**Example:**
```markdown
## 前置き

この記事は [キーボード #1 Advent Calendar 2024] の11日目の記事です。

私はキー数が右手側・左手側 24 キーずつの合計 48 キーの自作キーボードを使っているのですが...
```

## Closing Patterns

### Common closing phrases:

- `以上で説明は完了です。` (That completes the explanation.)
- `では今日はこの辺りにしようと思います` (I'll stop here for today)
- `本記事がどなたかの参考になれば幸いです。` (I hope this article helps someone.)
- `参考になれば幸いです。` (Hope this is helpful.)

### Reference section (almost always included):

```markdown
## 参考にしたサイト

- [Title](URL)
- [Title](URL)
```

### Optional device attribution:

```markdown
本記事は、Yamanami Keyboard の Cherry MX 版で書きました。
```

## Tone and Style

### Overall Characteristics

- **Modest and humble** - Uses softening phrases, acknowledges limitations
- **Conversational yet technical** - Balances casual tone with precise technical details
- **Self-reflective** - Openly discusses struggles and trial-and-error process
- **Community-oriented** - References Discord, Vim-jp, GitHub discussions

### Frequently Used Phrases

**Expressing difficulty/struggle:**
- `何とか〜できました` (Somehow managed to...)
- `試行錯誤の末` (After trial and error...)
- `色々と苦労しましたが` (Had various difficulties but...)

**Indicating purpose:**
- `備忘録としてまとめます` (Summarizing as a memo/reference)

**Transitions:**
- `そこで` (Therefore...)
- `というわけで` (So then...)
- `それから` (Then...)
- `まず` (First...)
- `次に` (Next...)

**Suggesting/inviting:**
- `よろしければ〜` (If you'd like...)

### Politeness Level

- Consistently uses です・ます form (polite style)
- Not overly formal - maintains accessibility
- Appropriate use of 謙譲語 (humble language)

## Technical Content Presentation

### Code Blocks

Always include language specifiers for syntax highlighting:

```lua
-- Lua code example
local config = require('config')
```

```c
// C code for QMK
void matrix_init_user(void) {
    // Implementation
}
```

```bash
❯ nvim --version
NVIM v0.10.1
```

- Precede code blocks with explanatory text
- Include inline comments in Japanese within code
- Add path/file comments like `# config.h` or `// keymap.c`

### Step-by-Step Instructions

Use numbered lists for sequential procedures:

1. まず〜する (First do...)
2. 次に〜する (Next do...)
3. それから〜する (Then do...)
4. 最後に〜する (Finally do...)

Use bullet points for related but non-sequential items:
- Item 1
- Item 2
- Item 3

### Environment Specifications

Always document:
- Software versions
- OS information
- Hardware specifications
- Tool versions

Example:
```markdown
### 環境

- OS: Ubuntu 22.04
- Neovim: v0.10.1
- QMK Firmware: 0.21.0
```

### Technical Details

- Include BOM (Bill of Materials) lists for hardware projects
- Document version numbers
- Show configuration files in full
- Provide complete code examples (not snippets)

## Common Section Names

### Technical/Programming Posts

- `前置き` - Preface
- `環境` - Environment
- `手順` - Procedure
- `実装` - Implementation
- `設定` - Configuration/Settings
- `実際のコード` - Actual Code
- `補足` - Supplementary Notes
- `まとめ` - Summary
- `参考にしたサイト` - Referenced Sites

### Hardware/Keyboard Posts

- `前置き` - Preface
- `BOM` - Bill of Materials
- `必要な手順の概要` - Overview of Required Steps
- `各処理の説明` - Explanation of Each Process
- `失敗談や工夫した点など` - Failures and Ingenuity
- `参考情報` - Reference Information

### Reading Notes (読書記録)

- `本の概要` - Book Overview
- `感想` - Impressions
- `特に印象に残った部分` - Particularly Memorable Parts
- `参考にしたサイト` - Referenced Sites

## Formatting Conventions

### Lists

```markdown
- Bullet points use `-` or `*`
- Sub-items are indented
  - Like this
  - And this

1. Numbered lists for sequential steps
2. Second step
3. Third step
```

### Emphasis

- **Bold** for important terms: `**重要**`
- `code formatting` for: commands, variables, file paths, technical terms
- Quote blocks for examples or excerpts:

```markdown
> Quoted text here
```

### Images and Media

Custom shortcodes used:

```markdown
{{< bsimage src="image.png" title="Image title" >}}

{{< video src="video.webm" type="video/webm" preload="auto" >}}

{{< youtube VIDEO_ID >}}

{{< amazon asin="ASIN" title="Product title" >}}
```

### Tables

Use markdown tables with header row:

```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
```

Common uses:
- Pin mappings for hardware
- Feature comparisons
- Configuration options

### Alerts and Notes

```markdown
{{% alert info %}}
Important information here
{{% /alert %}}

{{% alert warning %}}
Warning message here
{{% /alert %}}
```

### Updates and Addenda

```markdown
## 追記 (2024-12-25)

Updated information here...
```

Or within text:
```markdown
本記事執筆時点では... (At the time of writing...)
```

## Topic-Specific Conventions

### 自作キーボード (Custom Keyboards)

- Very detailed and technical
- Include BOM lists with specific part numbers
- Document both hardware and software configuration
- QMK Firmware code examples
- Photos of physical builds
- Design rationale sections
- Pin mapping tables

### 3Dプリンタ (3D Printers)

- Klipper/firmware configuration focus
- Document modifications and upgrades
- Before/after comparisons
- Troubleshooting narratives
- Link to STL files and MOD repositories
- Include print settings and parameters

### Neovim/Vim

- Lua configuration examples
- Plugin setup and configuration
- Reference Vim-jp community
- "小技集" (tips collection) style
- Link to Advent Calendar participation
- Document keymaps and custom functions

### 読書記録 (Reading Notes)

- More narrative style, less technical
- Provide historical context
- Include personal reflections
- Quote significant passages
- Use academic references with proper citations

### Programming General

- Problem-solution structure
- Document debugging journey
- Show failed attempts before final solution
- Acknowledge community help (Discord, GitHub Issues)
- Include complete error messages

## Language and Punctuation

### Japanese Punctuation

- `、` for commas
- `。` for periods
- `「」` for quotations
- `（）` for parenthetical remarks

### English-Japanese Mix

- Technical terms typically in English
- File paths in English
- Function/variable names in English
- Explanations in Japanese
- Code comments in Japanese

Example:
```markdown
`keyboard.json` に以下の設定を追加する。
```

## Problem-Solving Narrative Style

A distinctive characteristic of posts is the honest documentation of the problem-solving process:

1. **Describe the problem** - What wasn't working
2. **Show failed attempts** - What was tried first
3. **Document the solution** - What eventually worked
4. **Acknowledge help** - Credit community members or resources
5. **Reflect on lessons** - What was learned

**Common phrases:**
- `試行錯誤の末` (After trial and error...)
- `失敗談` (Failure story)
- `Discord の ... で相談したところ` (When I consulted on Discord...)
- `何とか解決できました` (Somehow managed to solve it)

## Community References

Frequently mention and link to:
- Discord servers (Self-Made Keyboard in Japan, etc.)
- Vim-jp community
- GitHub Issues and Pull Requests
- Advent Calendar participation
- Other blog posts and resources

Acknowledge help received:
```markdown
Discord の Self-Made Keyboard in Japan で相談したところ、〜というアドバイスをもらった。
```

## Completeness and Transparency

### Always Include

- Full version information
- Complete environment specifications
- Full code examples (not just snippets)
- All relevant configuration
- Comprehensive reference links

### Be Transparent About

- Mistakes made: `失敗談` sections
- Incomplete solutions: Note when something isn't fully working
- Uncertainties: `〜だと思われる` (seems to be...)
- Updates: Use `追記` sections when finding better solutions

## Evolution Over Time

The writing style has evolved:

**Earlier posts (2017-2019):**
- Simpler structure
- More essay-like
- Fewer code examples

**Recent posts (2023-2025):**
- Highly standardized structure
- Extensive code examples
- More screenshots and videos
- Table of contents enabled
- Detailed multi-section breakdowns
- Strong community references

## Tips for Consistency

1. **Always start with 前置き** for technical posts
2. **Document your environment** before diving into details
3. **Use consistent section names** from the common patterns
4. **Include all version numbers** for reproducibility
5. **Show your work** - document failed attempts and solutions
6. **Credit the community** when you receive help
7. **Provide references** at the end of every post
8. **Be humble** - use softening language
9. **Be complete** - include full code, not snippets
10. **Update when needed** - add 追記 sections for corrections
