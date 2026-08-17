<div align="center">

<img src="assets/finagent-logo.svg" alt="FinAgent logo" width="160">

# FinAgent

**🔐 Privacy-first personal finance automation, local by default.**

[![Latest Release](https://img.shields.io/badge/Latest%20Release-v1.0.8-brightgreen?style=flat-square)](https://github.com/malfihasan/financialAgent-public/releases/latest)
[![License: Personal Use](https://img.shields.io/badge/license-Personal%20Use-blue?style=flat-square)](LICENSE)
[![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey?style=flat-square)](https://github.com/malfihasan/financialAgent-public/releases/latest)

</div>

FinAgent turns downloaded bank statements into categorized transactions, budgets,
and financial trends without requiring bank credentials or a hosted FinAgent account.
Statement files, rules, configuration, and processed results remain in folders you
control on your computer.

## Dashboard Preview

<table>
   <tr>
      <td align="center" width="33%">
         <a href="assets/dashboard-overview.png"><img src="assets/dashboard-overview.png" alt="FinAgent overview dashboard" width="100%"></a>
         <br><sub><b>Overview</b></sub>
      </td>
      <td align="center" width="33%">
         <a href="assets/dashboard-monthly.png"><img src="assets/dashboard-monthly.png" alt="FinAgent monthly dashboard" width="100%"></a>
         <br><sub><b>Monthly trends</b></sub>
      </td>
      <td align="center" width="33%">
         <a href="assets/dashboard-transactions.png"><img src="assets/dashboard-transactions.png" alt="FinAgent transactions dashboard" width="100%"></a>
         <br><sub><b>Transactions</b></sub>
      </td>
   </tr>
</table>

## 📚 Documentation

Full installation, setup, terminal, and configuration guides are available online:
**[https://malfihasan.github.io/financialAgent-public/docs/](https://malfihasan.github.io/financialAgent-public/docs/)**

## 🚀 Installation

FinAgent is available for macOS, Linux, Windows, and Docker. Choose your
platform:

### 🍎 macOS

<p align="center">
   <img src="docs/tutorial_dmg_install.gif" alt="macOS installation quick start: download FinAgent from the GitHub releases page" width="800">
</p>

<p align="center"><em>macOS installation quick start: download the latest release and begin setup.</em></p>

1. **Download** the latest `FinAgent-<version>-macOS.dmg` from the
   [GitHub releases page](https://github.com/malfihasan/financialAgent-public/releases/latest).

2. **Install** — open the `.dmg` and drag **FinAgent.app** into `Applications`.

3. **First launch — approve the security check.** Development builds are not
   notarized with a paid Apple Developer ID, so macOS Gatekeeper may say Apple
   could not verify that FinAgent is free of malware and offer to move it to
   the Trash:
   - Right-click (or Control-click) **FinAgent.app** → **Open** → **Open**.
   - If macOS still refuses ("Apple could not verify…"), go to
     **System Settings → Privacy & Security**, scroll to the Security
     section, and click **"Open Anyway"** next to the FinAgent message,
     then confirm with your password or Touch ID.
    - For a release downloaded from the official FinAgent Releases page that
       you trust, Terminal can remove the quarantine flag:
     ```bash
     xattr -dr com.apple.quarantine /Applications/FinAgent.app
     ```
   This approval is needed **once per install/update**. Ad-hoc signing does
   not remove the warning for downloaded apps; avoiding it requires Apple
   notarization and a paid Apple Developer account.

4. **Launch** — double-clicking FinAgent.app opens a Terminal window, starts
   the app, and opens your browser on the dashboard. First run walks you
   through the setup wizard.

**Set up the `finagent` terminal alias (macOS)** — the docs and dashboard
refer to the `finagent` command. The binary lives inside the app bundle, so
add an alias to your shell profile:

```bash
# zsh (default on modern macOS)
echo 'alias finagent="/Applications/FinAgent.app/Contents/MacOS/finagent"' >> ~/.zshrc
source ~/.zshrc

# bash
echo 'alias finagent="/Applications/FinAgent.app/Contents/MacOS/finagent"' >> ~/.bash_profile
source ~/.bash_profile
```

Verify it works: `finagent --version`. The wrapper detects how it was
invoked — from a shell it runs inline (all
[terminal flags](https://malfihasan.github.io/financialAgent-public/docs/terminal/)
work as expected); from Finder it opens Terminal.app for you.

> See the full [macOS installation guide](https://malfihasan.github.io/financialAgent-public/docs/installation/#macos-installation)
> for more detail.

### 🐧 Linux (x86_64)

1. **Download** the latest Linux archive:
   [FinAgent-Linux-x86_64.tar.gz](https://github.com/malfihasan/financialAgent-public/releases/latest/download/FinAgent-Linux-x86_64.tar.gz).

2. **Extract**:
   ```bash
   tar -xzf FinAgent-Linux-x86_64.tar.gz
   cd finagent_bundle
   ```

3. **Install** (recommended — no sudo needed, adds a `finagent` command and an
   app menu entry):
   ```bash
   ./install.sh
   ```
   Or run it in place without installing: `./finagent --setup`.

4. **Run the setup wizard** (first time only):
   ```bash
   finagent --setup
   ```

5. **Process your statements**:
   ```bash
   finagent --orgs boa,amex,chase
   ```

### 🪟 Windows

1. **Download** the latest
   [FinAgent-Windows-x64.exe](https://github.com/malfihasan/financialAgent-public/releases/latest/download/FinAgent-Windows-x64.exe).
2. **Run the installer.** It includes the dashboard runtime; no separate Python
   or Node.js installation is required.
3. Leave **Launch FinAgent** selected to open first-run setup, then use the
   Start Menu or optional desktop shortcut for later launches.

See the [Windows installation guide](INSTALL.md#windows) for SmartScreen and
installer troubleshooting.

### 🐳 Docker

Every release includes a Docker image containing the packaged executable,
dashboard, documentation, Node.js runtime, and Ollama. The private source tree
and raw Python files are not published in the image.

Install Docker Desktop, or Docker Engine with Docker Compose, before continuing.

1. **Download** `FinAgent-Docker-x86_64.tar.gz`, `docker_up.sh`, and
   `docker-compose.yml` from the
   [latest release](https://github.com/malfihasan/financialAgent-public/releases/latest).

2. **Load the image** and make the launcher executable:
   ```bash
   docker load -i FinAgent-Docker-x86_64.tar.gz
   chmod +x docker_up.sh
   ```

3. **Start FinAgent.** This basic command skips the optional model download;
   you can select a provider later in Settings:
   ```bash
   ./docker_up.sh \
     --statements "$HOME/Documents/FinAgent/statements" \
     --processing "$HOME/Documents/FinAgent/processing" \
     --port 3001 \
     --docs-port 3003 \
     --no-ollama-model
   ```

4. **Open FinAgent:**
   - Dashboard: [http://localhost:3001](http://localhost:3001)
   - Documentation: [http://localhost:3003](http://localhost:3003)

Both ports are validated before Docker starts. `--docs-port` can select a
different host port, while omitting it uses the dashboard port plus 2.

To use the included Ollama service, replace `--no-ollama-model` with
`--ollama-model` to download the small `qwen2.5:0.5b` model into a persistent
Docker volume. Claude and OpenRouter keys can be injected from a local mode-600
env file. See [Quick start](docs/quick-start/#docker) for the shortest
copy-paste command. The [detailed Docker installation](docs/installation/#docker-installation)
covers provider commands, custom models, persistence, updates, and
troubleshooting; [INSTALL.md](INSTALL.md#docker) includes release verification
and cleanup checks.

The statements, processing, and config folders are mounted from the host and
locked in Docker Settings. This ensures the dashboard and processing pipeline
always use the same persistent folders.

### ⚙️ First-Run Setup Wizard

On first launch the wizard will ask for:

| Question | What to enter |
|----------|--------------|
| **Your display name** | Shown in the dashboard header |
| **Statements folder** | Where you drop raw bank CSV downloads (e.g. `~/Documents/FinAgent/statements`). FinAgent creates `BOA/`, `AMEX/`, `CHASE/`, `CITI/`, `USBANK/` subfolders here automatically. |
| **Processing folder** | Where FinAgent writes output files (e.g. `~/Documents/FinAgent/processing`) |
| **Dashboard port** | Local port for the web dashboard (default `3001`) |
| **LLM backend** | `ollama` (free, local), `claude` (API key), `open_router` (API key), or `none` |
| **Location lookup** | `nominatim` (free, recommended) or `google_maps` (better local coverage) |
| **Contact e-mail** | Optional contact shared with OpenStreetMap only when enabled |

For native installs, settings are saved to `~/.finagent/config.json`; re-run
the wizard at any time with `finagent --reconfigure`.

> **Docker:** the statements folder, processing folder, and ports come from
> `docker_up.sh` and remain locked in Settings. Other settings persist in the
> host config mount (the `.docker-config` folder by default). Complete or edit
> those fields in the dashboard. To change a mount or published port, stop the
> container and run `docker_up.sh` again with the new option.

## 📁 Adding Bank Statements

1. On your bank's export page, download a **CSV** or supported tabular text
   statement. **Do not download a PDF** — FinAgent needs transaction rows, and
   PDF statements are not supported.
2. Launch FinAgent and choose **Import bank statements** in the terminal menu.
   This opens the dashboard **Import** page, where you select the bank/account
   and upload the file. The old desktop import window is no longer used.

Advanced users can instead rename the file and place it manually:

| Bank | File naming | Destination folder |
|------|------------|-------------------|
| Bank of America | `chk2026_1234.txt` or `cc2026_5678.csv` | `statements/BOA/CheckingAC/` or `statements/BOA/CreditAC/` |
| American Express | `amex_2026_9999.csv` | `statements/AMEX/CreditAC/` |
| Chase | `chase_2026_0429.csv` | `statements/CHASE/CheckingAC/` or `/CreditAC/` |
| Citi | `citi_2026_3978.csv` | `statements/CITI/CheckingAC/` or `/CreditAC/` |
| US Bank | `usbank_2026_1111.csv` | `statements/USBANK/CheckingAC/` or `/CreditAC/` |

> **Tip** — Use `finagent --orgs boa --month 2026-06` to process just one bank
> for one month while testing.

### 🔑 Cloud API keys for terminal runs

Keys saved through FinAgent Settings or `finagent --setup` are loaded
automatically. If you select OpenRouter or Claude only with terminal options
and have not saved its key, export it before starting FinAgent. The pipeline
and dashboard server inherit the variable.

```bash
# macOS / Linux
export OPENROUTER_API_KEY="sk-or-your-key"
finagent --llm-provider open_router --orgs boa

export ANTHROPIC_API_KEY="sk-ant-your-key"
finagent --llm-provider claude --orgs boa
```

```powershell
# Windows PowerShell
$env:OPENROUTER_API_KEY = "sk-or-your-key"
finagent --llm-provider open_router --orgs boa

$env:ANTHROPIC_API_KEY = "sk-ant-your-key"
finagent --llm-provider claude --orgs boa
```

These values apply to the current terminal session. Do not store real keys in
committed scripts.

## ⚙️ Running the Processing Pipeline

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

## 📊 Viewing the Dashboard

FinAgent automatically merges processed transactions into one persistent
`dashboard_data/master_transactions.csv` file. No manual file copy is required.
Categories changed on the Transactions page are retained on subsequent runs.

The dashboard starts after normal processing when you approve the launch prompt.
Open **http://localhost:3001** (or your configured port). To open the last view
without processing again, run `finagent --dashboard-only`.

Date arguments create an inclusive dashboard-wide view without deleting older
master data:

```bash
finagent --start-date 20260101 --end-date 20260201
```

A later processing run without date arguments restores the full-history view.

Dashboard master maintenance is intentionally terminal-only:

```bash
finagent --overwrite-dashboard-data
finagent --delete-dashboard-data
```

When exporting a budget month that already exists, FinAgent asks before replacing
the saved archive. Cancelling leaves the existing archive unchanged.

## 🔧 Troubleshooting

**"No transaction CSV found"** — Run normal statement processing to create or
update `dashboard_data/master_transactions.csv`.

**"Ollama not found"** — Install Ollama from [ollama.com](https://ollama.com/) and
pull your chosen model: `ollama pull qwen2.5:3b`.

**Dashboard blank / port conflict** — Check if another process is using the port:
`lsof -i :3001`. Change the port with `finagent --reconfigure`.

**Re-run setup** — `finagent --reconfigure` or `python setup_wizard.py --reconfigure`.

## ✨ What It Does

- 🏦 Imports and normalizes statement files from Bank of America, American Express,
  Chase, Citi, and U.S. Bank.
- 🧠 Categorizes transactions with editable rules, optional merchant/location lookup,
  and optional Ollama, Claude, or OpenRouter assistance.
- 🗂️ Maintains one persistent transaction master while preserving categories edited
  from the dashboard.
- 📅 Supports inclusive date-range views without deleting older transaction history.
- 📊 Provides a local dashboard for totals, trends, category analysis, transaction
  review, budgets, and rule management.
- 🗄️ Keeps monthly budget archives and asks before replacing an existing archive.
- 💻 Runs with a guided setup and statement-import workflow on macOS, Linux, and Windows.

## 🔒 Privacy

FinAgent never asks for online-banking passwords and does not connect directly to
bank accounts. Local or no-LLM configurations keep financial processing on your
machine. If you enable a cloud LLM or external location service, relevant prompt or
lookup data is sent to that provider under its privacy terms.

## 📦 Download

Download the latest build from the
[FinAgent Releases page](https://github.com/malfihasan/financialAgent-public/releases/latest).

See [INSTALL.md](INSTALL.md) for platform requirements, installation, first-run
setup, statement folders, commands, and troubleshooting.

## 📚 Documentation

FinAgent ships with a full offline documentation site — installation,
first-run setup, terminal utilities, profile management, and a configuration
reference. You can also access the documentation online:

- **Online Documentation**: [https://malfihasan.github.io/financialAgent-public/docs/](https://malfihasan.github.io/financialAgent-public/docs/)
- **Local Documentation**: Once FinAgent is running, open
   `http://localhost:<dashboard port + 2>` (port `3003` by default), or use the
   documentation links inside the dashboard's Settings page and footer.

## 💬 Support

Found a bug or need support for another bank? Open an
[issue](https://github.com/malfihasan/financialAgent-public/issues) with your OS,
FinAgent version, expected behavior, and anonymized sample rows when relevant.
Never attach account numbers, credentials, API keys, or unredacted financial data.

FinAgent is free for personal use. You can also support the developer:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=000000)](https://www.buymeacoffee.com/alfi_hasan)

## ⚖️ License

FinAgent binaries are provided for personal, non-commercial use. Redistribution or
resale is not permitted. See [LICENSE](LICENSE) for complete terms. Source code is
maintained in a private repository.
