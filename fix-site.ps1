$ErrorActionPreference = "Continue"

Write-Host "START FIX SITE"

if (Test-Path "package.json") {
  Write-Host "NODE PROJECT DETECTED"

  if (Test-Path "pnpm-lock.yaml") {
    corepack enable 2>$null
    corepack prepare pnpm@latest --activate 2>$null
    pnpm install
    pnpm audit --fix
    pnpm exec prettier . --write
    pnpm exec eslint . --fix
    pnpm run lint
    pnpm run typecheck
    pnpm test
    pnpm run build
  }
  elseif (Test-Path "yarn.lock") {
    corepack enable 2>$null
    corepack prepare yarn@stable --activate 2>$null
    yarn install
    yarn audit
    yarn prettier . --write
    yarn eslint . --fix
    yarn lint
    yarn typecheck
    yarn test
    yarn build
  }
  else {
    npm install
    npm audit fix
    npx prettier . --write
    npx eslint . --fix
    npm run lint
    npm run typecheck
    npm test
    npm run build
  }
}

if (Test-Path "composer.json") {
  Write-Host "PHP PROJECT DETECTED"
  composer install
  composer update --with-all-dependencies

  if (Test-Path "artisan") {
    php artisan optimize:clear
    php artisan migrate --force
    php artisan optimize
  }

  if (Test-Path "vendor\bin\pint") {
    vendor\bin\pint
  }

  if (Test-Path "vendor\bin\phpstan") {
    vendor\bin\phpstan analyse
  }
}

if ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml") -or (Test-Path "manage.py")) {
  Write-Host "PYTHON PROJECT DETECTED"

  py -m venv .venv
  .\.venv\Scripts\python.exe -m pip install -U pip setuptools wheel

  if (Test-Path "requirements.txt") {
    .\.venv\Scripts\pip.exe install -r requirements.txt
  }

  if (Test-Path "pyproject.toml") {
    .\.venv\Scripts\pip.exe install -e .
  }

  .\.venv\Scripts\pip.exe install ruff black pytest
  .\.venv\Scripts\ruff.exe check . --fix
  .\.venv\Scripts\black.exe .

  if (Test-Path "manage.py") {
    .\.venv\Scripts\python.exe manage.py check
    .\.venv\Scripts\python.exe manage.py migrate
  }

  .\.venv\Scripts\pytest.exe
}

if ((Test-Path "Dockerfile") -or (Test-Path "docker-compose.yml") -or (Test-Path "compose.yaml")) {
  Write-Host "DOCKER PROJECT DETECTED"
  docker compose config
  docker compose build
}

Write-Host "DONE"
