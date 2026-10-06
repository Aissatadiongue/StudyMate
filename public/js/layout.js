// =============================================================
// StudyMate – en-tête et menu latéral des pages connectées
// La page doit contenir <header id="entete"> et <nav id="menu-lateral">
// =============================================================

const LIENS_MENU = [
    { href: '/accueil.html', texte: 'Accueil' },
    { href: '/cours.html', texte: 'Mes cours' },
    { href: '/ressources.html', texte: 'Ressources' },
    { href: '/entraide.html', texte: 'Entraide' },
    { href: '/etudiants.html', texte: 'Étudiants' },
    { href: '/favoris.html', texte: 'Favoris' },
    { href: '/publier.html', texte: 'Publier' },
    { href: '/notifications.html', texte: 'Notifications' },
    { href: '/profil.html', texte: 'Profil' },
    { href: '/parametres.html', texte: 'Paramètres' }
];

function afficherMenu() {
    const menu = document.getElementById('menu-lateral');
    if (!menu) return; // page sans menu (pages publiques)

    // TODO : ajouter les icônes et le lien « Déconnexion » (POST /api/auth/deconnexion)
    menu.innerHTML = LIENS_MENU
        .map(lien => `<a href="${lien.href}"${location.pathname === lien.href ? ' class="actif"' : ''}>${lien.texte}</a>`)
        .join('');
}

function afficherEntete() {
    const entete = document.getElementById('entete');
    if (!entete) return;

    // TODO : logo, barre de recherche, photo et nom de l'utilisateur connecté (GET /api/auth/moi)
}

afficherMenu();
afficherEntete();
