# Schéma de la base de données – StudyMate

Base PostgreSQL hébergée sur **Supabase**, construite à partir de la maquette du projet (12 écrans).
Le script de création est dans [`server/database/schema.sql`](../server/database/schema.sql) (`npm run db:init`).

Types utilisés : les identifiants sont des `BIGINT` générés automatiquement, les dates des `TIMESTAMPTZ`
(date + heure + fuseau) et les oui/non des `BOOLEAN`. Le diagramme simplifie ces types (`int`, `text`).

## Diagramme

```mermaid
erDiagram
    DEPARTEMENTS ||--o{ UTILISATEURS : regroupe
    DEPARTEMENTS ||--o{ COURS : propose
    UTILISATEURS ||--o{ UTILISATEUR_ETIQUETTES : "intérêts / compétences"
    UTILISATEURS ||--o{ COURS_SUIVIS : suit
    COURS        ||--o{ COURS_SUIVIS : "est suivi"
    COURS        ||--o{ RESSOURCES : contient
    UTILISATEURS ||--o{ RESSOURCES : publie
    RESSOURCES   ||--o{ RESSOURCE_LIKES : reçoit
    RESSOURCES   ||--o{ RESSOURCE_COMMENTAIRES : reçoit
    COURS        |o--o{ DISCUSSIONS : concerne
    UTILISATEURS ||--o{ DISCUSSIONS : lance
    DISCUSSIONS  ||--o{ REPONSES : reçoit
    UTILISATEURS ||--o{ REPONSES : écrit
    DISCUSSIONS  ||--o{ DISCUSSION_LIKES : reçoit
    DISCUSSIONS  ||--o{ DISCUSSION_ABONNEMENTS : "est suivie"
    UTILISATEURS ||--o{ FAVORIS_RESSOURCES : enregistre
    RESSOURCES   ||--o{ FAVORIS_RESSOURCES : "est enregistrée"
    UTILISATEURS ||--o{ FAVORIS_DISCUSSIONS : enregistre
    DISCUSSIONS  ||--o{ FAVORIS_DISCUSSIONS : "est enregistrée"
    UTILISATEURS ||--o{ NOTIFICATIONS : reçoit

    DEPARTEMENTS {
        int id PK
        text nom UK
    }
    UTILISATEURS {
        int id PK
        text nom
        text prenom
        text nom_utilisateur UK
        text courriel UK
        text mot_de_passe "hash bcrypt, NULL si Google"
        text google_id UK
        text etablissement
        text niveau_etudes
        int departement_id FK
        text programme
        text specialite
        text annee
        text presentation
        text photo "chemin dans Storage"
        text photo_couverture
        text derniere_activite
        text date_inscription
    }
    UTILISATEUR_ETIQUETTES {
        int utilisateur_id PK, FK
        text type PK "interet ou competence"
        text libelle PK
    }
    COURS {
        int id PK
        text nom UK
        text description
        int departement_id FK
        text niveau
        text icone
    }
    COURS_SUIVIS {
        int utilisateur_id PK, FK
        int cours_id PK, FK
        text date_ajout
    }
    RESSOURCES {
        int id PK
        text titre
        text description
        text type "notes, exercices, resume, exemples, examen, lien"
        text fichier "chemin dans Storage"
        text format
        int taille
        text lien
        int cours_id FK
        int auteur_id FK
        int nb_telechargements
        text date_publication
    }
    RESSOURCE_LIKES {
        int utilisateur_id PK, FK
        int ressource_id PK, FK
    }
    RESSOURCE_COMMENTAIRES {
        int id PK
        text contenu
        int ressource_id FK
        int auteur_id FK
        text date_creation
    }
    DISCUSSIONS {
        int id PK
        text titre
        text contenu
        text categorie "question, groupe_etude, conseil, autre"
        int cours_id FK
        int auteur_id FK
        int resolue
        text date_creation
    }
    REPONSES {
        int id PK
        text contenu
        int discussion_id FK
        int auteur_id FK
        int acceptee
        text date_creation
    }
    DISCUSSION_LIKES {
        int utilisateur_id PK, FK
        int discussion_id PK, FK
    }
    DISCUSSION_ABONNEMENTS {
        int utilisateur_id PK, FK
        int discussion_id PK, FK
    }
    FAVORIS_RESSOURCES {
        int utilisateur_id PK, FK
        int ressource_id PK, FK
        text date_ajout
    }
    FAVORIS_DISCUSSIONS {
        int utilisateur_id PK, FK
        int discussion_id PK, FK
        text date_ajout
    }
    NOTIFICATIONS {
        int id PK
        int utilisateur_id FK
        text type
        text message
        text lien
        boolean lue
        text date_creation
    }
```

## Correspondance avec la maquette

| Écran | Tables utilisées |
|---|---|
| 1. Accueil (non connecté) | aucune (page statique), recherche sur `cours`, `ressources`, `discussions` |
| 2. Inscription | `utilisateurs`, `departements` |
| 3. Connexion | `utilisateurs` (courriel **ou** nom d'utilisateur, ou `google_id`) |
| 4. Tableau de bord | compteurs sur `cours_suivis`, `ressources`, `discussions`, `favoris_*` ; ressources et discussions récentes |
| 5. Liste des cours | `cours`, `departements` (+ nombre de ressources et de discussions par cours) |
| 6. Ressources d'un cours | `ressources`, `ressource_likes`, `ressource_commentaires` |
| 7. Entraide | `discussions` (onglets = `categorie`, « Mes cours » = filtre sur `cours_suivis`), `discussion_likes`, `reponses` |
| 8. Détail d'une discussion | `discussions`, `reponses`, `discussion_abonnements` (bouton « Suivre ») |
| 9. Rechercher des étudiants | `utilisateurs` (filtres département, programme, niveau), `utilisateur_etiquettes` |
| 10. Profil étudiant | `utilisateurs`, `utilisateur_etiquettes`, et ses `cours_suivis`, `ressources`, `discussions` |
| 11. Publier une ressource | `ressources`, `cours` |
| 12. Favoris | `favoris_ressources`, `favoris_discussions` |
| Menu : Notifications | `notifications` |

## Choix importants

- **Les compteurs ne sont pas stockés** (« 48 ressources », « 12 réponses », « 32 likes ») : ils sont calculés avec `COUNT(*)`, comme ça ils sont toujours justes. Seul `nb_telechargements` est stocké, car un téléchargement n'est pas une ligne d'une autre table.
- **Connexion Google** : un compte a soit un `mot_de_passe` (haché avec bcrypt), soit un `google_id`, et au moins l'un des deux est obligatoire.
- **« En ligne »** : on met `derniere_activite` à jour à chaque requête et on considère l'utilisateur en ligne si elle date de moins de 5 minutes.
- **Intérêts et compétences** : une seule table `utilisateur_etiquettes` avec une colonne `type`, au lieu de deux tables presque identiques.
- **Favoris** : deux tables séparées (ressources et discussions) pour garder de vraies clés étrangères.
- **Courriel et nom d'utilisateur uniques sans tenir compte des majuscules** : `Kader@uqac.ca` et `kader@uqac.ca` sont le même compte (index uniques sur `lower(...)`).
- **Fichiers** : les PDF et les photos ne sont pas dans la base mais dans **Supabase Storage** (buckets `ressources`, privé, et `photos`, public). La base garde seulement leur chemin.
- **Suppression d'un compte** : tout ce que l'utilisateur a créé est supprimé (`ON DELETE CASCADE`). Un département ne peut pas être supprimé tant qu'il contient des cours (`ON DELETE RESTRICT`).
- **Sécurité Supabase (RLS)** : Supabase rend les tables accessibles depuis Internet avec sa clé publique. Le schéma active la *Row Level Security* sur toutes les tables sans aucune règle, ce qui bloque cet accès : seul notre serveur Express, connecté directement à la base, peut lire et écrire.
- **Sessions** : la table `sessions` garde les connexions des utilisateurs (gérée automatiquement par `connect-pg-simple`).

## Évolutions possibles

- `etablissements` / `programmes` en tables si vous voulez des listes déroulantes contrôlées
- Messagerie privée entre étudiants (`conversations`, `participants`, `messages`)
- `signalements` pour la modération
- `parametres` utilisateur (notifications par courriel, confidentialité du profil)
