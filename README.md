# Voie Rapide

[![Ruby](https://img.shields.io/badge/Ruby-3.4.5-red.svg)](https://www.ruby-lang.org/)
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

### 🔗 Système de Webhooks
- Notifications en temps réel vers les éditeurs
- Signatures HMAC pour la sécurité
- Système de retry intelligent avec circuit breaker
- Gestion centralisée des événements webhook

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

### Requirements
- ruby 3.4.5
- postrgresql >= 15

### Backend
- **Rails 8.0.2** - Framework web
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

- Ruby 3.4.5
- PostgreSQL 12+
- Git

## 🌐 Environnements

### 🧪 Sandbox (environnement de test)

- **Voie Rapide (Fast Track)** : https://sandbox.voie-rapide.services.api.gouv.fr/
- **Éditeur de démonstration (Fake Editor)** : https://sandbox.voie-rapide-edition.services.api.gouv.fr/

Ces environnements permettent de tester l'intégration complète sans affecter les données de production.

## 🚀 Installation et configuration

### 1. Cloner le projet
```bash
git clone [URL_DU_PROJET]
cd voie_rapide
```

### 3. Installer/configurer

```bash
./bin/install
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

### Administration des éditeurs et webhooks
```bash
# Interface d'administration (après avoir créé un admin)
# URL: http://localhost:3000/admin

# Gestion des éditeurs
# - Créer/modifier des éditeurs
# - Configurer les URLs de webhook et redirection
# - Générer les secrets webhook
# - Activer/désactiver les éditeurs

# Surveillance des webhooks
# - Consulter les événements webhook
# - Réessayer les webhooks échoués
# - Statistiques de succès/échec
```

### Assets
```bash
# Précompilation des assets
bin/rails assets:precompile

# Nettoyage des assets
bin/rails assets:clobber
```

### Configuration des champs et traductions
```bash
# Import de la configuration des champs depuis CSV
bin/rails field_configuration:import

# Import depuis un fichier CSV personnalisé
bin/rails field_configuration:import_from_file[/chemin/vers/fichier.csv]

# Validation de la structure CSV sans import
bin/rails field_configuration:validate[/chemin/vers/fichier.csv]

# Import des traductions des champs depuis CSV
bin/rails field_translations:import

# Import des traductions depuis un fichier CSV personnalisé
bin/rails field_translations:import_from_file[/chemin/vers/fichier.csv]
```

#### Configuration des champs (`field_configuration`)
Ces tâches permettent de configurer les champs de formulaire à partir d'un fichier CSV :

- **`field_configuration:import`** : Importe la configuration des champs depuis le fichier CSV par défaut (`config/form_fields/fields.csv`)
  - Crée les `MarketAttribute` et associations avec les `MarketType`
  - Supprime en mode soft-delete les champs non présents dans le CSV
  - Affiche des statistiques détaillées de l'import

- **`field_configuration:import_from_file`** : Même fonctionnalité mais avec un fichier CSV personnalisé

- **`field_configuration:validate`** : Valide la structure et le contenu du fichier CSV sans effectuer d'import

#### Traductions des champs (`field_translations`)
Ces tâches permettent d'extraire et de mettre à jour les traductions françaises depuis le même fichier CSV :

- **`field_translations:import`** : Extrait les traductions des colonnes CSV et met à jour `config/locales/form_fields.fr.yml`
  - Extrait les titres et descriptions côté acheteur (`category_acheteur`, `titre_acheteur`, etc.)
  - Met à jour les sections `categories`, `subcategories` et `fields` du fichier de traduction
  - Compatible avec les vues existantes sans modification de code

- **`field_translations:import_from_file`** : Même fonctionnalité mais avec un fichier CSV personnalisé

#### Structure du fichier CSV attendu
Le fichier CSV doit contenir les colonnes suivantes (ligne 4 = en-têtes) :
- `category_key`, `subcategory_key`, `key` : Clés techniques
- `category_acheteur`, `subcategory_acheteur` : Traductions des catégories/sous-catégories  
- `titre_acheteur`, `description_acheteur` : Traductions des champs côté acheteur
- `import` : `oui` pour les lignes à traiter
- Colonnes de types de marchés : `services`, `fournitures`, `travaux`, `défense`

## 🏗 Architecture

### Structure Rails
```
app/
├── controllers/     # Gestion des requêtes HTTP
│   ├── admin/       # Interface d'administration (éditeurs, webhooks)
│   ├── api/v1/      # API RESTful pour les éditeurs
│   └── buyer/       # Interface candidat
├── models/         # Logique métier et données
│   ├── editor.rb    # Modèle éditeur avec config webhook
│   ├── webhook_event.rb  # Événements webhook
│   └── public_market.rb  # Marchés publics
├── services/       # Services métier
│   ├── webhook_delivery_service.rb  # Livraison webhook
│   ├── webhook_circuit_breaker.rb   # Circuit breaker
│   └── editor_sync_service.rb       # Sync OAuth
├── jobs/           # Tâches en arrière-plan
│   ├── webhook_retry_job.rb    # Retry webhooks échoués
│   └── webhook_sync_job.rb     # Sync données via webhooks
└── views/          # Templates et présentation
    └── admin/       # Interface admin pour webhooks

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

### 🚀 Pour les Équipes Techniques
- [**📖 Guide de Démarrage**](docs/GUIDE_DE_DEMARRAGE.md) - Navigation et glossaire de toute la documentation
- [**🏃‍♂️ Démarrage Rapide**](docs/DEMARRAGE_RAPIDE.md) - Intégration complète en 30 minutes

### 📋 Documentation Technique Détaillée

#### Authentification et Sécurité
- [**🔐 Authentification OAuth2**](docs/AUTHENTIFICATION_OAUTH.md) - Flux Client Credentials, gestion tokens, sécurité
- [**🔔 Webhooks**](docs/WEBHOOKS.md) - Notifications temps réel, signatures HMAC, retry intelligent

#### Flux Métier
- [**🏢 Flux Acheteur**](docs/FLUX_ACHETEUR.md) - Création et configuration des marchés publics
- [**👥 Flux Candidat**](docs/FLUX_CANDIDAT.md) - Soumission et finalisation des candidatures

#### Références Techniques
- [**⚙️ Référence API**](docs/REFERENCE_API.md) - Spécifications complètes des endpoints
- [**🏗️ Schémas d'Intégration**](docs/SCHEMAS_INTEGRATION.md) - Architecture et diagrammes techniques

### 💡 Application de Démonstration
- [**🎭 Fake Editor App**](fake_editor_app/README.md) - Exemple d'implémentation OAuth2

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
