// =============================================================
// Connexion à la base PostgreSQL (Supabase)
// Utilisation dans une route :
//   const db = require('../db');
//   const { rows } = await db.query('SELECT * FROM cours WHERE id = $1', [id]);
// Toujours passer les valeurs en paramètres ($1, $2…), jamais en les
// collant dans le texte SQL : c'est ce qui protège des injections SQL.
// =============================================================
const { Pool } = require('pg');

if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL manquant : copiez .env.example en .env et remplissez-le (voir README)');
}

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    // Supabase exige une connexion chiffrée. DATABASE_SSL=false seulement
    // pour une base PostgreSQL locale.
    ssl: process.env.DATABASE_SSL === 'false' ? false : { rejectUnauthorized: false }
});

module.exports = {
    query: (texte, valeurs) => pool.query(texte, valeurs),
    pool
};
