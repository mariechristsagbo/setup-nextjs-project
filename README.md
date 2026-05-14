# Setup Next.js + Tailwind v3

Ce dépôt fournit des scripts Bash pour automatiser la création et la configuration d'un projet **Next.js (TypeScript)** avec **Tailwind CSS v3**.

## Objectif

Éviter de refaire manuellement les mêmes étapes de bootstrap:

- création d'un projet Next.js;
- installation des dépendances Tailwind v3;
- génération des fichiers de configuration Tailwind/PostCSS;
- mise à jour de `globals.css`;
- exécution séquentielle de commandes de setup.

## Prérequis

- `node` version 20 ou supérieure;
- `pnpm` (ou `corepack` disponible pour activer pnpm);
- `bash`.

## Structure

- `Makefile`: commandes principales d'orchestration.
- `scripts/run-sequential.sh`: exécute des commandes ligne par ligne depuis un fichier.
- `scripts/setup-next-tailwind.sh`: bootstrap Next.js + Tailwind v3.
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

Lit `setup.commands`, ignore les lignes vides/commentées (`#`), exécute chaque ligne dans un shell Bash et s'arrête au premier échec.

### 3. Créer/configurer un projet Next.js + Tailwind

```bash
make setup-next PROJECT_NAME=my-project
```

Lance `scripts/setup-next-tailwind.sh` pour:

- créer le projet s'il n'existe pas;
- installer les dépendances;
- configurer Tailwind v3 et PostCSS;
- injecter les directives `@tailwind` dans `globals.css`.

### 4. Même setup + démarrage du serveur dev

```bash
make setup-next-dev PROJECT_NAME=my-project
```

Fait le setup puis exécute `pnpm dev`.

## Utilisation directe du script principal

```bash
./scripts/setup-next-tailwind.sh my-project
./scripts/setup-next-tailwind.sh my-project --dev
```

Affichage de l'aide:

```bash
./scripts/setup-next-tailwind.sh --help
```

## Personnaliser `setup.commands`

Exemple:

```bash
# Une commande par ligne
./scripts/setup-next-tailwind.sh my-project
# ./scripts/setup-next-tailwind.sh my-project --dev
```

Puis:

```bash
make setup
```

## Comportement en cas d'erreur

- `run-sequential.sh` stoppe immédiatement si une commande échoue.
- `setup-next-tailwind.sh` stoppe si un prérequis manque (`node`, version, `pnpm`).

## Points d'attention

- Le script réécrit `tailwind.config.js` et `postcss.config.mjs`.
- Il supprime `postcss.config.js` s'il existe.
- En cas de relance sur un projet existant, vérifie les configurations personnalisées avant d'exécuter le script.
