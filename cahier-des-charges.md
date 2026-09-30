# Cahier des charges — FocusLite (nom provisoire)

> Application iOS personnelle qui combine le principe de **SocialLite** (Instagram sans Reels via une WebView filtrée) et celui d'**Opal** (blocage d'apps via l'API Screen Time).
> Ce document sert de brief de démarrage pour Claude Code. Le périmètre visé ici est le **MVP (V0)**.

---

## 1. Contexte et objectif

L'utilisateur perd la majorité de son temps d'écran dans les **Reels Instagram** et sur **TikTok**. Il veut garder l'usage utile d'Instagram (DMs, profils, posts, stories) tout en supprimant le format court.

iOS interdit à une app de modifier une autre app. La stratégie est donc :

1. **Bloquer l'app Instagram native** avec l'API Screen Time.
2. **Proposer à la place un Instagram web filtré**, dans une `WKWebView` avec injection de JS/CSS qui masque et bloque les Reels et l'Explore.
3. **Bloquer TikTok entièrement**, sans alternative.
4. **Offrir un "Mode Poster"** qui déverrouille temporairement l'app Instagram native pour publier, puis la rebloque automatiquement.

**Usage :** personnel, un seul utilisateur, installé sur l'iPhone du développeur. Une publication App Store est possible plus tard mais n'est pas un objectif du MVP.

---

## 2. Périmètre

### Inclus dans le MVP (V0)

- Autorisation Screen Time en mode individuel.
- Sélection des apps à bloquer, en deux groupes :
  - **Groupe "Redirection"** (Instagram) : bloqué, l'écran de blocage propose d'ouvrir la version filtrée dans FocusLite.
  - **Groupe "Blocage total"** (TikTok) : bloqué, sans échappatoire. *(Appelé "Blocage dur" jusqu'au 30/09/2026.)*
- Écran de blocage personnalisé (shield).
- Navigateur Instagram filtré (WebView + script injecté).
- Navigateur YouTube sans Shorts, même principe. *(Décision du 30/09/2026 : avancé depuis la V2, voir F4.)*
- Mode Poster : déverrouillage temporaire d'Instagram natif puis rebloquage automatique.
- Deep link vers une page précise de la WebView (ex. l'inbox des DMs).

### Hors périmètre V0 (voir roadmap §9)

- Plages horaires et planification.
- Statistiques d'usage (`DeviceActivityReport`).
- Friction avancée pour débloquer (délai, phrase à taper, quotas).
- Blocage d'instagram.com / tiktok.com dans Safari.
- YouTube Shorts.
- Compteur de DMs non lus.

(YouTube Shorts est sorti de cette liste le 30/09/2026 : voir F4, section YouTube.)

---

## 3. Contraintes techniques

- **Langage / UI :** Swift, SwiftUI.
- **iOS minimum :** 26.0, pour utiliser Liquid Glass sans code de repli. *(Décision du 30/09/2026, remplace 17.0.)*
- **Frameworks Apple :** `FamilyControls`, `ManagedSettings`, `ManagedSettingsUI`, `DeviceActivity`, `WebKit`, `UserNotifications`.
- **Entitlement :** `com.apple.developer.family-controls` sur **l'app principale et chaque extension**.
  - En développement : il suffit d'ajouter la capability "Family Controls" dans Xcode.
  - En distribution (TestFlight / App Store) : demande à faire auprès d'Apple **pour chaque bundle ID**. Pas bloquant pour le MVP.
- **Test :** les API Screen Time ne fonctionnent pas de manière fiable dans le simulateur. **Tout test de blocage se fait sur un iPhone physique.** La WebView peut être testée dans le simulateur.
- **Pas de backend, pas de compte, aucune donnée envoyée à l'extérieur.** Tout reste en local.
- **Robustesse du filtrage :** Instagram web est une SPA React avec des classes CSS obfusquées qui changent souvent. Il faut **cibler les attributs `href` et les URLs, jamais les classes CSS**, et éviter de dépendre de la langue de l'interface.

---

## 4. Architecture Xcode

### Targets

| Target | Type | Rôle |
|---|---|---|
| `FocusLite` | App iOS (SwiftUI) | Réglages, autorisation, sélection des apps, WebView Instagram, Mode Poster |
| `ShieldConfigurationExtension` | Shield Configuration Extension | Apparence de l'écran de blocage selon le groupe de l'app |
| `ShieldActionExtension` | Shield Action Extension | Réaction aux boutons de l'écran de blocage |
| `DeviceActivityMonitorExtension` | Device Activity Monitor Extension | Rebloque Instagram à la fin du Mode Poster |

### Bundle IDs (à adapter)

- `com.<team>.focuslite`
- `com.<team>.focuslite.shieldconfig`
- `com.<team>.focuslite.shieldaction`
- `com.<team>.focuslite.monitor`

### App Group

`group.com.<team>.focuslite`. Il est partagé par les 4 targets pour échanger l'état : sélections d'apps, état du Mode Poster, etc.

### Structure de code suggérée

```
FocusLite/
├── App/
│   ├── FocusLiteApp.swift
│   └── RootView.swift
├── Shared/                      # Membre des 4 targets
│   ├── AppGroup.swift           # suiteName, clés UserDefaults
│   ├── SelectionStore.swift     # lecture/écriture des FamilyActivitySelection
│   ├── BlockingManager.swift    # applique / retire les shields
│   └── ActivityNames.swift      # DeviceActivityName, ManagedSettingsStore.Name
├── Features/
│   ├── Onboarding/              # autorisation Screen Time + notifications
│   ├── Settings/                # choix des apps (2 pickers)
│   ├── Browser/
│   │   ├── InstagramWebView.swift
│   │   ├── WebViewCoordinator.swift
│   │   └── URLPolicy.swift      # règles autorisé / bloqué
│   └── PostMode/
├── Resources/
│   └── instagram-filter.js      # script injecté (généré depuis /web)
web/                             # sources TypeScript du script injecté
├── src/instagram-filter.ts
├── package.json
└── tsconfig.json
ShieldConfigurationExtension/
ShieldActionExtension/
DeviceActivityMonitorExtension/
```

---

## 5. Fonctionnalités détaillées

### F1 — Onboarding et autorisations

- Au premier lancement, afficher un écran expliquant le fonctionnement.
- Demander l'autorisation Screen Time avec `AuthorizationCenter.shared.requestAuthorization(for: .individual)`.
- Demander l'autorisation des notifications locales (nécessaire pour F3).
- Afficher l'état des autorisations et permettre de relancer la demande si elle a été refusée.

**Critères d'acceptation**

- Après acceptation, `AuthorizationCenter.shared.authorizationStatus == .approved`.
- Si l'utilisateur refuse, l'app l'indique clairement et ne plante pas.

### F2 — Sélection et blocage des apps

- Deux `FamilyActivityPicker` distincts :
  - **Redirection** : l'utilisateur y met Instagram.
  - **Blocage total** : l'utilisateur y met TikTok (et autres).
- Les deux `FamilyActivitySelection` sont sérialisées (Codable → JSON) dans les `UserDefaults` de l'App Group.
- `BlockingManager` applique les shields via un `ManagedSettingsStore` nommé :
  - `shield.applications` = union des `applicationTokens` des deux groupes ;
  - `shield.applicationCategories` = catégories sélectionnées, s'il y en a.
- Un toggle global "Blocage actif" permet d'activer ou désactiver l'ensemble.
- Au lancement de l'app et au retour au premier plan, re-appliquer l'état attendu (filet de sécurité).

**Critères d'acceptation**

- Ouvrir Instagram ou TikTok affiche l'écran de blocage.
- Le blocage persiste après fermeture de l'app et redémarrage de l'iPhone.
- Désactiver le toggle retire tous les shields.

> Note : les `ApplicationToken` sont opaques, l'app principale ne connaît pas le nom des apps sélectionnées. C'est pour ça qu'on utilise **deux sélections séparées** : l'appartenance d'un token à un groupe détermine son comportement.

### F3 — Écran de blocage personnalisé

**ShieldConfigurationExtension**

- Charger les sélections depuis l'App Group et déterminer le groupe du token de l'app bloquée.
- **Groupe Redirection :**
  - titre : "Instagram est en pause" ;
  - sous-titre : "Tes messages, posts et stories t'attendent dans FocusLite, sans les Reels." ;
  - bouton principal : "Ouvrir FocusLite" ;
  - bouton secondaire : "Fermer".
- **Groupe Blocage total :**
  - titre : "App bloquée" ;
  - sous-titre court et dissuasif ;
  - un seul bouton : "Fermer".
- Style sobre et cohérent avec l'app (couleurs, icône).

**ShieldActionExtension**

- Une extension Shield Action **ne peut pas ouvrir une app directement**.
- Bouton "Ouvrir FocusLite" (groupe Redirection) :
  - planifier une notification locale immédiate ("Touche pour ouvrir tes messages Instagram, sans les Reels.") ;
  - mettre dans `userInfo` un deep link, par défaut `focuslite://open?path=/direct/inbox/` ;
  - répondre `.close`.
- Bouton "Fermer" : `.close`.

**Critères d'acceptation**

- Le bon écran s'affiche selon le groupe.
- Toucher "Ouvrir FocusLite" produit une notification. La toucher ouvre FocusLite sur l'inbox des DMs.

### F4 — Navigateur Instagram filtré

**WebView**

- `WKWebView` avec `WKWebsiteDataStore.default()`, pour que la session reste connectée entre les lancements.
- User-Agent : Safari mobile iOS récent, pour obtenir la version mobile d'instagram.com.
- Page d'accueil : `https://www.instagram.com/`.
- Écran d'accueil FocusLite au lancement : liste des services (Instagram, YouTube) et accès aux réglages. Un deep link (F6) ouvre directement le service, sans passer par cet écran. *(Décision du 30/09/2026.)*
- Barre native fine **en haut** de la WebView, réservée aux actions FocusLite : bouton "Accueil" (retour à la liste des services) et bouton "Mode Poster" (F5). Pas de barre native en bas : la navigation dans Instagram passe par la barre du site. Retour = glissement depuis le bord gauche, recharger = pull-to-refresh. *(Décision du 30/09/2026, remplace la barre accueil / messages / retour / recharger.)*
- Le lien `/explore/` (bouton de recherche d'Instagram) ouvre `/explore/search/` au lieu de la grille Explorer.
- Les liens vers des domaines externes s'ouvrent dans Safari (`SFSafariViewController` ou `UIApplication.open`).

**Règles d'URL (`URLPolicy.swift`)**

| Chemin | Règle |
|---|---|
| `/reels/` et sous-chemins (feed des Reels) | **Bloqué** |
| `/explore/` et sous-chemins | **Bloqué** |
| `/explore/search/` et sous-chemins (recherche de comptes) | **Autorisé** (décision du 30/09/2026, exception à la ligne précédente) |
| `/reel/<id>/` (reel unique, typiquement reçu en DM) | **Autorisé**, via un réglage `allowSingleReels` (défaut : `true`) |
| `/direct/…`, `/stories/…`, `/p/…`, profils, `/accounts/…` | Autorisé |
| Tout le reste sur instagram.com | Autorisé par défaut |

Quand une navigation est bloquée : l'annuler, afficher un toast "Reels bloqués", puis rester sur la page courante ou rediriger vers l'accueil.

> ⚠️ À vérifier : confirmer les chemins exacts en inspectant instagram.com en mode mobile avant d'implémenter (feed Reels vs reel unique).

**Interception de la navigation**

1. **Natif** : `WKNavigationDelegate.decidePolicyFor(navigationAction:)` applique `URLPolicy` aux chargements de pages complets.
2. **JS** : instagram.com navigue via `history.pushState` / `replaceState`, invisibles côté natif. Le script injecté doit :
   - patcher `history.pushState` et `history.replaceState` et écouter `popstate` ;
   - à chaque changement d'URL, envoyer `{ type: "navigation", url }` au natif via `window.webkit.messageHandlers.focuslite.postMessage(...)` ;
   - bloquer côté JS aussi : si le chemin est interdit, revenir en arrière ou rediriger vers `/` avant affichage.
3. Le natif reçoit les messages via `WKScriptMessageHandler` (nom : `focuslite`), applique `URLPolicy` et affiche le toast si besoin.

**Script injecté (`instagram-filter.js`)**

Source en TypeScript dans `/web`, compilée en un seul fichier JS copié dans les ressources de l'app. Il est injecté via `WKUserScript` avec `injectionTime: .atDocumentStart`.

Le script doit :
- injecter une feuille de style qui masque :
  - `a[href="/reels/"]` et `a[href^="/reels/"]` (onglet Reels) ;
  - `a[href="/explore/"]` et `a[href^="/explore/"]` ;
- utiliser un `MutationObserver` sur `document.documentElement` pour ré-appliquer le masquage quand le DOM change. Il doit être léger : throttle / `requestAnimationFrame`, pas de travail lourd à chaque mutation ;
- patcher l'historique (voir ci-dessus) ;
- être **idempotent**, sans double injection si le script est chargé plusieurs fois ;
- ne jamais dépendre de classes CSS obfusquées ni du texte de l'interface ;
- exposer un objet de config lu au démarrage (ex. `allowSingleReels`), injecté par le natif.

**Critères d'acceptation**

- L'onglet Reels et l'Explore ne sont ni visibles ni atteignables, y compris via la navigation interne de l'app web.
- DMs, profils, posts et stories fonctionnent.
- Un reel reçu en DM s'ouvre si `allowSingleReels == true`, mais ne permet pas de basculer vers le feed Reels.
- La session reste connectée après un redémarrage de l'app.
- Le script peut être testé dans Safari desktop (mode responsive iPhone) en le collant dans la console, avant toute intégration native.

**YouTube sans Shorts** *(décision du 30/09/2026)*

- Deuxième service de l'écran d'accueil, même principe que le navigateur Instagram : WebView sur `https://m.youtube.com/`, session persistante, User-Agent Safari iOS, script `youtube-filter.js` généré depuis `/web`.
- Règle d'URL : tout chemin contenant le segment exact `shorts` est **bloqué**, soit `/shorts/<id>` (le lecteur, qui fait défiler les Shorts suivants) et l'onglet Shorts d'une chaîne (`/@nom/shorts`). Un handle comme `/@nom.shorts` reste autorisé. Toast : "Shorts bloqués".
- Domaines gardés dans la WebView : `youtube.com` et ses sous-domaines, `youtu.be` et `google.com` (connexion via `accounts.google.com`, consentement cookies). Le reste s'ouvre dans Safari.
- Masquage : les liens `/shorts/…` et les conteneurs de Shorts, par leurs noms d'éléments (`ytm-reel-shelf-renderer`, `ytm-shorts-lockup-view-model`…). Ce sont des noms de composants, pas des classes obfusquées.
- Pas de Mode Poster pour YouTube. L'app YouTube native n'a pas de traitement dédié : pour la bloquer, la mettre dans "Blocage total" (le bouton du groupe Redirection ouvre Instagram).

> ⚠️ À vérifier sur iPhone : (1) Google peut refuser la connexion dans une WebView ("navigateur non sécurisé") ; YouTube reste alors utilisable sans compte. (2) Les noms d'éléments des étagères de Shorts sont déduits des noms de renderers de `ytInitialData`, pas observés dans le DOM.

### F5 — Mode Poster

Objectif : publier une story ou un post depuis l'app native, qui offre plus de fonctions que la version web.

- Bouton "Mode Poster" dans la WebView et dans les réglages.
- Au déclenchement :
  1. retirer du shield les tokens du groupe Redirection (TikTok reste bloqué) ;
  2. enregistrer dans l'App Group `postModeEndsAt = now + 15 min` ;
  3. démarrer un monitoring `DeviceActivityCenter().startMonitoring(.postMode, during: schedule)` de maintenant à `postModeEndsAt`, `repeats: false`.
- **DeviceActivityMonitorExtension**
  - `intervalDidEnd(for: .postMode)` → ré-appliquer tous les shields, effacer `postModeEndsAt`.
- **Filet de sécurité** : à chaque ouverture de FocusLite, si `postModeEndsAt` est dépassé, ré-appliquer les shields.
- Afficher un compte à rebours dans l'app pendant le Mode Poster.

> Contrainte : `DeviceActivitySchedule` impose un **intervalle minimum de 15 minutes**. Le Mode Poster dure donc 15 min en V0. Gérer le cas d'un intervalle qui chevauche minuit (construire les `DateComponents` avec la date complète).

**Critères d'acceptation**

- Pendant le Mode Poster, Instagram natif s'ouvre normalement et TikTok reste bloqué.
- Après 15 min, Instagram natif est de nouveau bloqué, même si FocusLite n'a pas été rouverte.

### F6 — Deep links

- URL scheme : `focuslite://`.
- `focuslite://open?path=<chemin>` ouvre la WebView sur `https://www.instagram.com<chemin>`, avec validation par `URLPolicy`.
- Toucher une notification planifiée par F3 déclenche ce deep link (`UNUserNotificationCenterDelegate`).

---

## 6. Données partagées (App Group)

| Clé | Type | Écrit par | Lu par |
|---|---|---|---|
| `selection.redirect` | `FamilyActivitySelection` (JSON) | App | App, ShieldConfig, ShieldAction, Monitor |
| `selection.hardBlock` | `FamilyActivitySelection` (JSON) | App | App, ShieldConfig, ShieldAction, Monitor |
| `blocking.enabled` | `Bool` | App | Tous |
| `postMode.endsAt` | `Date?` | App, Monitor | App, Monitor |
| `browser.allowSingleReels` | `Bool` | App | App |

---

## 7. Plan de développement (ordre imposé)

Chaque étape doit compiler et être testable avant de passer à la suivante. Un commit par étape.

1. **Squelette** : projet Xcode, 4 targets, App Group, capability Family Controls partout, `Shared/` membre des 4 targets.
2. **F1** : onboarding et autorisations.
3. **F2** : pickers, persistance, `BlockingManager`. *Test sur iPhone : Instagram et TikTok bloqués.*
4. **F4 (partie JS)** : script TypeScript + build vers `Resources/instagram-filter.js`. *Test dans Safari desktop.*
5. **F4 (partie native)** : WebView, `URLPolicy`, bridge JS ↔ natif.
6. **F6** : deep links.
7. **F3** : shields personnalisés et notification de redirection. *Test sur iPhone du parcours complet.*
8. **F5** : Mode Poster et extension Monitor. *Test sur iPhone : rebloquage après 15 min, app fermée.*

---

## 8. Consignes pour Claude Code

- **Ne pas inventer d'API.** En cas de doute sur une signature Apple (FamilyControls, ManagedSettings, DeviceActivity), le signaler plutôt que deviner.
- Les points marqués **⚠️ À vérifier** doivent être confirmés avant implémentation.
- Rappeler à l'utilisateur quand une étape nécessite un test sur iPhone physique.
- Garder les extensions minimalistes : elles ont des limites mémoire strictes.
- Pas de dépendances tierces côté Swift pour le MVP. Côté `/web`, TypeScript + un bundler léger (esbuild) suffisent.
- Code et commentaires en anglais, textes de l'interface en français.

---

## 9. Roadmap après le MVP

**V1 — couche Opal**
- Friction pour débloquer : attente de 30 s, phrase à taper, nombre de déblocages limité par jour.
- Plages horaires (ex. aucun accès à Instagram avant midi).
- Statistiques via une extension `DeviceActivityReport`.
- Masquer les vidéos courtes et les "Suggestions pour vous" dans le feed d'accueil web.

**V2 — échappatoires et extension**
- Bloquer instagram.com et tiktok.com dans Safari (`ManagedSettings` web domains). ⚠️ À vérifier : que ça n'affecte pas la WebView de FocusLite.
- ~~YouTube sans Shorts (même principe de wrapper).~~ Fait le 30/09/2026, voir F4.
- Compteur de DMs non lus lu depuis la WebView.
- Préparation App Store : demande d'entitlement de distribution pour les 4 bundle IDs, page de confidentialité, icône.

---

## 10. Limites connues (acceptées)

- En mode `.individual`, l'utilisateur peut révoquer l'autorisation dans Réglages ou supprimer l'app. C'est un outil de friction, pas un contrôle parental.
- Le filtrage web peut casser si Instagram modifie sa structure d'URLs. Le script doit être facile à mettre à jour.
- La WebView ne reçoit pas de notifications push. Et iOS masque aussi les notifications d'une app bloquée par un shield Screen Time, sans API pour les autoriser : **pas de notifications de DMs tant qu'Instagram est bloqué**. Limite acceptée le 30/09/2026 : les DMs se consultent en ouvrant FocusLite.
