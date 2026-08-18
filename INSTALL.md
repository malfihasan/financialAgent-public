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
| Node.js | Linux: 18+; macOS/Windows: bundled | Linux: 20 LTS |
| Python | Bundled | — |

> **Note** — Linux users install Node.js separately for the dashboard. macOS
> and Windows releases include the dashboard runtime. Docker includes all
> application runtimes and Ollama.

---

## macOS

1. **Download** the latest macOS `.dmg` from the
   [Releases page](https://github.com/malfihasan/financialAgent-public/releases/latest)
   or use the direct latest link:
   [FinAgent-macOS.dmg](https://github.com/malfihasan/financialAgent-public/releases/latest/download/FinAgent-macOS.dmg).

2. **Open** the `.dmg` and drag **FinAgent** to your Applications folder.

3. **Approve the first launch.** Development builds are not notarized with a
    paid Apple Developer ID, so macOS may say Apple could not verify that
    FinAgent is free of malware and offer to move it to the Trash.
    - Control-click (or right-click) **FinAgent.app** in Applications, choose
       **Open**, then choose **Open** again.
    - If it is still blocked, open **System Settings → Privacy & Security**,
       scroll to Security, click **Open Anyway** beside the FinAgent message,
       and confirm with your password or Touch ID.
    - For a release you downloaded from the official FinAgent Releases page and
       trust, Terminal can remove the downloaded-file quarantine flag:
       ```bash
       xattr -dr com.apple.quarantine /Applications/FinAgent.app
       ```
    Approval is normally required once per install or update. Ad-hoc signing
    does not remove this warning for downloaded apps; Apple notarization is the
    standard way to avoid it and requires a paid Apple Developer account.

4. **First launch** — open Terminal and run:
   ```bash
   /Applications/FinAgent.app/Contents/MacOS/finagent
   ```
   The setup wizard will appear and guide you through configuration.

5. **Subsequent runs** — double-click the app in Finder (dashboard auto-opens)
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

3. **Install** (recommended, no sudo needed) — copies the app to
   `~/.local/share/FinAgent`, links a `finagent` command into `~/.local/bin`,
   and adds an application-menu entry:
   ```bash
   ./install.sh
   ```
   Prefer to run it in place instead? Skip this step and use `./finagent`
   from the extracted folder. Uninstall later with `./install.sh --uninstall`.

4. **Run the setup wizard** (first time only):
   ```bash
   finagent --setup
   ```

5. **Process your statements**:
   ```bash
   finagent --orgs boa,amex,chase
   ```

---

## Docker

The Docker release image contains the packaged Linux executable, dashboard
assets, and required runtime data. It does not include the private source tree
or raw Python source files. Statement, processing, and config folders are
bind-mounted from the host and locked to those mounts for the container's
lifetime; Settings shows a "Docker locked" badge and hides the folder pickers.

1. **Download the image and launcher files**:
   ```bash
   curl -LO https://github.com/malfihasan/financialAgent-public/releases/download/v1.0.11/FinAgent-1.0.11-Docker-x86_64.tar.gz
   curl -LO https://github.com/malfihasan/financialAgent-public/releases/download/v1.0.11/docker_up.sh
   curl -LO https://github.com/malfihasan/financialAgent-public/releases/download/v1.0.11/docker-compose.yml
   ```

2. **Load the image** and make the launcher executable:
   ```bash
   docker load -i FinAgent-1.0.11-Docker-x86_64.tar.gz
   chmod +x docker_up.sh
   ```

3. **Preview the mounts and ports** without starting a container:
   ```bash
   ./docker_up.sh \
     --statements ~/Documents/FinAgent/statements \
     --processing ~/Documents/FinAgent/processing \
     --port 3001 \
   --docs-port 3003 \
   --no-ollama-model \
     --dry-run
   ```

4. **Start it**. Keep `docker_up.sh` and `docker-compose.yml` in the same
   directory:
   ```bash
   ./docker_up.sh \
     --statements ~/Documents/FinAgent/statements \
     --processing ~/Documents/FinAgent/processing \
       --port 3001 \
       --docs-port 3003
   ```
    The launcher rejects malformed, privileged, conflicting, or out-of-range
    ports before it invokes Docker. If `--docs-port` is omitted, documentation
    uses the dashboard port plus 2.

    Ollama is already installed in the image. In an interactive terminal the
    launcher asks whether to download `qwen2.5:0.5b`; use `--ollama-model`
    (optionally followed by another model name) or `--no-ollama-model` for
    non-interactive runs. Downloaded models persist in the `ollama-data` Docker
   volume. An explicit model selection becomes the active model shown in
   Settings for that launch, even when the mounted config contains an older
   model. Without an explicit choice, an existing Settings selection is
   preserved; a fresh config starts with provider `none` and downloads no
   model.

    For Claude or OpenRouter, no provider CLI installation is needed because
    FinAgent calls their HTTPS APIs directly. Keep the key out of shell history:
    ```bash
    printf '%s\n' 'ANTHROPIC_API_KEY=your-key' > ~/.config/finagent/docker.env
    chmod 600 ~/.config/finagent/docker.env
    ./docker_up.sh --llm-provider claude --env-file ~/.config/finagent/docker.env \
       --statements ~/Documents/FinAgent/statements \
       --processing ~/Documents/FinAgent/processing
    ```
    For OpenRouter, use `OPENROUTER_API_KEY=...` and
    `--llm-provider open_router`. The key is injected at runtime, masked in the
    dashboard, and is not copied into the image. Providers can still be changed
    later in Settings.

5. **Verify the service**:
   ```bash
   docker ps --filter name=finagent
   docker logs finagent
   curl http://localhost:3001/api/config
   ```
   Open `http://localhost:3001` and documentation at
   `http://localhost:3003`. The API response should report Docker mode,
   `/data/statements`, and `/data/processing`. Import a small supported bank
   statement, run processing from the dashboard, and confirm output appears in
   the host processing folder.

6. **Restart and verify persistence**:
   ```bash
   docker restart finagent
   curl http://localhost:3001/api/config
   ```
   Configuration and imported data should remain because all three data
   directories are host mounts.

7. **Stop and remove the container** from the launcher directory:
   ```bash
   docker compose --project-name finagent down
   ```

The versioned `FinAgent-<version>-Docker-x86_64.tar.gz` image is the Docker
artifact. `FinAgent-Docker-x86_64.tar.gz` is its stable latest-download alias.
The release also includes `docker_up.sh` and `docker-compose.yml`; these are
launcher assets, not another application image. The published image is x86_64.
Apple Silicon Docker Desktop can run it through emulation; native ARM Linux
requires a separately built ARM64 image.

---

## Windows

1. **Download** the latest Windows installer:
   [FinAgent-Windows-x64.exe](https://github.com/malfihasan/financialAgent-public/releases/latest/download/FinAgent-Windows-x64.exe).

2. **Run the installer.** It includes the dashboard runtime and creates Start
   Menu shortcuts; a desktop shortcut is optional. No separate Python or
   Node.js installation is required.

3. If SmartScreen appears, click **More info → Run anyway**.

4. Leave **Launch FinAgent** selected on the final page. Your browser opens to
   first-run setup. Later, use the Start Menu or desktop shortcut.

If installation fails unexpectedly, FinAgent creates a short, non-secret
diagnostic in the Windows temporary folder and opens a pre-filled GitHub issue
for your review. Attach the installer log only if a maintainer requests it.

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
| **Contact e-mail** | Optional contact shared with OpenStreetMap only when enabled |

Settings are saved to `~/.finagent/config.json`.  
Re-run the wizard at any time with `finagent --reconfigure`.

---

## Adding Bank Statements

1. Download a CSV or supported tabular text statement export from your bank.
   PDF statements are not supported.
2. Choose **Import bank statements** from FinAgent's terminal menu to open the
   dashboard Import page, then select the bank/account and upload the file.
   Advanced users can instead rename it and drop it in the matching folder:

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

Keys saved during setup are loaded automatically. Otherwise, export the key
before using a cloud provider from the terminal:

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
$env:ANTHROPIC_API_KEY = "sk-ant-your-key"
```

---

## Viewing the Dashboard

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

---

## Troubleshooting

**"No transaction CSV found"** — Run normal statement processing to create or
update `dashboard_data/master_transactions.csv`.

**"Ollama not found"** — Install Ollama from [ollama.com](https://ollama.com/) and
pull your chosen model: `ollama pull qwen2.5:3b`.

**Dashboard blank / port conflict** — Check if another process is using the port:
`lsof -i :3001`. Change the port with `finagent --reconfigure`.

**Re-run setup** — `finagent --reconfigure` or `python setup_wizard.py --reconfigure`.
