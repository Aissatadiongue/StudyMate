// =============================================================
// Réception des fichiers envoyés par les formulaires (multer)
// Les fichiers restent en mémoire puis sont envoyés vers Supabase Storage
// avec televerser() de server/supabase.js.
//
// Exemple dans une route :
//   router.post('/', uploadRessource.single('fichier'), async (req, res) => {
//       const chemin = await televerser('ressources', req.file);
//       ...
//   });
// =============================================================
const path = require('path');
const multer = require('multer');

function creerUpload(extensionsAutorisees, tailleMaxMo) {
    return multer({
        storage: multer.memoryStorage(),
        limits: { fileSize: tailleMaxMo * 1024 * 1024 },
        fileFilter: (req, fichier, cb) => {
            const extension = path.extname(fichier.originalname).toLowerCase();
            if (extensionsAutorisees.includes(extension)) {
                cb(null, true);
            } else {
                cb(new Error('Format de fichier non autorisé'));
            }
        }
    });
}

module.exports = {
    // Ressources : 10 Mo maximum
    uploadRessource: creerUpload(['.pdf', '.zip', '.doc', '.docx', '.ppt', '.pptx', '.txt'], 10),
    // Photos de profil et de couverture : 2 Mo maximum
    uploadPhoto: creerUpload(['.jpg', '.jpeg', '.png', '.webp'], 2)
};
