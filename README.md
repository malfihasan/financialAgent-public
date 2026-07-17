<div align="center">

# FinAgent

**Privacy-first personal finance categorization — all data stays on your machine.**

[![Latest Release](https://img.shields.io/github/v/release/malfihasan/financialAgent-public?style=flat-square&label=Download)](https://github.com/malfihasan/financialAgent-public/releases/latest)
[![License: Personal Use](https://img.shields.io/badge/license-Personal%20Use-blue?style=flat-square)](LICENSE)
[![Supported Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey?style=flat-square)](#download)

</div>

---

## What is FinAgent?

FinAgent automatically categorizes your bank statement transactions using:

- **Rule engine** — fast, deterministic keyword and merchant rules
- **Location lookup** — Nominatim / OpenStreetMap to identify merchants by address
- **Local LLM** — Ollama with `qwen2.5:3b` (runs 100 % on your machine, no cloud)
- **Cloud LLM** (optional) — Anthropic Claude or OpenRouter for highest accuracy

Everything is processed locally. No data ever leaves your computer unless you
choose a cloud LLM provider.

---

## Features

| Feature | Details |
|---------|---------|
| Supported banks | Bank of America · Amex · Chase · Citi · US Bank |
| Categorization | Rules + location lookup + optional LLM fallback |
| Dashboard | React web dashboard with charts, budget tracking, category drill-down |
| LLM options | Ollama (free, local) · Claude API · OpenRouter · none |
| Location lookup | Nominatim (free) · Google Maps scraping · combined |
| First-run wizard | Interactive CLI setup — no config files to hand-edit |
| Platforms | macOS · Linux · Windows |

---

## Screenshots

> _Screenshots coming soon._

---

## Download

Download the latest binary for your platform from the
[**Releases page**](https://github.com/malfihasan/financialAgent-public/releases/latest):

| Platform | File |
|----------|------|
| macOS (Apple Silicon + Intel) | `FinAgent-x.y.z-macOS.dmg` |
| Linux x86_64 | `FinAgent-x.y.z-Linux-x86_64.tar.gz` |
| Windows x64 | `FinAgent-x.y.z-Windows-x64.zip` |

See [INSTALL.md](INSTALL.md) for full setup instructions.

---

## Quick Start (3 steps)

```bash
# 1. Run the first-time setup wizard
finagent --setup

# 2. Drop your bank CSV downloads into the statements folder, then:
finagent --orgs boa,amex,chase

# 3. Open the dashboard
open http://localhost:3001
```

---

## How It Works

```
Your bank CSVs
      │
      ▼
Rule Engine  ──────────────────────────────────────────────► Categorized
(markdown rules)                                              Transactions
      │ uncategorized remaining
      ▼
Location Lookup
(Nominatim / Google Maps)
      │ still uncategorized
      ▼
LLM Fallback
(Ollama / Claude / OpenRouter)
      │
      ▼
Final CSV + Dashboard
```

All processing happens on your machine. Your bank data never touches a
third-party server unless you explicitly configure a cloud LLM provider.

---

## Support This Project

FinAgent is free for personal use. If it saves you time:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-%E2%98%95-yellow?style=flat-square)](https://www.buymeacoffee.com/malfihasan)

Monthly supporters get:
- Priority bug fixes
- Early access to new bank format support
- Direct support channel

---

## Reporting Issues

Found a bug or want to request a new bank? Open an issue:
[github.com/malfihasan/financialAgent-public/issues](https://github.com/malfihasan/financialAgent-public/issues)

Please include:
- Your OS and version
- The FinAgent version (`finagent --version`)
- What you expected vs. what happened
- Anonymized sample CSV rows if relevant (remove all personal data)

---

## License

FinAgent binaries are provided for **personal, non-commercial use only**.
Redistribution or resale of the binaries is not permitted.

Source code is maintained in a private repository.
