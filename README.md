# Voie Rapide

[![Ruby](https://img.shields.io/badge/Ruby-3.2.1-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.0.2-red.svg)](https://rubyonrails.org/)
[![DSFR](https://img.shields.io/badge/DSFR-1.13.0-blue.svg)](https://www.systeme-de-design.gouv.fr/)

**Voie Rapide** est une application Rails 8 qui simplifie les candidatures aux marchés publics pour les petites et moyennes entreprises (PME). Le projet vise à transformer les procédures d'appel d'offres complexes en un processus rationalisé et convivial, intégré aux plateformes d'achat existantes.

## 🎯 Objectif

Faciliter l'accès des PME aux marchés publics français en :
- Réduisant les formalités administratives
- Automatisant l'identification des entreprises (SIRET)
- Simplifiant la gestion documentaire
- Fournissant des attestations officielles

## ✨ Fonctionnalités principales

### 🔐 Authentification OAuth
- Intégration avec les plateformes d'éditeurs
- Flux d'autorisation sécurisé
- Gestion des tokens et des scopes

### 📋 Gestion documentaire
- Documents requis par type de marché
- Validation PDF uniquement (version MVP)
- Génération automatique d'attestations
- Téléchargement sécurisé

### 🏢 Identification SIRET
- Validation automatique des numéros SIRET
- Récupération des informations d'entreprise
- Vérification de l'éligibilité

### 🎨 Interface gouvernementale
- Système de Design de l'État (DSFR)
- Interface accessible et responsive
- Thèmes clair/sombre/système
- Conformité aux standards gouvernementaux

### 🌍 Internationalisation
- Support multilingue (français/anglais)
- Configuration i18n complète
- Contenu externalisé dans des fichiers YAML

## 🛠 Technologies utilisées

### Backend
- **Ruby 3.2.1** - Langage de programmation
- **Rails 8.0.2** - Framework web
- **PostgreSQL** - Base de données principale
- **Solid Cable/Cache/Queue** - Infrastructure Rails database-backed

### Frontend
- **DSFR (Système de Design de l'État) v1.13.0** - Framework CSS gouvernemental
- **Turbo & Stimulus (Hotwire)** - Interactivité frontend
- **Importmap** - Gestion des modules JavaScript
- **Propshaft** - Pipeline d'assets moderne

### Tests et Qualité
- **RSpec** - Tests unitaires et d'intégration
- **Cucumber** - Tests comportementaux (BDD)
- **FactoryBot** - Génération de données de test
- **Shoulda Matchers** - Matchers de test avancés
- **RuboCop** - Analyse statique du code
- **Capybara + Selenium** - Tests système

## 📋 Prérequis

- Ruby 3.2.1
- PostgreSQL 12+
- Git

## 🚀 Installation et configuration

### 1. Cloner le projet
```bash
git clone [URL_DU_PROJET]
cd voie_rapide
```

### 2. Installer les dépendances
```bash
# Installer les gems Ruby
bundle install
```

### 3. Configurer la base de données
```bash
# Préparer la base de données
bin/rails db:prepare

# Ou pour un reset complet
bin/rails db:reset
```

### 4. Charger les données de test (optionnel)
```bash
bin/rails db:seed
```

## 🔧 Commandes de développement

### Serveur de développement
```bash
# Démarrer le serveur de développement
bin/dev

# Ou directement Rails
bin/rails server
```

### Application de démonstration (Fake Editor App)
```bash
# Démarrer l'application de démonstration OAuth2
cd fake_editor_app
bundle install
bundle exec rackup -p 4567

# Accéder au dashboard : http://localhost:4567
```

### Base de données
```bash
# Migrations
bin/rails db:migrate

# Reset complet
bin/rails db:reset

# Préparation (setup + migrations)
bin/rails db:prepare
```

### Tests
```bash
# Tous les tests RSpec
bundle exec rspec

# Tests Cucumber
bundle exec cucumber

# Tests avec base de données fraîche
bin/rails test:db
```

### Qualité du code
```bash
# Vérification RuboCop
bin/rubocop

# Correction automatique
bin/rubocop -a

# Suite de qualité complète
bin/rubocop && bundle exec rspec && bundle exec cucumber
```

### Assets
```bash
# Précompilation des assets
bin/rails assets:precompile

# Nettoyage des assets
bin/rails assets:clobber
```

## 🏗 Architecture

### Structure Rails
```
app/
├── controllers/     # Gestion des requêtes HTTP
├── models/         # Logique métier et données
├── views/          # Templates et présentation
├── helpers/        # Assistants de vue
├── jobs/           # Tâches en arrière-plan
└── services/       # Services métier

config/             # Configuration de l'application
├── locales/        # Fichiers de traduction i18n
└── routes.rb       # Routes de l'application

db/                 # Schéma et migrations
spec/               # Tests RSpec
features/           # Tests Cucumber
```

### Modules principaux
- **Module**: `VoieRapide` - Module principal de l'application
- **Locales**: Français (défaut), Anglais
- **Base de données**: PostgreSQL avec schémas multiples

## 🔐 Sécurité

### Standards appliqués
- Protection CSRF intégrée
- Paramètres forts (Strong Parameters)
- Validation côté serveur
- Sanitisation des entrées utilisateur
- Authentification OAuth2 sécurisée

### Conformité
- Respect du RGPD
- Standards d'accessibilité gouvernementaux
- Sécurité des données sensibles
- Audit et logs de sécurité

## 🌐 Internationalisation

L'application supporte plusieurs langues via Rails i18n :

### Langues disponibles
- **Français** (défaut) - `fr`
- **Anglais** - `en`

### Structure des traductions
```yaml
fr:
  application:      # Métadonnées de l'app
  header:          # Navigation et branding
  footer:          # Liens légaux
  home:            # Page d'accueil
    features:      # Fonctionnalités
    workflow:      # Processus en 3 étapes
```

## 🎭 Application de Démonstration (Fake Editor App)

Une application Sinatra complète qui démontre l'intégration OAuth2 avec Voie Rapide.

### Fonctionnalités
- **Authentification OAuth2** : Client Credentials flow
- **Dashboard visuel** : Statut et détails des tokens en temps réel
- **Gestion des tokens** : Authentification, rafraîchissement, nettoyage
- **Base SQLite** : Stockage local des tokens
- **Interface utilisateur** : Design inspiré du DSFR

### Démarrage rapide
```bash
# 1. Démarrer Voie Rapide
bin/dev

# 2. Dans un autre terminal, démarrer l'app de démo
cd fake_editor_app
bundle install
bundle exec rackup -p 4567

# 3. Accéder au dashboard
# http://localhost:4567
```

### Utilisation
1. Cliquer sur **"S'authentifier"** pour obtenir un token OAuth2
2. Visualiser les détails du token (expiration, scope, etc.)
3. Utiliser **"Rafraîchir le Token"** pour renouveler
4. Tester l'intégration complète avec l'API

Voir [fake_editor_app/README.md](fake_editor_app/README.md) pour plus de détails.

## 🧪 Tests

### Types de tests
- **Tests unitaires** (RSpec) - Modèles, contrôleurs, services
- **Tests d'intégration** (RSpec) - Flux complets
- **Tests comportementaux** (Cucumber) - Scénarios utilisateur
- **Tests système** (Capybara) - Interface utilisateur

### Couverture actuelle
- ✅ Page d'accueil avec DSFR
- ✅ Intégration i18n
- ✅ Configuration de base
- ✅ Authentification OAuth2
- ✅ Qualité de code (RuboCop)

### Exécution des tests
```bash
# Tests RSpec uniquement
bundle exec rspec

# Tests Cucumber uniquement  
CUCUMBER_PUBLISH_QUIET=true bundle exec cucumber

# Suite complète
bin/rubocop && bundle exec rspec && bundle exec cucumber
```

## 🚢 Déploiement

### Configuration de production
- Variables d'environnement pour les secrets
- Configuration SSL/TLS
- Optimisation des assets
- Configuration de la base de données
- Logs et monitoring

### Outils de déploiement
- **Kamal** - Déploiement Docker
- **Thruster** - Mise en cache et accélération
- Support des conteneurs Docker

## 🤝 Contribution

### Standards de développement
1. **Recherche → Planification → Implémentation**
2. Tests obligatoires (RSpec + Cucumber)
3. Qualité code (RuboCop sans violation)
4. Convention Rails respectée
5. Documentation i18n en français

### Workflow de contribution
1. Créer une branche feature
2. Développer avec tests
3. Vérifier la qualité (`bin/rubocop`)
4. Exécuter tous les tests
5. Créer une pull request

## 📚 Documentation

### Documentation API et Intégration
- [**Guide d'Intégration API**](docs/API_INTEGRATION.md) - Documentation complète pour les éditeurs
- [Authentification OAuth2](docs/API_INTEGRATION.md#authentification-oauth2) - Flux Client Credentials
- [Exemples d'Intégration](docs/API_INTEGRATION.md#exemples-dintégration) - JavaScript, PHP, Python
- [**Fake Editor App**](fake_editor_app/README.md) - Application de démonstration OAuth2

### Ressources utiles
- [Rails 8.0 Guide](https://guides.rubyonrails.org/)
- [DSFR - Système de Design de l'État](https://www.systeme-de-design.gouv.fr/)
- [RSpec Documentation](https://rspec.info/)
- [Cucumber Guides](https://cucumber.io/docs)

### Conventions du projet
- Code en anglais, interface en français
- Messages de commit en français
- Documentation technique en français
- Tests comportementaux en français

## 📄 Licence

Ce projet est développé pour l'administration française dans le cadre de l'amélioration de l'accès aux marchés publics.

## 🙋‍♂️ Support

Pour toute question ou problème :
1. Consulter la documentation
2. Vérifier les issues existantes
3. Créer une nouvelle issue avec les détails

---

**Voie Rapide** - Simplifiez vos candidatures aux marchés publics 🚀
