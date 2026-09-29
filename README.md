# 🛡️ CostGuard: Infrastructure Cost Impact Firewall

> **Predict infrastructure cost impact before `terraform apply`. Enforce budget guardrails in CI/CD with sub-50ms evaluations, live Azure Retail Prices, and zero cloud credentials required.**

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg?logo=python&logoColor=white)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115%2B-009688.svg?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/React-18.3-61DAFB.svg?logo=react&logoColor=black)](https://react.dev)
[![Vite](https://img.shields.io/badge/Vite-5.4-646CFF.svg?logo=vite&logoColor=white)](https://vitejs.dev)
[![Tailwind CSS](https://img.shields.io/badge/TailwindCSS-3.4-38B2AC.svg?logo=tailwind-css&logoColor=white)](https://tailwindcss.com)
[![SQLite](https://img.shields.io/badge/SQLite-Write--Through_Cache-003B57.svg?logo=sqlite&logoColor=white)](https://sqlite.org)
[![Tests](https://img.shields.io/badge/Tests-44%20Passed-success.svg?logo=pytest&logoColor=white)](tests/)

---

## 🌟 Overview

**CostGuard** is an open-source FinOps firewall and infrastructure cost predictor. It inspects Terraform Plan JSON files during code review or pull request checks, automatically identifies compute and storage modifications, fetches live regional pricing from Microsoft's public **Azure Retail Prices API**, computes monthly cost deltas normalized to standard 730 hours/month, and enforces budget policies with strict POSIX exit codes.

```
       ┌────────────────────────┐
       │  Terraform Plan JSON   │
       │ (stdin or --plan file) │
       └───────────┬────────────┘
                   │
                   ▼
       ┌────────────────────────┐
       │   CostGuard Parser     │  Extracts actions (create, delete, update, replace)
       │  & Resource Sizer      │  Normalizes regions (East US -> eastus)
       └───────────┬────────────┘  Safely skips 15+ non-billable types
                   │
                   ▼
        ┌───────────────────────┐
        │  SQLite Cache Engine  │◄────────────┐ (Sub-30ms repeat hits)
        │  (pricing_cache.db)   │             │
        └───────────┬───────────┘             │
            MISS    │                         │
                    ▼                         │
        ┌───────────────────────┐             │ WRITE-THROUGH
        │  Azure Retail Prices  ├─────────────┘
        │   REST API (Live)     │ (OData $filter, non-spot, consumption)
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  Delta Cost Engine    │ Normalizes hourly meters to 730h/month baseline
        │  (730 hrs baseline)   │ Accurate delta math: Prior, Projected, Net Delta
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Policy Guardrail Check│ Net Delta > Max Increase ?
        └─────┬───────────┬─────┘
       PASS   │           │ BREACH
              ▼           ▼
         Exit Code 0   Exit Code 1
       (CI/CD Green) (CI/CD Blocked)
```

---

## 🚀 Key Capabilities

* **Standalone POSIX CLI**: Zero dependencies on web services; supports piped standard input (`cat plan.json | costguard`) and file flag (`--plan`).
* **Strict POSIX Exit Codes**:
  - `0`: Plan approved (monthly cost delta within allowed budget ceiling).
  - `1`: Budget breached (monthly cost delta exceeds `--max-increase` threshold).
  - `2`: Operational failure (invalid JSON format, missing file, or invalid parameters).
* **Live Azure Retail Prices API**: Directly queries Microsoft's public OData endpoint (`https://prices.azure.com/api/retail/prices`) with zero API keys or Azure subscriptions required.
* **SQLite Write-Through Cache**: High-speed local database (`pricing_cache.db`) cuts evaluation times from ~500ms (cold API) to **<25ms** on warm cache hits.
* **Intelligent Noise Filtering**: Gracefully filters and skips 15+ non-billable Azure resource types (`azurerm_resource_group`, `azurerm_virtual_network`, `azurerm_subnet`, `azurerm_network_security_group`, etc.).
* **PR Markdown & JSON Output**: Produces formatted Rich terminal tables, GitHub Actions PR Markdown comment summaries, or machine-readable JSON.
* **Full-Stack Web Dashboard**: Built with FastAPI, React 18, TypeScript, Tailwind CSS, Lucide icons, and Recharts for interactive analytics, live pricing queries, cache inspection, and sandbox testing.

---

## 📦 Project Structure

```
costguard/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py              # FastAPI app with CORS & static frontend serving
│   │   └── routes.py            # REST endpoints (analyze, cache, pricing, guardrails)
│   └── requirements.txt         # Backend Python dependencies
├── costguard/
│   ├── __init__.py              # Core library export
│   ├── cli/
│   │   ├── __init__.py
│   │   └── main.py              # Click + Rich CLI implementation
│   └── core/
│       ├── __init__.py
│       ├── cache.py             # SQLite write-through pricing cache
│       ├── calculator.py        # 730h cost calculation & delta math
│       ├── guardrail.py         # Policy breaker & exit code enforcement
│       ├── models.py            # Pydantic data schemas
│       ├── pricing.py           # Azure Retail Prices REST API client
│       └── resources.py         # Terraform parser, sizer, region normalizer
├── frontend/
│   ├── src/
│   │   ├── components/          # Header, Sidebar, MetricsCard, etc.
│   │   ├── pages/               # Overview, Analyze, Pricing, Cache, Guardrails, Docs
│   │   ├── types/               # TypeScript interfaces
│   │   ├── App.tsx              # Main routing & application state
│   │   └── main.tsx             # React entry point
│   ├── dist/                    # Compiled production assets (SPA)
│   ├── package.json
│   ├── tailwind.config.js
│   └── vite.config.ts
├── test-plans/
│   ├── plan_a_small_add.json       # 1 VM (B1s) + 1 Disk (P10) in eastus (+ $27.30/mo)
│   ├── plan_b_upgrade_delete.json  # Upgrade B1s->B2s, add P10, delete B1s (+ $34.90/mo)
│   ├── plan_c_hostile_noise.json   # 15 non-billable network/metadata resources ($0.00)
│   └── plan_d_metadata_only.json   # Tag update on VM with zero sizing change ($0.00)
├── tests/                       # Pytest test suite (44 tests, 100% offline)
├── pyproject.toml               # Poetry/pip editable package definition
├── REPORT.md                    # Detailed engineering report
├── Makefile                     # Build & developer automation
└── README.md                    # Project documentation
```

---

## ⚡ Quick Start

### 1. Installation

```bash
# Clone or navigate to the repository
cd costguard

# Create and activate Python virtual environment
python -m venv .venv
source .venv/bin/activate       # On Windows: .venv\Scripts\activate

# Install costguard CLI in editable mode
pip install -e .
pip install -r backend/requirements.txt
```

### 2. Standalone CLI Usage

```bash
# Analyze a Terraform plan file
costguard --plan test-plans/plan_a_small_add.json --max-increase 50.0

# Pipe a plan via stdin
cat test-plans/plan_b_upgrade_delete.json | costguard --max-increase 50.0

# Test circuit breaker failure (Exit Code 1)
costguard --plan test-plans/plan_b_upgrade_delete.json --max-increase 20.0
echo $?  # Prints 1

# Generate GitHub PR Markdown comment
costguard --plan test-plans/plan_b_upgrade_delete.json --markdown

# Output machine-readable JSON
costguard --plan test-plans/plan_a_small_add.json --json
```

### 3. CLI Command-Line Reference

| Flag | Short | Default | Description |
| :--- | :---: | :---: | :--- |
| `--plan` | `-p` | `stdin` | Path to Terraform Plan JSON file. If omitted, reads from stdin. |
| `--max-increase` | `-m` | `50.0` | Maximum allowed monthly cost delta before triggering exit code 1. |
| `--currency` | `-c` | `USD` | Target pricing currency code (e.g. `USD`, `EUR`, `GBP`). |
| `--clear-cache` | | `False` | Purges the local SQLite pricing database before evaluating. |
| `--markdown` | | `False` | Emits a GitHub Actions PR comment markdown summary. |
| `--json` | `-j` | `False` | Emits raw machine-readable JSON output for CI pipeline parsing. |
| `--quiet` | `-q` | `False` | Suppresses verbose terminal tables, printing only verdict & delta. |
| `--help` | `-h` | | Displays help and flag reference. |

---

## 📊 Test Plans & Results Matrix

| Test Plan | Changes / Actions | Detected Resources | Prior Cost | Projected Cost | Net Delta | Policy Threshold | Status | Exit Code | Evaluation Time |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: | :--- |
| **Plan A: Small Add** | 1 VM Create (`Standard_B1s`)<br>1 Disk Create (`P10 128GB`) | 2 billable in `eastus` | $0.00 | $27.30 | **+$27.30** | $50.00 | **PASSED** | `0` | Cold: ~380ms<br>Warm: ~18ms |
| **Plan B: Upgrade & Delete (Pass)** | 1 VM Upgrade (`B1s` $\rightarrow$ `B2s`)<br>1 Disk Create (`P10`)<br>1 VM Delete (`B1s`) | 3 compute & disk actions | $15.18 | $50.08 | **+$34.90** | $50.00 | **PASSED** | `0` | Cold: ~540ms<br>Warm: ~24ms |
| **Plan B: Budget Breach (Fail)** | 1 VM Upgrade (`B1s` $\rightarrow$ `B2s`)<br>1 Disk Create (`P10`)<br>1 VM Delete (`B1s`) | 3 compute & disk actions | $15.18 | $50.08 | **+$34.90** | $20.00 | **FAILED** | `1` | Cold: ~540ms<br>Warm: ~22ms |
| **Plan C: Hostile Noise** | 15 Creates (VNet, Subnets, NSGs, Route Tables) | 0 billable (15 skipped) | $0.00 | $0.00 | **+$0.00** | $50.00 | **PASSED** | `0` | <8ms (no network) |
| **Plan D: Metadata-Only** | 1 VM Update (Tags changed, sizing unchanged) | 1 VM in `eastus` | $30.37 | $30.37 | **+$0.00** | $50.00 | **PASSED** | `0` | Warm: ~14ms |

---

## 🧪 Automated Testing

CostGuard includes an automated test suite of 44 tests across 8 test suites with 100% offline execution via mocked HTTP fixtures:

```bash
# Run the complete test suite
pytest tests/ -v
```

Test coverage encompasses:
* `test_parser.py`: Ingestion of valid/malformed JSON, action extraction, empty plans.
* `test_resources.py`: VM size extraction, disk tier mappings (P4-P80), region normalization, non-billable resource skipping.
* `test_pricing.py`: Azure Retail Prices API client queries, OData filter formatting, rate limit and timeout fallbacks.
* `test_cache.py`: SQLite write-through cache insertion, hit/miss tracking, cache clearing.
* `test_calculator.py`: 730-hour normalization, delta calculation across create, delete, update, and replace lifecycles.
* `test_guardrail.py`: Strict enforcement of exit codes 0 and 1, edge cases on exact threshold boundaries.
* `test_cli.py`: Click CLI entry point, stdin piping, `--plan`, `--json`, and `--markdown` formatting.
* `test_api.py`: FastAPI endpoints for health, analyze, file uploads, demo fixtures, cache management, and pricing queries.

---

## 🌐 Full-Stack Web Application

The repository contains a full-stack web UI built with FastAPI and React:

```bash
# Start the unified web server (serves FastAPI API and built React SPA on port 8000)
uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
```

Then navigate to: **`http://localhost:8000`**

### Available Pages:
* **Overview**: Executive KPI metrics, high-level cost summary, recent scans, and quick actions.
* **Dashboard**: Cost breakdown by resource type, interactive Recharts visualization, and action distribution.
* **Analyze Plan**: Drag-and-drop Terraform plan upload, paste raw JSON, or execute built-in demo plans with real-time feedback.
* **Cost Breakdown**: Tabular itemization of prior cost, projected cost, and dollar deltas per resource.
* **Pricing Explorer**: Direct interactive search tool into the live Azure Retail Prices API.
* **SQLite Cache Manager**: Live database inspector displaying cached SKUs, entry counts, hit ratios, and one-click cache purge.
* **Guardrails**: Configure organization budget limits, alert thresholds, and currency preferences.
* **Test Plans**: Sandbox for running pre-loaded benchmark fixtures (Plan A, B, C, D).
* **Terminal Simulator**: In-browser interactive CLI emulator demonstrating exact terminal output.
* **Documentation**: Embedded architectural guide and API reference.

---

## 🔄 GitHub Actions CI/CD Integration

Integrate CostGuard into your pull request pipeline to block infrastructure changes that breach budget thresholds:

```yaml
name: "CostGuard FinOps Firewall"

on:
  pull_request:
    branches: [ main ]

jobs:
  costguard:
    name: "Evaluate Infrastructure Cost Impact"
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"
          cache: "pip"

      - name: Install CostGuard
        run: |
          python -m pip install --upgrade pip
          pip install .

      - name: Generate Terraform Plan JSON
        run: |
          terraform init
          terraform plan -out=tfplan.binary
          terraform show -json tfplan.binary > plan.json

      - name: Run CostGuard Firewall
        id: costguard
        run: |
          costguard --plan plan.json --max-increase 50.0 --markdown > cost_comment.md
        continue-on-error: true

      - name: Comment PR with Cost Impact
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const body = fs.readFileSync('cost_comment.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: body
            });

      - name: Enforce Budget Circuit Breaker
        run: |
          costguard --plan plan.json --max-increase 50.0 --quiet
```

---

## 📄 License

CostGuard is released under the **MIT License**.
