# StudyMate

Plateforme d'entraide académique pour les étudiants : partager des ressources de cours, poser des questions (avec l'aide d'un assistant IA), trouver des étudiants qui suivent les mêmes cours.

**Équipe** : Kader Diop et Aissata Diongue

## Technologies

- **Front** : HTML + [Tailwind CSS](https://tailwindcss.com) v4 + JavaScript, dans `public/`
- **Back** : [Node.js](https://nodejs.org) + [Express](https://expressjs.com) 5, dans `server/`
- **Base de données** : PostgreSQL sur [Supabase](https://supabase.com), voir [docs/schema-bdd.md](docs/schema-bdd.md)
- **Fichiers** (PDF, photos) : Supabase Storage

## Installation (une seule fois)

Prérequis : Node.js 20 ou plus récent.

### 1. Supabase

1. Créer un projet sur https://supabase.com (un seul projet pour toute l'équipe).
2. **Storage → New bucket** : créer `ressources` (privé) et `photos` (public).

### 2. Le projet

```bash
npm install
cp .env.example .env
```

Remplir `.env` :

| Variable | Où la trouver dans Supabase |
|---|---|
| `DATABASE_URL` | bouton **Connect** → **Session pooler** → URI (remplacer `[YOUR-PASSWORD]`) |
| `SUPABASE_URL` | **Project Settings → API** → Project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | **Project Settings → API** → clé `service_role` (secrète !) |
| `SESSION_SECRET` | à générer : `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"` |

Puis créer les tables et les données de départ :

```bash
npm run db:init
```

## Lancer le projet

```bash
npm run dev
```

Ouvrir http://localhost:3000. Le serveur redémarre et le CSS se recompile automatiquement à chaque modification.

| Commande | Rôle |
|---|---|
| `npm run dev` | développement : serveur + Tailwind en mode surveillance |
| `npm run db:init` | crée les tables et ajoute les données de départ (à relancer après un changement de `schema.sql`) |
| `npm run build` | génère le CSS final (pour la mise en ligne) |
| `npm start` | lance le serveur (mise en ligne) |

## Organisation

```
public/                  front : ce que voit le navigateur
├── *.html               une page par écran de la maquette
├── css/style.css        généré par Tailwind (ne pas modifier, ignoré par Git)
├── js/                  api.js (appels au serveur), layout.js (menu), un fichier par page
└── img/
styles/app.css           source Tailwind : couleurs de la maquette + composants (.btn, .carte…)
server/                  back
├── server.js            point d'entrée
├── db.js                connexion PostgreSQL (Supabase)
├── supabase.js          envoi et téléchargement de fichiers (Supabase Storage)
├── database/            schema.sql, seed.sql, init.js
├── middlewares/         auth.js (connexion requise), upload.js (fichiers)
└── routes/              une route par fonctionnalité (/api/...)
docs/                    documentation (schéma de la base, plan de travail)
```

## Ajouter une fonctionnalité

1. Créer une branche : `git checkout -b feature/nom-de-la-fonctionnalite`
2. Coder la route dans `server/routes/` (elle doit exporter un `express.Router()`).
3. Dans `server/server.js`, décommenter la ligne `app.use('/api/...', require('./routes/...'))` correspondante.
4. Coder la page dans `public/` et son JavaScript dans `public/js/`.
5. Ouvrir une pull request sur GitHub : l'autre membre relit avant la fusion dans `main`.

## Sécurité

- Ne jamais publier `.env` (déjà dans `.gitignore`) ni la clé `service_role`.
- Requêtes SQL toujours avec des paramètres : `db.query('... WHERE id = $1', [id])`.
- Mots de passe hachés avec `bcryptjs`, jamais stockés en clair.

## Travailler à deux

- Une branche par fonctionnalité, fusionnée par pull request après relecture.
- Faire `git pull` avant de commencer à travailler.
- Vous partagez la même base Supabase : prévenir l'autre avant de modifier `schema.sql`.
