<div align="center">

# FinAgent

**Privacy-first personal finance automation, local by default.**

[![Latest Release](https://img.shields.io/badge/Latest%20Release-latest-brightgreen?style=flat-square)](https://github.com/malfihasan/financialAgent-public/releases/latest)
[![License: Personal Use](https://img.shields.io/badge/license-Personal%20Use-blue?style=flat-square)](LICENSE)
[![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey?style=flat-square)](https://github.com/malfihasan/financialAgent-public/releases/latest)

</div>

FinAgent turns downloaded bank statements into categorized transactions, budgets,
and financial trends without requiring bank credentials or a hosted FinAgent account.
Statement files, rules, configuration, and processed results remain in folders you
control on your computer.

## What It Does

- Imports and normalizes statement files from Bank of America, American Express,
  Chase, Citi, and U.S. Bank.
- Categorizes transactions with editable rules, optional merchant/location lookup,
  and optional Ollama, Claude, or OpenRouter assistance.
- Maintains one persistent transaction master while preserving categories edited
  from the dashboard.
- Supports inclusive date-range views without deleting older transaction history.
- Provides a local dashboard for totals, trends, category analysis, transaction
  review, budgets, and rule management.
- Keeps monthly budget archives and asks before replacing an existing archive.
- Runs with a guided setup and statement-import workflow on macOS, Linux, and Windows.

## Privacy

FinAgent never asks for online-banking passwords and does not connect directly to
bank accounts. Local or no-LLM configurations keep financial processing on your
machine. If you enable a cloud LLM or external location service, relevant prompt or
lookup data is sent to that provider under its privacy terms.

## Download

Download the latest build from the
[FinAgent Releases page](https://github.com/malfihasan/financialAgent-public/releases/latest).

See [INSTALL.md](INSTALL.md) for platform requirements, installation, first-run
setup, statement folders, commands, and troubleshooting.

## Support

Found a bug or need support for another bank? Open an
[issue](https://github.com/malfihasan/financialAgent-public/issues) with your OS,
FinAgent version, expected behavior, and anonymized sample rows when relevant.
Never attach account numbers, credentials, API keys, or unredacted financial data.

FinAgent is free for personal use. You can also
[buy the developer a coffee](https://www.buymeacoffee.com/alfi_hasan).

## License

FinAgent binaries are provided for personal, non-commercial use. Redistribution or
resale is not permitted. See [LICENSE](LICENSE) for complete terms. Source code is
maintained in a private repository.
