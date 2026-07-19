# FinAgent — Installation Guide

FinAgent is a local, privacy-first personal finance categorization tool.
All your data stays on your machine.

---

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| OS | macOS 11, Ubuntu 20.04, Windows 10 | macOS 14, Ubuntu 22.04, Windows 11 |
| RAM | 4 GB | 8 GB+ |
| Disk | 500 MB free | 2 GB+ (for LLM model cache) |
| Node.js | 18+ | 20 LTS |
| Python | 3.11 (bundled) | — |

> **Note** — Python is bundled in the macOS `.dmg` and Linux `.tar.gz` releases.
> Node.js must be installed separately for the web dashboard.
> Install from [nodejs.org](https://nodejs.org/).

---

## macOS

1. **Download** the latest macOS `.dmg` from the
   [Releases page](https://github.com/malfihasan/financialAgent-public/releases/latest)
   or use the direct latest link:
   [FinAgent-macOS.dmg](https://github.com/malfihasan/financialAgent-public/releases/latest/download/FinAgent-macOS.dmg).

2. **Open** the `.dmg` and drag **FinAgent** to your Applications folder.

3. **First launch** — open Terminal and run:
   ```bash
   /Applications/FinAgent.app/Contents/MacOS/finagent
   ```
   The setup wizard will appear and guide you through configuration.

4. **Subsequent runs** — double-click the app in Finder (dashboard auto-opens)
   or use the command line with full arguments.

---

## Linux (x86_64)

1. **Download** the latest Linux archive:
   [FinAgent-Linux-x86_64.tar.gz](https://github.com/malfihasan/financialAgent-public/releases/latest/download/FinAgent-Linux-x86_64.tar.gz).

2. **Extract**:
   ```bash
   tar -xzf FinAgent-Linux-x86_64.tar.gz
   cd finagent_bundle
   ```

3. **Run the setup wizard** (first time only):
   ```bash
   ./finagent --setup
   ```

4. **Process your statements**:
   ```bash
   ./finagent --orgs boa,amex,chase
   ```

---

## Windows

1. **Download** the latest Windows archive:
   [FinAgent-Windows-x64.zip](https://github.com/malfihasan/financialAgent-public/releases/latest/download/FinAgent-Windows-x64.zip).

2. **Extract** the zip to a folder of your choice (e.g. `C:\FinAgent`).

3. **Run the setup wizard** (first time only):
   ```
   FinAgent.bat --setup
   ```

4. **Process your statements**:
   ```
   FinAgent.bat --orgs boa,amex,chase
   ```

---

## First-Run Setup Wizard

On first launch the wizard will ask for:

| Question | What to enter |
|----------|--------------|
| **Your display name** | Shown in the dashboard header |
| **Statements folder** | Where you drop raw bank CSV downloads (e.g. `~/Documents/FinAgent/statements`). FinAgent creates `BOA/`, `AMEX/`, `CHASE/`, `CITI/`, `USBANK/` subfolders here automatically. |
| **Processing folder** | Where FinAgent writes output files (e.g. `~/Documents/FinAgent/processing`) |
| **Dashboard port** | Local port for the web dashboard (default `3001`) |
| **LLM backend** | `ollama` (free, local), `claude` (API key), `open_router` (API key), or `none` |
| **Location lookup** | `nominatim` (free, recommended) or `google_maps` (better local coverage) |
| **Contact e-mail** | Required by Nominatim ToS; never sent anywhere else |

Settings are saved to `~/.finagent/config.json`.  
Re-run the wizard at any time with `finagent --reconfigure`.

---

## Adding Bank Statements

1. Download your statement CSV from your bank's website.
2. Rename the file using the convention below and drop it in the matching folder:

| Bank | File naming | Destination folder |
|------|------------|-------------------|
| Bank of America | `chk2026_1234.txt` or `cc2026_5678.csv` | `statements/BOA/CheckingAC/` or `statements/BOA/CreditAC/` |
| American Express | `amex_2026_9999.csv` | `statements/AMEX/CreditAC/` |
| Chase | `chase_2026_0429.csv` | `statements/CHASE/CheckingAC/` or `/CreditAC/` |
| Citi | `citi_2026_3978.csv` | `statements/CITI/CheckingAC/` or `/CreditAC/` |
| US Bank | `usbank_2026_1111.csv` | `statements/USBANK/CheckingAC/` or `/CreditAC/` |

> **Tip** — Use `finagent --orgs boa --month 2026-06` to process just one bank
> for one month while testing.

---

## Running the Processing Pipeline

```bash
# Process all banks for all available months
finagent --orgs boa,amex,chase,citi,usbank

# Process one bank, one month
finagent --orgs chase --month 2026-06

# Skip the LLM (rules only, fastest)
finagent --orgs boa --no-llm

# Use a specific LLM backend for this run
finagent --orgs amex --llm-provider claude
```

---

## Viewing the Dashboard

After a successful run, copy the output file into the dashboard data folder:

```bash
cp ~/Documents/FinAgent/processing/processing_dir/transaction_data/final_categorized_transactions_*.csv \
   ~/Documents/FinAgent/processing/processing_dir/dashboard_data/
```

Then open your browser at **http://localhost:3001** (or the port you chose).

The dashboard starts automatically with the `finagent` command.  
To start it standalone: `finagent --dashboard-only`.

---

## Troubleshooting

**"No transaction CSV found"** — Make sure you copied the output file into the
`dashboard_data/` folder (see above).

**"Ollama not found"** — Install Ollama from [ollama.com](https://ollama.com/) and
pull your chosen model: `ollama pull qwen2.5:3b`.

**Dashboard blank / port conflict** — Check if another process is using the port:
`lsof -i :3001`. Change the port with `finagent --reconfigure`.

**Re-run setup** — `finagent --reconfigure` or `python setup_wizard.py --reconfigure`.
