#!/usr/bin/env bash
set -Eeuo pipefail

project_name="my-project"
run_dev=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dev)
      run_dev=true
      ;;
    -h|--help)
      echo "Usage: $0 [project-name] [--dev]"
      echo "Prerequisites: Node.js >= 20, pnpm (or corepack available)"
      echo "Example: $0 my-project"
      echo "Example: $0 my-project --dev"
      exit 0
      ;;
    *)
      project_name="$1"
      ;;
  esac
  shift
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[error] Missing command: $1"
    exit 1
  fi
}

ensure_node_version() {
  local major
  major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [[ "$major" -lt 20 ]]; then
    echo "[error] Node.js >= 20 is required (detected: $(node -v 2>/dev/null || echo unknown))."
    exit 1
  fi
}

ensure_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    return
  fi

  if command -v corepack >/dev/null 2>&1; then
    echo "[info] pnpm not found, enabling it via corepack..."
    corepack enable
  fi

  if ! command -v pnpm >/dev/null 2>&1; then
    echo "[error] pnpm is required. Install Node.js with corepack, or install pnpm manually."
    exit 1
  fi
}

require_cmd node
ensure_node_version
ensure_pnpm

project_dir="$(pwd)/$project_name"

if [[ ! -d "$project_name" ]]; then
  echo "[info] Creating Next.js project: $project_name"
  pnpm dlx create-next-app@latest "$project_name" --typescript --eslint --use-pnpm --no-tailwind --disable-git --yes
elif [[ ! -f "$project_name/package.json" ]]; then
  echo "[error] Directory '$project_name' exists but is not a Node project (missing package.json)."
  exit 1
else
  echo "[info] Project already exists: $project_name (skipping create-next-app)"
fi

cd "$project_dir"

echo "[info] Installing project dependencies..."
pnpm install

echo "[info] Installing Tailwind v3 dependencies..."
pnpm add -D tailwindcss@3 postcss autoprefixer
pnpm remove @tailwindcss/postcss >/dev/null 2>&1 || true

echo "[info] Initializing Tailwind config files..."
pnpm exec tailwindcss init -p

echo "[info] Writing tailwind.config.js..."
cat > tailwind.config.js <<'CONFIG'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",

    // Or if using `src` directory:
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
CONFIG

echo "[info] Writing PostCSS config for Tailwind v3..."
cat > postcss.config.mjs <<'POSTCSS'
const config = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};

export default config;
POSTCSS
rm -f postcss.config.js

globals_css=""
if [[ -f src/app/globals.css ]]; then
  globals_css="src/app/globals.css"
elif [[ -f app/globals.css ]]; then
  globals_css="app/globals.css"
else
  mkdir -p src/app
  globals_css="src/app/globals.css"
  touch "$globals_css"
fi

echo "[info] Updating $globals_css..."
tmp_file="$(mktemp)"
{
  echo "@tailwind base;"
  echo "@tailwind components;"
  echo "@tailwind utilities;"
  echo
  awk '!/^@tailwind (base|components|utilities);$/' "$globals_css"
} > "$tmp_file"
mv "$tmp_file" "$globals_css"

if [[ "$run_dev" == true ]]; then
  echo "[info] Starting dev server in $project_name..."
  exec pnpm dev
fi

echo "[ok] Setup complete for $project_name"
