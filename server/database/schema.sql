-- =============================================================
-- StudyMate - Schéma de la base de données (PostgreSQL / Supabase)
-- Basé sur la maquette du projet (12 écrans).
-- Voir docs/schema-bdd.md pour le diagramme et les explications.
--
-- Exécution : npm run db:init (ou coller ce fichier dans le SQL Editor de Supabase)
-- Le script peut être relancé sans risque : il ne recrée pas ce qui existe déjà.
-- =============================================================

-- -------------------------------------------------------------
-- Départements (filtres des écrans 5 et 9, inscription)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS departements (
    id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom TEXT   NOT NULL UNIQUE                      -- ex : "Informatique et mathématique"
);

-- -------------------------------------------------------------
-- Utilisateurs (écrans 2, 3, 9, 10)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS utilisateurs (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom               TEXT   NOT NULL,
    prenom            TEXT   NOT NULL,
    nom_utilisateur   TEXT   NOT NULL,              -- ex : "kaderdiop" (connexion possible avec)
    courriel          TEXT   NOT NULL,
    mot_de_passe      TEXT,                         -- hash bcrypt ; NULL si compte Google
    google_id         TEXT   UNIQUE,                -- "Continuer avec Google"
    etablissement     TEXT   NOT NULL,              -- ex : "UQAC"
    niveau_etudes     TEXT   NOT NULL,              -- ex : "Baccalauréat", "Maîtrise"
    departement_id    BIGINT REFERENCES departements(id) ON DELETE SET NULL,
    programme         TEXT,                         -- ex : "Informatique"
    specialite        TEXT,                         -- ex : "Science des données"
    annee             TEXT,                         -- ex : "2e année"
    presentation      TEXT,
    photo             TEXT,                         -- chemin dans le bucket Storage "photos"
    photo_couverture  TEXT,                         -- bannière du profil (bucket "photos")
    derniere_activite TIMESTAMPTZ,                  -- pour le badge "En ligne"
    date_inscription  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (mot_de_passe IS NOT NULL OR google_id IS NOT NULL)
);

-- Courriel et nom d'utilisateur uniques sans tenir compte des majuscules
-- (Kader@uqac.ca et kader@uqac.ca sont le même compte)
CREATE UNIQUE INDEX IF NOT EXISTS uq_utilisateurs_courriel        ON utilisateurs (lower(courriel));
CREATE UNIQUE INDEX IF NOT EXISTS uq_utilisateurs_nom_utilisateur ON utilisateurs (lower(nom_utilisateur));

-- Domaines d'intérêt et compétences du profil (étiquettes)
CREATE TABLE IF NOT EXISTS utilisateur_etiquettes (
    utilisateur_id BIGINT NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    type           TEXT   NOT NULL CHECK (type IN ('interet', 'competence')),
    libelle        TEXT   NOT NULL,                 -- ex : "IA", "Python"
    PRIMARY KEY (utilisateur_id, type, libelle)
);

-- -------------------------------------------------------------
-- Cours (écran 5) et "Mes cours" (tableau de bord)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cours (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom            TEXT   NOT NULL UNIQUE,          -- ex : "Programmation C++"
    description    TEXT,
    departement_id BIGINT NOT NULL REFERENCES departements(id) ON DELETE RESTRICT,
    niveau         TEXT,                            -- ex : "Baccalauréat"
    icone          TEXT                             -- nom de l'icône
);

CREATE TABLE IF NOT EXISTS cours_suivis (
    utilisateur_id BIGINT      NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    cours_id       BIGINT      NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    date_ajout     TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (utilisateur_id, cours_id)
);

-- -------------------------------------------------------------
-- Ressources (écrans 6 et 11)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ressources (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titre              TEXT   NOT NULL,
    description        TEXT   NOT NULL,
    type               TEXT   NOT NULL
                       CHECK (type IN ('notes', 'exercices', 'resume', 'exemples', 'examen', 'lien')),
    fichier            TEXT,                        -- chemin dans le bucket Storage "ressources"
    format             TEXT,                        -- ex : "PDF", "ZIP"
    taille             BIGINT,                      -- en octets (affiché "2.4 MB")
    lien               TEXT,                        -- URL si type = 'lien'
    cours_id           BIGINT NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    auteur_id          BIGINT NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    nb_telechargements INTEGER     NOT NULL DEFAULT 0,
    date_publication   TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (fichier IS NOT NULL OR lien IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS ressource_likes (
    utilisateur_id BIGINT NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    ressource_id   BIGINT NOT NULL REFERENCES ressources(id)   ON DELETE CASCADE,
    PRIMARY KEY (utilisateur_id, ressource_id)
);

CREATE TABLE IF NOT EXISTS ressource_commentaires (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contenu       TEXT        NOT NULL,
    ressource_id  BIGINT      NOT NULL REFERENCES ressources(id)   ON DELETE CASCADE,
    auteur_id     BIGINT      NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    date_creation TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- Entraide : discussions et réponses (écrans 7 et 8)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS discussions (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titre         TEXT    NOT NULL,
    contenu       TEXT    NOT NULL,
    categorie     TEXT    NOT NULL DEFAULT 'question'
                  CHECK (categorie IN ('question', 'groupe_etude', 'conseil', 'autre')),
    cours_id      BIGINT  REFERENCES cours(id)                 ON DELETE SET NULL,
    auteur_id     BIGINT  NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    resolue       BOOLEAN NOT NULL DEFAULT false,
    date_creation TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS reponses (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contenu       TEXT    NOT NULL,
    discussion_id BIGINT  NOT NULL REFERENCES discussions(id)  ON DELETE CASCADE,
    auteur_id     BIGINT  NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    acceptee      BOOLEAN NOT NULL DEFAULT false,
    date_creation TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS discussion_likes (
    utilisateur_id BIGINT NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    discussion_id  BIGINT NOT NULL REFERENCES discussions(id)  ON DELETE CASCADE,
    PRIMARY KEY (utilisateur_id, discussion_id)
);

-- Bouton "Suivre" : être notifié des nouvelles réponses
CREATE TABLE IF NOT EXISTS discussion_abonnements (
    utilisateur_id BIGINT NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    discussion_id  BIGINT NOT NULL REFERENCES discussions(id)  ON DELETE CASCADE,
    PRIMARY KEY (utilisateur_id, discussion_id)
);

-- -------------------------------------------------------------
-- Favoris (écran 12) : onglets "Ressources" et "Discussions"
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS favoris_ressources (
    utilisateur_id BIGINT      NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    ressource_id   BIGINT      NOT NULL REFERENCES ressources(id)   ON DELETE CASCADE,
    date_ajout     TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (utilisateur_id, ressource_id)
);

CREATE TABLE IF NOT EXISTS favoris_discussions (
    utilisateur_id BIGINT      NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    discussion_id  BIGINT      NOT NULL REFERENCES discussions(id)  ON DELETE CASCADE,
    date_ajout     TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (utilisateur_id, discussion_id)
);

-- -------------------------------------------------------------
-- Notifications (menu latéral)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    utilisateur_id BIGINT  NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    type           TEXT    NOT NULL
                   CHECK (type IN ('reponse', 'like', 'commentaire', 'nouvelle_ressource')),
    message        TEXT    NOT NULL,                -- ex : "Kader a répondu à votre discussion"
    lien           TEXT,                            -- page à ouvrir au clic
    lue            BOOLEAN NOT NULL DEFAULT false,
    date_creation  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- Sessions de connexion (utilisée par connect-pg-simple dans server.js)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sessions (
    sid    VARCHAR      NOT NULL PRIMARY KEY,
    sess   JSON         NOT NULL,
    expire TIMESTAMP(6) NOT NULL
);

-- -------------------------------------------------------------
-- Index pour accélérer les recherches et les listes fréquentes
-- -------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_utilisateurs_departement  ON utilisateurs (departement_id);
CREATE INDEX IF NOT EXISTS idx_cours_departement         ON cours (departement_id);
CREATE INDEX IF NOT EXISTS idx_ressources_cours          ON ressources (cours_id, date_publication DESC);
CREATE INDEX IF NOT EXISTS idx_ressources_auteur         ON ressources (auteur_id);
CREATE INDEX IF NOT EXISTS idx_commentaires_ressource    ON ressource_commentaires (ressource_id);
CREATE INDEX IF NOT EXISTS idx_discussions_cours         ON discussions (cours_id, date_creation DESC);
CREATE INDEX IF NOT EXISTS idx_discussions_auteur        ON discussions (auteur_id);
CREATE INDEX IF NOT EXISTS idx_reponses_discussion       ON reponses (discussion_id, date_creation);
CREATE INDEX IF NOT EXISTS idx_notifications_utilisateur ON notifications (utilisateur_id, lue);
CREATE INDEX IF NOT EXISTS idx_sessions_expire           ON sessions (expire);

-- -------------------------------------------------------------
-- Sécurité Supabase : Row Level Security
-- Supabase expose automatiquement les tables du schéma "public" sur une API
-- accessible avec la clé publique (anon). Activer RLS SANS aucune règle bloque
-- cet accès : seules les requêtes de notre serveur Express (connexion directe
-- avec le rôle propriétaire des tables) peuvent lire et écrire.
-- -------------------------------------------------------------
ALTER TABLE departements           ENABLE ROW LEVEL SECURITY;
ALTER TABLE utilisateurs           ENABLE ROW LEVEL SECURITY;
ALTER TABLE utilisateur_etiquettes ENABLE ROW LEVEL SECURITY;
ALTER TABLE cours                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE cours_suivis           ENABLE ROW LEVEL SECURITY;
ALTER TABLE ressources             ENABLE ROW LEVEL SECURITY;
ALTER TABLE ressource_likes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE ressource_commentaires ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussions            ENABLE ROW LEVEL SECURITY;
ALTER TABLE reponses               ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_likes       ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_abonnements ENABLE ROW LEVEL SECURITY;
ALTER TABLE favoris_ressources     ENABLE ROW LEVEL SECURITY;
ALTER TABLE favoris_discussions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications          ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions               ENABLE ROW LEVEL SECURITY;
