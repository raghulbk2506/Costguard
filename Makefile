.PHONY: help install install-frontend build test test-cov cli-demo backend clean

help:
	@echo "CostGuard Build & Automation Tool"
	@echo "================================="
	@echo "make install          - Install Python dependencies and package in editable mode"
	@echo "make install-frontend - Install npm dependencies in frontend"
	@echo "make build            - Compile frontend React dashboard into production dist"
	@echo "make test             - Run complete automated pytest test suite"
	@echo "make cli-demo         - Run all 4 test plans through the CostGuard CLI"
	@echo "make backend          - Launch FastAPI web server on port 8000"
	@echo "make clean            - Remove build artifacts, pycache, and temp files"

install:
	pip install -e .
	pip install -r backend/requirements.txt

install-frontend:
	cd frontend && npm install

build:
	cd frontend && npm run build

test:
	pytest tests/ -v

test-cov:
	pytest tests/ --cov=costguard --cov-report=term-missing

cli-demo:
	@echo "--- 1. Plan A (Small Add: +$27.30/mo) ---"
	costguard --plan test-plans/plan_a_small_add.json --max-increase 50
	@echo "\n--- 2. Plan B (Upgrade & Delete: +$34.90/mo - Pass) ---"
	costguard --plan test-plans/plan_b_upgrade_delete.json --max-increase 50
	@echo "\n--- 3. Plan B (Circuit Breaker Breach: +$34.90/mo > $20 limit - Exit 1) ---"
	-costguard --plan test-plans/plan_b_upgrade_delete.json --max-increase 20
	@echo "\n--- 4. Plan C (Hostile Noise: 15 non-billable resources skipped - +$0.00/mo) ---"
	costguard --plan test-plans/plan_c_hostile_noise.json
	@echo "\n--- 5. Plan D (Metadata-Only: VM tag update - +$0.00/mo) ---"
	costguard --plan test-plans/plan_d_metadata_only.json

backend:
	uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload

clean:
	rm -rf .pytest_cache .coverage htmlcov build dist *.egg-info
	find . -type d -name "__pycache__" -exec rm -rf {} +
