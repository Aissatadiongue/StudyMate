-- =============================================================
-- StudyMate – données de départ
-- Exécuté par npm run db:init. Peut être relancé : les lignes déjà
-- présentes sont ignorées (ON CONFLICT DO NOTHING).
-- Les comptes utilisateurs se créent via la page d'inscription.
-- =============================================================

INSERT INTO departements (nom) VALUES
    ('Informatique et mathématique'),
    ('Sciences appliquées'),
    ('Sciences économiques et administratives')
ON CONFLICT (nom) DO NOTHING;

INSERT INTO cours (nom, description, departement_id, niveau, icone)
SELECT c.nom, c.description, d.id, 'Baccalauréat', c.icone
FROM (VALUES
    ('Programmation C++',            'Bases du langage C++ et programmation orientée objet', 'cpp'),
    ('Bases de données',             'Modélisation, SQL et jointures',                       'bdd'),
    ('Conception Web',               'HTML, CSS et JavaScript',                              'web'),
    ('Algèbre vectorielle',          'Vecteurs, matrices et espaces vectoriels',             'algebre'),
    ('Structure discrète',           'Logique, ensembles, graphes',                          'discret'),
    ('Architecture des ordinateurs', 'Fonctionnement interne d''un ordinateur',              'architecture'),
    ('Statistiques',                 'Probabilités et statistiques descriptives',            'stats'),
    ('Réseaux et sécurité',          'Protocoles réseau et sécurité informatique',           'reseaux')
) AS c (nom, description, icone)
JOIN departements d ON d.nom = 'Informatique et mathématique'
ON CONFLICT (nom) DO NOTHING;
