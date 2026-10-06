// =============================================================
// StudyMate – point d'entrée du serveur
// Lancement : npm run dev (développement) ou npm start
// =============================================================
require('dotenv').config();

const path = require('path');
const express = require('express');
const session = require('express-session');
const PgSession = require('connect-pg-simple')(session);
const { pool } = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;
const SEMAINE = 7 * 24 * 60 * 60 * 1000;
const enProduction = process.env.NODE_ENV === 'production';

// En ligne, on refuse de démarrer sans vraie clé secrète pour les sessions
if (enProduction && !process.env.SESSION_SECRET) {
    throw new Error('SESSION_SECRET manquant dans les variables d\'environnement');
}

// En ligne, le site est derrière le proxy HTTPS de l'hébergeur
if (enProduction) {
    app.set('trust proxy', 1);
}

// Lecture du JSON envoyé par les pages (fetch)
app.use(express.json());

// Sessions : un cookie identifie l'utilisateur connecté
// (« Se souvenir de moi » = allonger req.session.cookie.maxAge à la connexion)
// Les sessions sont enregistrées dans la table "sessions" de la base :
// on reste connecté même après un redémarrage du serveur.
app.use(session({
    store: new PgSession({ pool, tableName: 'sessions' }),
    secret: process.env.SESSION_SECRET || 'secret-de-developpement',
    resave: false,
    saveUninitialized: false,
    cookie: {
        httpOnly: true,         // le JavaScript de la page ne peut pas lire le cookie
        sameSite: 'lax',        // protège contre les requêtes venant d'autres sites
        secure: enProduction,   // en ligne : cookie envoyé seulement en HTTPS
        maxAge: SEMAINE
    }
}));

// Pages, CSS, JS et images du site
app.use(express.static(path.join(__dirname, '..', 'public')));

// API
app.get('/api/sante', (req, res) => res.json({ statut: 'ok' }));

// Routes des fonctionnalités : décommentez chaque ligne quand le fichier
// de la route correspondante est codé (un fichier vide ferait planter le serveur)
// app.use('/api/auth', require('./routes/auth'));
// app.use('/api/utilisateurs', require('./routes/utilisateurs'));
// app.use('/api/cours', require('./routes/cours'));
// app.use('/api/ressources', require('./routes/ressources'));
// app.use('/api/discussions', require('./routes/discussions'));
// app.use('/api/favoris', require('./routes/favoris'));
// app.use('/api/notifications', require('./routes/notifications'));
// app.use('/api/tableau-de-bord', require('./routes/tableau-de-bord'));

// Route d'API inconnue
app.use('/api', (req, res) => res.status(404).json({ erreur: 'Route introuvable' }));

// Page inconnue
app.use((req, res) => res.status(404).sendFile(path.join(__dirname, '..', 'public', '404.html')));

// Erreurs (ex. fichier trop gros ou mauvais format refusé par multer)
app.use((err, req, res, next) => {
    console.error(err);
    res.status(err.status || 400).json({ erreur: err.message || 'Erreur serveur' });
});

// Vérifie la connexion à la base avant d'accepter des visiteurs
pool.query('SELECT 1')
    .then(() => {
        app.listen(PORT, () => {
            console.log(`StudyMate démarré sur http://localhost:${PORT}`);
        });
    })
    .catch(err => {
        console.error('Impossible de se connecter à la base de données :', err.message);
        console.error('Vérifiez DATABASE_URL dans .env (voir README)');
        process.exit(1);
    });
