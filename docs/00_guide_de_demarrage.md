# Guide de Démarrage - Intégration Passe Marché

## 🎯 Vue d'Ensemble

**Passe Marché** est une API gouvernementale qui simplifie les candidatures aux marchés publics pour les PME. Ce guide vous orientera vers la documentation appropriée selon vos besoins d'intégration.

## 📖 Comment Utiliser Cette Documentation

### 🚀 Démarrage Rapide (Recommandé pour Commencer)

* [**Démarrage Rapide**](01_demarrage_rapide.md) - Intégration complète en 30 minutes
  * _Quand l'utiliser_ : Premier contact avec l'API, démonstration rapide
  * _Contenu_ : Configuration, premier appel API, tests de base

### 🔐 Authentification et Sécurité

* [**Authentification OAuth2**](02_authentification_oauth.md) - Spécifications OAuth2
  * _Quand l'utiliser_ : Implémentation de l'authentification en production
  * _Contenu_ : Client Credentials, gestion tokens, sécurité
* [**Webhooks**](07_webhooks.md) - Notifications temps réel
  * _Quand l'utiliser_ : Réception d'événements (marchés créés, candidatures soumises)
  * _Contenu_ : Types d'événements, signatures HMAC, retry intelligent

### 🏢 Flux Métier (Pour Comprendre le Processus)

* [**Flux Acheteur**](03_flux_acheteur.md) - Processus côté acheteurs publics
  * _Quand l'utiliser_ : Comprendre comment les marchés sont créés et configurés
  * _Contenu_ : Wizard de création, configuration champs, notifications webhook
* [**Flux Candidat**](04_flux_candidat.md) - Processus côté entreprises candidates
  * _Quand l'utiliser_ : Comprendre l'expérience utilisateur des candidats
  * _Contenu_ : SIRET, étapes dynamiques, génération PDF/ZIP

### ⚙️ Références Techniques (Pour l'Implémentation)

* [**Référence API**](05_reference_api.md) - Spécifications complètes des endpoints
  * _Quand l'utiliser_ : Implémentation détaillée, débogage
  * _Contenu_ : Tous les endpoints, paramètres, réponses, codes d'erreur
* [**Schémas d'Intégration**](06_schemas_integration.md) - Architecture et diagrammes
  * _Quand l'utiliser_ : Conception architecture, compréhension des flux
  * _Contenu_ : Diagrammes ASCII, séquences d'appels, états des objets

### 🛠️ Utilitaires et Scripts

* [**Scripts de Référence**](99_scripts_reference.md) - Scripts bash, curl et utilitaires
  * _Quand l'utiliser_ : Automatisation, tests, intégration CI/CD
  * _Contenu_ : Scripts authentification, création marchés, webhooks, monitoring

### 🌍 Environnements

* [**Environnements**](08_environnements.md) - Configuration des environnements
  * _Quand l'utiliser_ : Choix de l'environnement, migration entre environnements
  * _Contenu_ : URLs, caractéristiques, flux de déploiement, checklist migration

## 🗂️ Glossaire et Concepts Clés

### Authentification

* **OAuth2 Client Credentials** : Authentification machine-à-machine sans utilisateur
* **Bearer Token** : Token JWT de 24h à inclure dans l'en-tête Authorization
* **Client ID/Secret** : Identifiants fournis par l'administration Passe Marché

### Marchés Publics

* **Marché Public (Tender)** : Appel d'offres créé par un acheteur public
* **Types de Marchés** : Services, Fournitures, Travaux, Défense
* **Étapes Dynamiques** : Formulaires générés selon le type de marché
* **Champs Obligatoires/Optionnels** : Configuration par type de marché

### Candidatures

* **Application** : Candidature d'une entreprise à un marché
* **SIRET** : Identifiant obligatoire de l'entreprise française
* **Étapes** : Séquence de formulaires (identité, capacités, documents)
* **Attestation PDF** : Preuve officielle de soumission avec timestamp

### Intégration Technique

* **Webhooks** : Notifications HTTP POST avec signature HMAC
* **Popup/iFrame** : Modes d'intégration dans votre plateforme
* **ZIP Package** : Archive de tous les documents soumis
* **Circuit Breaker** : Mécanisme de protection contre les pannes

## 🔄 Parcours d'Intégration Recommandé

### Phase 1 : Découverte (15 min)

1. **Lisez ce guide** pour comprendre la structure
2. [**Démarrage Rapide**](01_demarrage_rapide.md) pour un premier test
3. [**Schémas d'Intégration**](06_schemas_integration.md) pour visualiser l'architecture

### Phase 2 : Implémentation (1-2 jours)

1. [**Authentification OAuth2**](02_authentification_oauth.md) + tests curl
2. [**Référence API**](05_reference_api.md) pour l'implémentation
3. [**Webhooks**](07_webhooks.md) pour les notifications temps réel

### Phase 3 : Production (1 jour)

1. **Tests avec fake\_editor\_app** pour validation complète
2. **Configuration environnement** production
3. **Mise en service** et monitoring

## 🏗️ Architecture d'Intégration

```
┌─────────────────────────────────────────────────────────────┐
│                    VOTRE PLATEFORME                         │
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
│                      API PASSE MARCHE                       │
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

* **HTTPS obligatoire** pour tous les appels
* **Validation SIRET** requise pour toutes les candidatures françaises
* **Signature HMAC** pour vérifier l'authenticité des webhooks
* **Gestion expiration tokens** (24h de validité)

### ⚠️ Limitations Actuelles (MVP)

* **PDF uniquement** pour les documents que nous fournissons (pas d'autres formats)
* **France uniquement** (validation SIRET obligatoire)

### ⚠️ Sécurité

* **Client Secret** ne doit jamais être exposé côté client
* **Variables d'environnement** pour stocker les secrets
* **Rotation régulière** des credentials (bonne pratique non mise en place actuellement)
* **Scan antivirus** des fichiers déposés par les candidats (ClamAV) - [Documentation sécurité fichiers](09_securite_fichiers.md)
* **Logs de sécurité** pour audit

## 📞 Support et Ressources

### 🏛️ Administration

* **Enregistrement des plateformes de marchés publics** : Contact requis avec l'administration
* **Credentials OAuth** : Fournis manuellement après validation
* **Support technique** : Via channels officiels

### 🧪 Environnements

Passe Marché dispose de 4 environnements pour les différentes phases d'intégration :

| Environnement  | URL                                      | Données API | Accès              |
| -------------- | ---------------------------------------- | ----------- | ------------------ |
| **Staging**    | https://staging.passemarche.data.gouv.fr | Simulées    | plateformes de marchés publics           |
| **Preprod**    | https://preprod.passemarche.data.gouv.fr | Réelles     | Sécurisé           |
| **Production** | https://passemarche.data.gouv.fr         | Réelles     | Sécurisé           |
| **Sandbox**    | https://sandbox.passemarche.data.gouv.fr | Simulées    | Interne (instable) |

**Fake Editor** (démo d'intégration) : Remplacez `passemarche` par `editeur.passemarche` dans les URLs ci-dessus.

[**Documentation complète des environnements**](08_environnements.md) : URLs, caractéristiques, et flux de déploiement

### 📚 Ressources Externes

* **OAuth2 Specification** : [RFC 6749](https://tools.ietf.org/html/rfc6749)
* **JWT Tokens** : [RFC 7519](https://tools.ietf.org/html/rfc7519)
* **HMAC Signatures** : [RFC 2104](https://tools.ietf.org/html/rfc2104)
* **Système de Design DSFR** : [documentation officielle](https://www.systeme-de-design.gouv.fr/)

## LETS GO

**Prêt à commencer ? →** [**Démarrage Rapide (30min)**](01_demarrage_rapide.md)
