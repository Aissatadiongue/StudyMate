// =============================================================
// StudyMate – appels au serveur
// Toutes les pages passent par api() pour parler à /api/...
//
// Exemples :
//   const cours = await api('/cours');
//   await api('/auth/connexion', { method: 'POST', body: { courriel, motDePasse } });
// En cas d'erreur, api() lance une Error avec le message du serveur.
// =============================================================

// Pages accessibles sans être connecté : pas de redirection sur une erreur 401
const PAGES_PUBLIQUES = ['/', '/index.html', '/connexion.html', '/inscription.html', '/mot-de-passe-oublie.html'];

async function api(chemin, options = {}) {
    const estFormulaire = options.body instanceof FormData;

    const reponse = await fetch('/api' + chemin, {
        ...options,
        credentials: 'same-origin', // envoie le cookie de session
        headers: estFormulaire ? options.headers : { 'Content-Type': 'application/json', ...options.headers },
        body: estFormulaire || options.body === undefined ? options.body : JSON.stringify(options.body)
    });

    // Session expirée sur une page réservée aux connectés : retour à la connexion
    if (reponse.status === 401 && !PAGES_PUBLIQUES.includes(location.pathname)) {
        window.location.href = '/connexion.html';
        return;
    }

    const donnees = await reponse.json().catch(() => null);
    if (!reponse.ok) {
        throw new Error(donnees?.erreur || 'Une erreur est survenue');
    }
    return donnees;
}
