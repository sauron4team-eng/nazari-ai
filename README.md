# nazariai

A new Flutter project.

## Getting Started



# 🤝 Collaboration & Workflow Git

Afin de garantir un développement fluide et d'éviter les conflits, **chaque membre de l'équipe doit suivre ce workflow**.

---

## 📥 Initialisation du projet

### 1. Cloner le dépôt

```bash
git clone https://github.com/sauron4team-eng/nazari-ai.git
cd nazari-ai
```

---

### 2. Récupérer les dernières modifications

```bash
git checkout main
git pull origin main
git fetch --all
```

Lister les branches disponibles :

```bash
git branch -a
```

Vous devriez retrouver une structure similaire à :

```text
main
develop

feature/frontend
feature/backend
feature/ai
```

---

## 🌳 Structure des branches

Notre dépôt est organisé de la manière suivante :

```text
main
│
├── develop
│
├── feature/frontend
│   ├── task/login
│   ├── task/chat-ui
│   ├── task/dashboard
│   └── ...
│
├── feature/backend
│   ├── task/auth-api
│   ├── task/database
│   └── ...
│
└── feature/ai
    ├── task/gemma-integration
    ├── task/rag
    └── ...
```

### Description des branches

| Branche      | Rôle                                                                     |
| ------------ | ------------------------------------------------------------------------ |
| **main**     | Version stable du projet (démo / release). Aucun développement direct.   |
| **develop**  | Branche d'intégration des fonctionnalités validées.                      |
| **feature/** | Regroupe les tâches d'une grande fonctionnalité (Frontend, Backend, IA). |
| **task/**    | Branche dédiée à une seule tâche de développement.                       |

---

## 🚀 Workflow de développement

### Étape 1 — Choisir la Feature

Exemple :

```bash
git checkout feature/frontend
git pull origin feature/frontend
```

---

### Étape 2 — Créer une Task

Chaque nouvelle fonctionnalité commence par une branche `task`.

Exemple :

```bash
git checkout -b task/login
git push -u origin task/login
```

---

### Étape 3 — Développer

Travaillez normalement.

Effectuez des commits réguliers.

```bash
git add .
git commit -m "feat: création de l'écran de connexion"
git push
```

---

### Étape 4 — Terminer la tâche

Une fois la tâche terminée :

Créer une **Pull Request** :

```text
task/login
      ↓
feature/frontend
```

Après validation :

* Fusionner la Pull Request.
* Supprimer la branche `task`.

---

### Étape 5 — Intégration

Lorsque plusieurs tâches sont terminées :

```text
task/login
task/chat-ui
task/dashboard
            ↓
feature/frontend
```

Puis :

```text
feature/frontend
        ↓
develop
```

Enfin :

```text
develop
    ↓
main
```

Seul du code stable doit arriver dans `main`.

---

# ✅ Bonnes pratiques

Toujours :

* Faire un `git pull` avant de commencer une tâche.
* Créer une nouvelle branche `task` pour chaque développement.
* Faire des commits fréquents.
* Faire des `push` réguliers.
* Tester le code avant d'ouvrir une Pull Request.
* Communiquer avec l'équipe avant de commencer une tâche importante.

---

# ❌ À éviter

Ne jamais développer directement sur :

* `main`
* `develop`
* `feature/frontend`
* `feature/backend`
* `feature/ai`

Ces branches servent uniquement à intégrer le travail des différentes tâches.

Ne jamais mélanger plusieurs fonctionnalités dans une seule branche `task`.

❌ Mauvais :

```text
task/login-chat-profile
```

✅ Correct :

```text
task/login
task/chat-ui
task/profile
```

---

# 📝 Convention des commits

Nous utilisons les **Conventional Commits**.

Exemples :

```text
feat: ajout de l'écran de connexion
feat: création du tableau de bord
fix: correction de la navigation
refactor: nettoyage du service d'authentification
docs: mise à jour du README
style: amélioration de l'interface
test: ajout des tests
```

---

# 🎯 Philosophie de l'équipe

> **Une Task = Un objectif.**

Notre priorité est de produire un code propre, facile à relire et simple à intégrer.

Nous privilégions :

* Des tâches courtes.
* Des commits réguliers.
* Des Pull Requests fréquentes.
* Une branche `main` toujours stable et prête pour une démonstration.

Avant de créer une nouvelle branche `task`, vérifiez qu'aucun autre membre de l'équipe ne travaille déjà sur la même fonctionnalité.

**Développons vite, intégrons proprement et gardons toujours une version prête pour le hackathon. 🚀**


A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
