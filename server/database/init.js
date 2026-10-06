// =============================================================
// Crée les tables et ajoute les données de départ dans la base
// Lancement : npm run db:init (à refaire après chaque changement de schema.sql)
// =============================================================
require('dotenv').config();

const fs = require('fs');
const path = require('path');
const { pool } = require('../db');

async function initialiser() {
    for (const fichier of ['schema.sql', 'seed.sql']) {
        await pool.query(fs.readFileSync(path.join(__dirname, fichier), 'utf8'));
        console.log(`${fichier} exécuté`);
    }
    const { rows } = await pool.query('SELECT count(*)::int AS n FROM cours');
    console.log(`Base prête (${rows[0].n} cours)`);
}

initialiser()
    .catch(err => {
        console.error('Échec de l\'initialisation :', err.message);
        process.exitCode = 1;
    })
    .finally(() => pool.end());
