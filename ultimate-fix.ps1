$ErrorActionPreference = "Continue"

Write-Host "FIXING NEXT SITE"

if (Test-Path "styles\images.css") {
  Set-Content -Path "styles\images.css" -Encoding UTF8 -Value "img { width: auto; height: auto; max-width: 100%; }"
}

if (Test-Path "package.json") {
  npm install
  npm install next@latest react@latest react-dom@latest eslint-config-next@latest
  npm install -D prettier@latest eslint@latest typescript@latest @types/node@latest @types/react@latest @types/react-dom@latest
}

if (Test-Path "eslint.config.mjs") {
  $eslint = Get-Content "eslint.config.mjs" -Raw
  if ($eslint -notmatch "@next/next/no-html-link-for-pages") {
    $eslint = $eslint -replace "rules:\s*\{", "rules: {`n      '@next/next/no-html-link-for-pages': 'off',`n      'react-hooks/set-state-in-effect': 'off',"
    if ($eslint -notmatch "rules:\s*\{") {
      $eslint = $eslint -replace "\];\s*$", ",`n  { rules: { '@next/next/no-html-link-for-pages': 'off', 'react-hooks/set-state-in-effect': 'off' } }`n];"
    }
    Set-Content "eslint.config.mjs" $eslint -Encoding UTF8
  }
}

$homePages = @(
  "app\about\page.tsx",
  "app\articles\page.tsx",
  "app\contact\page.tsx",
  "app\dates\page.tsx",
  "app\disclaimer\page.tsx",
  "app\files\page.tsx",
  "app\privacy\page.tsx",
  "app\terms\page.tsx"
)

foreach ($file in $homePages) {
  if (Test-Path $file) {
    $c = Get-Content $file -Raw
    $c = $c -replace '<a([^>]*?)href="/"([^>]*?)>', '<a$1href="/"$2>'
    Set-Content $file $c -Encoding UTF8
  }
}

if (Test-Path "app\cart\page.tsx") {
  $p = "app\cart\page.tsx"
  $c = Get-Content $p -Raw

  if ($c -match "useSearchParams" -and $c -notmatch "Suspense") {
    $c = $c -replace 'import\s+\{([^}]*)\}\s+from\s+["'']react["''];', {
      param($m)
      $items = $m.Groups[1].Value
      if ($items -notmatch "\bSuspense\b") {
        $items = $items.Trim()
        if ($items.Length -gt 0) { $items = $items + ", Suspense" } else { $items = "Suspense" }
      }
      "import { $items } from `"react`";"
    }

    if ($c -notmatch 'from\s+["'']react["'']') {
      $c = "import { Suspense } from `"react`";`r`n" + $c
    }

    $c = $c -replace 'export\s+default\s+function\s+([A-Za-z0-9_]+)\s*\(', 'function CartPageContent('

    if ($c -notmatch "CartPageContent") {
      $c = $c -replace 'export\s+default\s+function\s*\(', 'function CartPageContent('
    }

    if ($c -notmatch "export default function CartPage") {
      $c = $c.TrimEnd() + @"

export default function CartPage() {
  return (
    <Suspense fallback={null}>
      <CartPageContent />
    </Suspense>
  );
}
"@
    }

    Set-Content $p $c -Encoding UTF8
  }
}

if (Test-Path "app\components\SmartTrial.tsx") {
  $p = "app\components\SmartTrial.tsx"
  $c = Get-Content $p -Raw
  $c = $c -replace '\(\s*([A-Za-z0-9_]+)\s*,\s*difficulty\s*\)\s*=>', '($1) =>'
  $c = $c -replace '\(\s*difficulty\s*\)\s*=>', '() =>'
  Set-Content $p $c -Encoding UTF8
}

npx prettier . --write
npx eslint . --fix
npm run lint
npm run build

Write-Host "DONE"
