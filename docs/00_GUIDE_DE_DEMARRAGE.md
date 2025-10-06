# Guide de Démarrage - Intégration Voie Rapide

## 🎯 Vue d'Ensemble

**Voie Rapide** est une API gouvernementale qui simplifie les candidatures aux marchés publics pour les PME. Ce guide vous orientera vers la documentation appropriée selon vos besoins d'intégration.

## 📖 Comment Utiliser Cette Documentation

### 🚀 Démarrage Rapide (Recommandé pour Commencer)
- **[Démarrage Rapide](01_DEMARRAGE_RAPIDE.md)** - Intégration complète en 30 minutes
  - *Quand l'utiliser* : Premier contact avec l'API, démonstration rapide
  - *Contenu* : Configuration, premier appel API, tests de base

### 🔐 Authentification et Sécurité
- **[Authentification OAuth2](02_AUTHENTIFICATION_OAUTH.md)** - Spécifications OAuth2
  - *Quand l'utiliser* : Implémentation de l'authentification en production
  - *Contenu* : Client Credentials, gestion tokens, sécurité

- **[Webhooks](07_WEBHOOKS.md)** - Notifications temps réel
  - *Quand l'utiliser* : Réception d'événements (marchés créés, candidatures soumises)
  - *Contenu* : Types d'événements, signatures HMAC, retry intelligent

### 🏢 Flux Métier (Pour Comprendre le Processus)
- **[Flux Acheteur](03_FLUX_ACHETEUR.md)** - Processus côté acheteurs publics
  - *Quand l'utiliser* : Comprendre comment les marchés sont créés et configurés
  - *Contenu* : Wizard de création, configuration champs, notifications webhook

- **[Flux Candidat](04_FLUX_CANDIDAT.md)** - Processus côté entreprises candidates
  - *Quand l'utiliser* : Comprendre l'expérience utilisateur des candidats
  - *Contenu* : SIRET, étapes dynamiques, génération PDF/ZIP

### ⚙️ Références Techniques (Pour l'Implémentation)
- **[Référence API](05_REFERENCE_API.md)** - Spécifications complètes des endpoints
  - *Quand l'utiliser* : Implémentation détaillée, débogage
  - *Contenu* : Tous les endpoints, paramètres, réponses, codes d'erreur

- **[Schémas d'Intégration](06_SCHEMAS_INTEGRATION.md)** - Architecture et diagrammes
  - *Quand l'utiliser* : Conception architecture, compréhension des flux
  - *Contenu* : Diagrammes ASCII, séquences d'appels, états des objets

### 🛠️ Utilitaires et Scripts
- **[Scripts de Référence](99_SCRIPTS_REFERENCE.md)** - Scripts bash, curl et utilitaires
  - *Quand l'utiliser* : Automatisation, tests, intégration CI/CD
  - *Contenu* : Scripts authentification, création marchés, webhooks, monitoring

## 🗂️ Glossaire et Concepts Clés

### Authentification
- **OAuth2 Client Credentials** : Authentification machine-à-machine sans utilisateur
- **Bearer Token** : Token JWT de 24h à inclure dans l'en-tête Authorization
- **Client ID/Secret** : Identifiants fournis par l'administration Voie Rapide

### Marchés Publics
- **Marché Public (Tender)** : Appel d'offres créé par un acheteur public
- **Types de Marchés** : Services, Fournitures, Travaux, Défense
- **Étapes Dynamiques** : Formulaires générés selon le type de marché
- **Champs Obligatoires/Optionnels** : Configuration par type de marché

### Candidatures
- **Application** : Candidature d'une entreprise à un marché
- **SIRET** : Identifiant obligatoire de l'entreprise française
- **Étapes** : Séquence de formulaires (identité, capacités, documents)
- **Attestation PDF** : Preuve officielle de soumission avec timestamp

### Intégration Technique
- **Webhooks** : Notifications HTTP POST avec signature HMAC
- **Popup/iFrame** : Modes d'intégration dans votre plateforme
- **ZIP Package** : Archive de tous les documents soumis
- **Circuit Breaker** : Mécanisme de protection contre les pannes

## 🔄 Parcours d'Intégration Recommandé

### Phase 1 : Découverte (15 min)
1. **Lisez ce guide** pour comprendre la structure
2. **[Démarrage Rapide](01_DEMARRAGE_RAPIDE.md)** pour un premier test
3. **[Schémas d'Intégration](06_SCHEMAS_INTEGRATION.md)** pour visualiser l'architecture

### Phase 2 : Implémentation (1-2 jours)
1. **[Authentification OAuth2](02_AUTHENTIFICATION_OAUTH.md)** + tests curl
2. **[Référence API](05_REFERENCE_API.md)** pour l'implémentation
3. **[Webhooks](07_WEBHOOKS.md)** pour les notifications temps réel

### Phase 3 : Production (1 jour)
1. **Tests avec fake_editor_app** pour validation complète
2. **Configuration environnement** production
3. **Mise en service** et monitoring

## 🏗️ Architecture d'Intégration

```
┌─────────────────────────────────────────────────────────────┐
│                    VOTRE PLATEFORME ÉDITEUR                │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Création      │  │  Intégration    │  │   Réception     │ │
│  │   Marchés       │  │  Popup/iFrame   │  │   Webhooks      │ │
│  │                 │  │                 │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ OAuth2 + API Calls
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      API VOIE RAPIDE                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   OAuth2        │  │  Gestion        │  │   Génération    │ │
│  │   Doorkeeper    │  │  Candidatures   │  │   Documents     │ │
│  │                 │  │  Marchés        │  │   PDF/ZIP       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🚦 Points d'Attention

### ⚠️ Exigences Techniques
- **HTTPS obligatoire** pour tous les appels
- **Validation SIRET** requise pour toutes les candidatures françaises
- **Signature HMAC** pour vérifier l'authenticité des webhooks
- **Gestion expiration tokens** (24h de validité)

### ⚠️ Limitations Actuelles (MVP)
- **PDF uniquement** pour les documents que nous fournissons (pas d'autres formats)
- **France uniquement** (validation SIRET obligatoire)

### ⚠️ Sécurité
- **Client Secret** ne doit jamais être exposé côté client
- **Variables d'environnement** pour stocker les secrets
- **Rotation régulière** des credentials (bonne pratique non mise en place actuellement)
- **Logs de sécurité** pour audit

## 📞 Support et Ressources

### 🏛️ Administration
- **Enregistrement éditeurs** : Contact requis avec l'administration
- **Credentials OAuth** : Fournis manuellement après validation
- **Support technique** : Via channels officiels

### 🧪 Environnements
- **Sandbox** : https://sandbox.voie-rapide.services.api.gouv.fr/
- **Documentation Live** : Tests avec données réelles en sandbox
- **Fake Editor** : Exemple d'implémentation de référence

### 📚 Ressources Externes
- **OAuth2 Specification** : [RFC 6749](https://tools.ietf.org/html/rfc6749)
- **JWT Tokens** : [RFC 7519](https://tools.ietf.org/html/rfc7519)
- **HMAC Signatures** : [RFC 2104](https://tools.ietf.org/html/rfc2104)
- **Système de Design DSFR** : [documentation officielle](https://www.systeme-de-design.gouv.fr/)

## LETS GO

**Prêt à commencer ? → [Démarrage Rapide (30min)](01_DEMARRAGE_RAPIDE.md)**
