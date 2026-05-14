#!/usr/bin/env bash
set -Eeuo pipefail

project_name="my-project"
run_dev=false
run_shadcn=true
use_src_dir=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dev)
      run_dev=true
      ;;
    --no-shadcn)
      run_shadcn=false
      ;;
    --src-dir)
      use_src_dir=true
      ;;
    -h|--help)
      echo "Usage: $0 [project-name] [--src-dir] [--dev] [--no-shadcn]"
      echo "Prerequisites: Node.js >= 20, pnpm (or corepack available)"
      echo "Example: $0 my-project"
      echo "Example: $0 my-project --src-dir"
      echo "Example: $0 my-project --dev"
      echo "Example: $0 my-project --no-shadcn"
      exit 0
      ;;
    *)
      if [[ "$1" == -* ]]; then
        echo "[error] Unknown option: $1"
        exit 1
      fi
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

ensure_import_alias() {
  local alias_target="$1"
  local config_file=""

  if [[ -f tsconfig.json ]]; then
    config_file="tsconfig.json"
  elif [[ -f jsconfig.json ]]; then
    config_file="jsconfig.json"
  else
    echo "[warn] No tsconfig.json or jsconfig.json found. Skipping @/* alias check."
    return
  fi

  node - "$config_file" "$alias_target" <<'NODE'
const fs = require("fs")
const [configFile, aliasTarget] = process.argv.slice(2)
const raw = fs.readFileSync(configFile, "utf8")

let data
try {
  data = JSON.parse(raw)
} catch (error) {
  console.error(`[error] ${configFile} is not valid JSON.`)
  console.error(`[hint] Configure compilerOptions.paths['@/*'] manually to ['${aliasTarget}']`)
  process.exit(1)
}

data.compilerOptions ||= {}
data.compilerOptions.baseUrl ||= "."
data.compilerOptions.paths ||= {}
data.compilerOptions.paths["@/*"] = [aliasTarget]

fs.writeFileSync(configFile, `${JSON.stringify(data, null, 2)}\n`)
NODE

  echo "[info] Ensured @/* import alias in $config_file -> $alias_target"
}

ensure_tailwind_for_existing_project() {
  if node -e 'const p=require("./package.json");const deps={...(p.dependencies||{}),...(p.devDependencies||{})};process.exit(deps.tailwindcss?0:1)'; then
    return
  fi

  echo "[error] Tailwind CSS is missing in this existing project."
  echo "[hint] Install Tailwind following the official Next.js docs, then rerun this script."
  exit 1
}

setup_shadcn() {
  if [[ "$run_shadcn" != true ]]; then
    echo "[info] Skipping shadcn/ui setup (--no-shadcn)."
    return
  fi

  if [[ -f components.json ]]; then
    echo "[info] shadcn/ui already initialized (components.json found)."
    return
  fi

  echo "[info] Initializing shadcn/ui with default options..."
  if pnpm dlx shadcn@latest init -d; then
    return
  fi

  echo "[error] Unable to initialize shadcn/ui automatically."
  echo "[hint] Try manually: pnpm dlx shadcn@latest init"
  exit 1
}

require_cmd node
ensure_node_version
ensure_pnpm

project_dir="$(pwd)/$project_name"
created_project=false

if [[ ! -d "$project_name" ]]; then
  echo "[info] Creating Next.js project with recommended defaults: $project_name"
  create_cmd=(pnpm create next-app@latest "$project_name" --typescript --eslint --tailwind --app --use-pnpm --import-alias "@/*" --yes)
  if [[ "$use_src_dir" == true ]]; then
    create_cmd+=(--src-dir)
  fi
  "${create_cmd[@]}"
  created_project=true
elif [[ ! -f "$project_name/package.json" ]]; then
  echo "[error] Directory '$project_name' exists but is not a Node project (missing package.json)."
  exit 1
else
  echo "[info] Project already exists: $project_name (skipping create-next-app)"
fi

cd "$project_dir"

echo "[info] Installing project dependencies..."
pnpm install

if [[ "$created_project" != true ]]; then
  ensure_tailwind_for_existing_project
fi

alias_target="./*"
if [[ "$use_src_dir" == true || -d src/app ]]; then
  alias_target="./src/*"
fi
ensure_import_alias "$alias_target"

setup_shadcn

if [[ "$run_dev" == true ]]; then
  echo "[info] Starting dev server in $project_name..."
  exec pnpm dev
fi

echo "[ok] Setup complete for $project_name"
