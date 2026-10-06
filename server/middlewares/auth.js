// =============================================================
// Bloque l'accès aux routes si l'utilisateur n'est pas connecté
// Utilisation : router.get('/', connexionRequise, (req, res) => ...)
// =============================================================

function connexionRequise(req, res, next) {
    if (!req.session.utilisateurId) {
        return res.status(401).json({ erreur: 'Vous devez être connecté' });
    }
    next();
}

module.exports = connexionRequise;
