# Fake Editor App - Démonstration d'Intégration Passe Marché

Cette application Sinatra démontre comment intégrer une plateforme de marchés publics  avec l'API OAuth2 de Passe Marché.

## 🎯 Objectif

Fournir un exemple concret d'intégration OAuth2 avec Passe Marché, incluant :
- Authentification via Client Credentials flow
- Stockage et gestion des tokens
- Interface utilisateur pour visualiser les tokens
- Mécanisme de rafraîchissement des tokens

## 🛠 Technologies

- **Sinatra** : Framework web léger
- **SQLite** : Base de données locale pour le stockage des tokens
- **Sequel** : ORM pour la gestion de la base de données
- **HTTParty** : Client HTTP pour les appels API
- **dotenv** : Gestion des variables d'environnement

## 📋 Prérequis

- Ruby 3.4.5
- Passe Marché en cours d'exécution sur http://localhost:3000
- Éditeur demo configuré dans Passe Marché

## 🚀 Installation

### 1. Installer les dépendances

```bash
cd fake_editor_app
bundle install
```

### 2. Configurer les variables d'environnement

```bash
cp .env.example .env
```

Éditez le fichier `.env` avec vos paramètres :

```
FAST_TRACK_URL=http://localhost:3000
CLIENT_ID=demo_editor_client
CLIENT_SECRET=demo_editor_secret
PORT=4567
RACK_ENV=development
```

### 3. Configurer l'éditeur demo dans Passe Marché

Dans la console Rails de Passe Marché :

```ruby
demo_editor = Editor.create!(
  name: 'Demo Editor App',
  client_id: 'demo_editor_client',
  client_secret: 'demo_editor_secret',
  completion_webhook_url: 'http://localhost:4567/webhooks/voie-rapide',
  redirect_url: 'http://localhost:4567?completed={market_identifier}',
  authorized: true,
  active: true
)
demo_editor.generate_webhook_secret!
demo_editor.sync_to_doorkeeper!
```

**Note**: Les URLs de webhook et redirection sont configurées pour pointer vers l'application fake editor sur le port 4567.

## 🎮 Utilisation

### 1. Démarrer l'application

```bash
bundle exec rackup -p 4567
```

### 2. Accéder à l'interface

Ouvrez votre navigateur à : http://localhost:4567

### 3. Tester l'intégration complète

1. Cliquez sur **"S'authentifier"** pour obtenir un token OAuth2
2. Le token sera affiché avec ses détails (type, scope, expiration)
3. Créez un marché public avec le formulaire
4. Cliquez sur l'URL de configuration pour accéder à Passe Marché
5. Complétez la configuration du marché dans Passe Marché
6. À la fin, le marché sera marqué comme "Terminé" via webhook
7. Utilisez **"Rafraîchir le Token"** si nécessaire
8. Utilisez **"Effacer les Tokens"** pour nettoyer la base de données

## 🏗 Structure du Projet

```
fake_editor_app/
├── app.rb                    # Application Sinatra principale
├── config.ru                 # Configuration Rack
├── Gemfile                   # Dépendances Ruby
├── .env.example              # Template de configuration
├── lib/
│   ├── database.rb           # Configuration SQLite et modèles
│   └── fast_track_client.rb  # Client OAuth2 pour Passe Marché
├── views/
│   ├── layout.erb            # Template de base
│   └── dashboard.erb         # Interface du dashboard
├── public/
│   ├── style.css             # Styles CSS
│   └── app.js                # JavaScript client
└── README.md                 # Cette documentation
```

## 🔧 Fonctionnalités

### Authentification OAuth2
- Client Credentials flow
- Gestion automatique des tokens
- Stockage sécurisé en base SQLite

### Création de marchés publics
- Formulaire de création avec validation
- Intégration avec l'API Passe Marché
- Stockage local des marchés créés

### Réception de webhooks
- Endpoint `/webhooks/voie-rapide` pour les notifications
- Traitement automatique des événements de completion
- Mise à jour du statut des marchés en temps réel

### Interface utilisateur
- Dashboard avec statut d'authentification
- Affichage des détails du token
- Liste des marchés publics avec leur statut
- Boutons pour authentification/rafraîchissement
- Countdown en temps réel pour l'expiration

### Stockage des données
- Base de données SQLite locale
- Modèle Token avec validation d'expiration
- Modèle Market pour les marchés publics
- Nettoyage automatique des anciens tokens

## 🛡 Sécurité

- Variables d'environnement pour les secrets
- Tokens stockés localement uniquement
- Validation d'expiration des tokens
- Interface sécurisée sans exposition des secrets

## 🐛 Dépannage

### Erreur d'authentification
- Vérifiez que Passe Marché est lancé
- Vérifiez les variables d'environnement
- Assurez-vous que l'éditeur demo est créé et autorisé

### Erreur de base de données
- Le fichier SQLite sera créé automatiquement
- Supprimez `fake_editor.db` pour réinitialiser

### Erreur de port
- Changez le port dans `.env` si 4567 est occupé
- Utilisez `bundle exec rackup -p AUTRE_PORT`

## 📚 Documentation

Cette application sert d'exemple pour :
- [Guide d'Intégration API](../docs/API_INTEGRATION.md)
- Implémentation OAuth2 Client Credentials
- Gestion des tokens et erreurs
- Interface utilisateur pour l'authentification

## 🤝 Contribution

Cette application est un exemple de démonstration. Pour des améliorations :
1. Créez une branche feature
2. Testez vos modifications
3. Assurez-vous que l'intégration fonctionne
4. Créez une pull request

---

*Application de démonstration pour l'intégration OAuth2 avec Passe Marché*
