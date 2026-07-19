<div align="center">

# FinAgent

**Privacy-first personal finance engine — all data stays on your machine.**

[![Latest Release](https://img.shields.io/badge/Latest%20Release-latest-brightgreen?style=flat-square)](https://github.com/malfihasan/financialAgent-public/releases/latest)
[![License: Personal Use](https://img.shields.io/badge/license-Personal%20Use-blue?style=flat-square)](LICENSE)
[![Supported Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey?style=flat-square)](#download)

</div>

---

## What is FinAgent?
FinAgent is a local personal-finance automation system. It imports bank statements, applies deterministic rules and optional generative categorization, and displays processed results in a local dashboard. The main motivation of this project is to provide a privacy-first personal finance system that runs entirely on your machine, without sending any data to the cloud or requiring login to any financial institute.

As of 2026-07-18, FinAgent supports five banks: American Express, Bank of America, Chase, Citi, and U.S. Bank. More bank workflows can be added in future releases.

Current limitation: one machine is treated as one FinAgent user. The setup wizard writes one local `~/.finagent/config.json`, and all statement input plus processed output are resolved from that one local configuration. Multi-user support is planned for future releases.

## Overview
FinAgent is a **terminal / CLI application** that automatically processes your bank statement transactions using a multi-stage pipeline.

After processing, a local web **dashboard** opens automatically in your browser so you can explore spending charts, track budgets, and review categories — no cloud sync, no accounts.

> **CLI-first design**: FinAgent runs in your terminal. The `.dmg` / `.tar.gz` / `.zip`
> installers package the same command-line tool — they don't open a GUI window on launch.
> See [Installation](#installation) for how to get `finagent` on your PATH.

Everything is processed locally. No data leaves your computer unless you choose a cloud LLM.

---

## Features

| Feature | Details |
|---------|---------|
| Supported banks | Bank of America · Amex · Chase · Citi · US Bank |
| Categorization | Rules + location lookup + optional LLM fallback |
| Dashboard | React web dashboard — charts, budget tracking, category drill-down |
| LLM options | Ollama (free, local) · Claude API · OpenRouter · none |
| Location lookup | Nominatim (free) · Google Maps · combined |
| First-run wizard | Interactive CLI setup on first launch — no config files to edit |
| Platforms | macOS · Linux · Windows |

---

## Screenshots

> _Screenshots coming soon._

---

## Download

Download the latest binary for your platform from the
[**Releases page**](https://github.com/malfihasan/financialAgent-public/releases/latest):

| Platform | Latest download |
|----------|-----------------|
| macOS (Apple Silicon + Intel) | [FinAgent macOS `.dmg`](https://github.com/malfihasan/financialAgent-public/releases/latest/download/FinAgent-macOS.dmg) |
| Linux x86_64 | [FinAgent Linux `.tar.gz`](https://github.com/malfihasan/financialAgent-public/releases/latest/download/FinAgent-Linux-x86_64.tar.gz) |
| Windows x64 | [FinAgent Windows `.zip`](https://github.com/malfihasan/financialAgent-public/releases/latest/download/FinAgent-Windows-x64.zip) |

The links above always point to the latest public release. Release artifacts are published with versioned filenames on GitHub, and stable download aliases are updated automatically by the release workflow.

---

## Installation

### macOS

```bash
# 1. Download and open the .dmg, drag FinAgent.app to /Applications

# 2. Add finagent to your PATH (one-time — add to ~/.zshrc or ~/.bash_profile)
export PATH="/Applications/FinAgent.app/Contents/MacOS:$PATH"

# 3. Reload your shell
source ~/.zshrc        # or: source ~/.bash_profile

# 4. Verify
finagent --version
```

> **Double-click alternative**: Double-clicking `FinAgent.app` opens a Terminal window
> automatically and drops you into the interactive menu — no PATH setup needed for casual use.

### Linux

```bash
# 1. Extract
tar -xzf FinAgent-Linux-x86_64.tar.gz

# 2. Move to a permanent location
sudo mv finagent/ /opt/finagent/

# 3. Add to PATH
sudo ln -s /opt/finagent/finagent /usr/local/bin/finagent

# 4. Verify
finagent --version
```

### Windows

```powershell
# 1. Extract the .zip to C:\Program Files\FinAgent\

# 2. Add to PATH (System → Advanced → Environment Variables → Path)
#    Add: C:\Program Files\FinAgent\finagent\

# 3. Open a new terminal and verify
finagent --version
```

---

## First Run — Setup Wizard

The **very first time** you run `finagent` (by any method), it automatically starts an
interactive setup wizard:

```
  FinAgent v1.0.0  —  Personal Finance Engine

  Welcome to FinAgent! Let's configure your workspace.

  Your name: PrivateUser1
  Statements folder [~/Documents/FinAgent/statements]:
  Processing output folder [~/Documents/FinAgent/processing]:
  Dashboard port [3001]:
  LLM provider (ollama / claude / none) [ollama]:
  ...

  ✓ Configuration saved to ~/.finagent/config.json
```

After setup, the interactive menu appears. You only do this once — settings are saved to
`~/.finagent/config.json` and reused on every subsequent run.

---

## Usage

### Interactive menu (no arguments)

```bash
finagent
```

```
  Hello, PrivateUser1!

  What would you like to do?

    1)  Process bank statements  →  categorize + open dashboard
    2)  Open dashboard only      →  view results from last run
    3)  Calculation only         →  process without opening dashboard
    4)  Re-run setup wizard      →  change directories / LLM settings
    5)  Exit
```

### Direct CLI (power users)

```bash
# Process all configured banks, open dashboard when done
finagent --orgs boa,amex,chase

# Filter by date range
finagent --orgs boa,amex --start-date 20250101 --end-date 20250331

# Process only (no dashboard)
finagent --calculation-only --orgs boa,amex,chase

# Open dashboard with last run's data
finagent --dashboard-only

# Re-run setup wizard
finagent --setup

# Full option reference
finagent --help
```

### Typical monthly workflow

```
1. Export CSVs from your bank websites
2. Drop them into your statements folder:
      ~/Documents/FinAgent/statements/BOA/CheckingAC/
      ~/Documents/FinAgent/statements/AMEX/CreditAC/
      ~/Documents/FinAgent/statements/CHASE/CheckingAC/

3. Run:  finagent --orgs boa,amex,chase

4. Browser opens automatically at http://localhost:3001
   → review categories, check budgets, export reports

5. Press Ctrl-C to stop the dashboard server
```

---


## Support This Project

FinAgent is free for personal use. If it saves you time:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-%E2%98%95-yellow?style=flat-square)](https://www.buymeacoffee.com/alfi_hasan)

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
- What you expected vs what happened
- Anonymized sample CSV rows if relevant (remove all personal data)

---

## License

FinAgent binaries are provided for **personal, non-commercial use only**.
Redistribution or resale of the binaries is not permitted.
Source code is maintained in a private repository.

