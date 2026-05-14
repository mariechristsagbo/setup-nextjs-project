# Setup Next.js + shadcn/ui

Ce dépôt fournit des scripts Bash pour automatiser la création d'un projet **Next.js (TypeScript)** avec les defaults recommandés, puis initialiser **shadcn/ui**.

## Objectif

Automatiser le workflow recommandé par la doc shadcn/ui:

- création du projet avec `create-next-app`;
- Tailwind CSS + App Router + alias `@/*` configurés dès la création;
- option `src/` via `--src-dir`;
- vérification de l'alias `@/*` pour projets existants;
- initialisation de `shadcn/ui`.

## Prérequis

- `node` version 20 ou supérieure;
- `pnpm` (ou `corepack` disponible pour activer pnpm);
- `bash`.

## Structure

- `Makefile`: commandes d'orchestration.
- `scripts/run-sequential.sh`: exécute des commandes ligne par ligne depuis un fichier.
- `scripts/setup-next-tailwind.sh`: setup Next.js + alias + shadcn/ui.
- `setup.commands.example`: exemple de commandes séquentielles.
- `setup.commands`: fichier utilisé par `make setup`.

## Commandes disponibles

### 1. Initialiser le fichier de commandes

```bash
make setup-init
```

Crée `setup.commands` à partir de `setup.commands.example` s'il n'existe pas.

### 2. Exécuter les commandes séquentielles

```bash
make setup
```

Lit `setup.commands`, ignore les lignes vides/commentées (`#`), exécute chaque ligne et s'arrête au premier échec.

### 3. Setup standard (recommandé)

```bash
make setup-next PROJECT_NAME=my-project
```

- Crée le projet s'il n'existe pas avec les defaults recommandés (`tailwind`, `app router`, alias `@/*`).
- Si le projet existe déjà, il est réutilisé.
- Lance `shadcn init` en mode defaults.

### 4. Setup avec dossier `src/`

```bash
make setup-next-src PROJECT_NAME=my-project
```

Crée le projet avec `--src-dir` (ou force l'alias `@/*` vers `./src/*` sur un projet existant).

### 5. Setup + démarrage du serveur dev

```bash
make setup-next-dev PROJECT_NAME=my-project
```

Fait le setup puis exécute `pnpm dev`.

### 6. Setup sans shadcn/ui

```bash
make setup-next-no-shadcn PROJECT_NAME=my-project
```

Fait le setup Next.js sans lancer `shadcn init`.

## Utilisation directe du script

```bash
./scripts/setup-next-tailwind.sh my-project
./scripts/setup-next-tailwind.sh my-project --src-dir
./scripts/setup-next-tailwind.sh my-project --dev
./scripts/setup-next-tailwind.sh my-project --no-shadcn
```

Aide:

```bash
./scripts/setup-next-tailwind.sh --help
```

## Projets existants

Pour un projet existant:

- le script vérifie la présence de Tailwind CSS;
- il garantit l'alias `@/*` dans `tsconfig.json` (ou `jsconfig.json`), vers `./*` ou `./src/*`.

Si Tailwind est absent, le script s'arrête et demande d'installer Tailwind d'abord (comme recommandé par la doc).

## Comportement en cas d'erreur

- `run-sequential.sh` stoppe immédiatement si une commande échoue.
- `setup-next-tailwind.sh` stoppe si un prérequis manque (`node`, version, `pnpm`) ou si `shadcn init` échoue.
