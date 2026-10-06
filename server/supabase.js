// =============================================================
// Stockage des fichiers dans Supabase Storage
// Buckets à créer dans Supabase (Storage → New bucket) :
//   - "ressources" : privé (téléchargement via un lien temporaire)
//   - "photos"     : public (photos de profil et de couverture)
// =============================================================
const path = require('path');
const crypto = require('crypto');
const { createClient } = require('@supabase/supabase-js');

let client;

// Le client est créé au premier usage : le serveur peut démarrer
// même si les clés Supabase ne sont pas encore renseignées.
function supabase() {
    if (!client) {
        if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
            throw new Error('SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY manquant dans .env');
        }
        // Clé "service_role" : elle a tous les droits, elle ne doit JAMAIS
        // être envoyée au navigateur ni publiée sur GitHub.
        client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
            auth: { persistSession: false }
        });
    }
    return client;
}

// Envoie un fichier reçu par multer et renvoie son chemin dans le bucket
async function televerser(bucket, fichier) {
    const chemin = crypto.randomUUID() + path.extname(fichier.originalname).toLowerCase();
    const { error } = await supabase().storage
        .from(bucket)
        .upload(chemin, fichier.buffer, { contentType: fichier.mimetype });
    if (error) throw error;
    return chemin;
}

// Lien de téléchargement valable 60 secondes (bucket privé "ressources")
async function lienTemporaire(bucket, chemin) {
    const { data, error } = await supabase().storage.from(bucket).createSignedUrl(chemin, 60);
    if (error) throw error;
    return data.signedUrl;
}

// Adresse publique d'une photo (bucket public "photos")
function urlPublique(bucket, chemin) {
    return supabase().storage.from(bucket).getPublicUrl(chemin).data.publicUrl;
}

async function supprimer(bucket, chemin) {
    const { error } = await supabase().storage.from(bucket).remove([chemin]);
    if (error) throw error;
}

module.exports = { televerser, lienTemporaire, urlPublique, supprimer };
