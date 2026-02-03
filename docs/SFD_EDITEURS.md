# Spécification Fonctionnelle Détaillée (SFD)
# Intégration Passe Marché pour Éditeurs

---

**Version** : 1.0.0
**Date** : 2026-02-03
**Statut** : Draft
**Auteur** : Équipe Passe Marché

---

## Table des matières

1. [Introduction](#1-introduction)
2. [Vue d'ensemble de l'architecture](#2-vue-densemble-de-larchitecture)
3. [Authentification OAuth2](#3-authentification-oauth2)
4. [Parcours Acheteur](#4-parcours-acheteur)
5. [Parcours Candidat](#5-parcours-candidat)
6. [Référence API](#6-référence-api)
7. [Webhooks](#7-webhooks)
8. [Gestion des documents](#8-gestion-des-documents)
9. [Sécurité et conformité](#9-sécurité-et-conformité)
10. [Environnements](#10-environnements)
11. [Annexes](#11-annexes)

---

## 1. Introduction

### 1.1 Présentation de Passe Marché

**Passe Marché** est une plateforme gouvernementale française qui simplifie les candidatures aux marchés publics pour les petites et moyennes entreprises (PME). Elle s'intègre avec les plateformes des éditeurs de marchés publics pour offrir une expérience utilisateur fluide et conforme aux exigences réglementaires.

### 1.2 Objectifs de l'intégration

L'intégration avec Passe Marché permet aux éditeurs de :

- **Créer des marchés publics** via API pour leurs acheteurs
- **Gérer les candidatures** des entreprises sur leurs plateformes
- **Recevoir des notifications** en temps réel via webhooks
- **Télécharger les documents** générés (attestations PDF, dossiers ZIP)

### 1.3 Périmètre du document

Ce document décrit les spécifications fonctionnelles et techniques nécessaires pour intégrer Passe Marché dans une plateforme éditeur, incluant :

- Architecture et flux d'intégration
- Authentification OAuth2
- Endpoints API
- Webhooks et callbacks
- Gestion des documents

### 1.4 Public cible

- Équipes techniques des éditeurs de plateformes de marchés publics
- Architectes logiciels
- Développeurs backend

### 1.5 Glossaire

| Terme | Définition |
|-------|------------|
| **Acheteur** | Agent public responsable de la passation des marchés (buyer) |
| **Candidat** | Entreprise soumettant une offre à un marché public |
| **Consultation** | Synonyme de marché public (tender) |
| **Éditeur** | Plateforme tierce intégrant Passe Marché |
| **Lot** | Subdivision d'un marché public |
| **Marché public** | Appel d'offres lancé par un acheteur public |
| **SIRET** | Identifiant à 14 chiffres d'un établissement français |
| **SIREN** | Identifiant à 9 chiffres d'une entreprise française |
| **OAuth2** | Protocole d'autorisation standard |
| **Client Credentials** | Flux OAuth2 pour authentification machine-à-machine |
| **Bearer Token** | Token d'accès JWT utilisé dans les requêtes API |
| **Webhook** | Notification HTTP push vers un endpoint externe |
| **HMAC-SHA256** | Algorithme de signature cryptographique |

### 1.6 Documents de référence

- [RFC 6749 - OAuth 2.0](https://tools.ietf.org/html/rfc6749)
- [RFC 7519 - JWT](https://tools.ietf.org/html/rfc7519)
- [RFC 2104 - HMAC](https://tools.ietf.org/html/rfc2104)
- [Système de Design de l'État (DSFR)](https://www.systeme-de-design.gouv.fr/)

---

## 2. Vue d'ensemble de l'architecture

### 2.1 Diagramme d'architecture général

```
┌─────────────────────────────────────────────────────────────────┐
│                    PLATEFORME ÉDITEUR                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Backend       │  │  Intégration    │  │   Réception     │  │
│  │   Éditeur       │  │  Popup/iFrame   │  │   Webhooks      │  │
│  │                 │  │                 │  │                 │  │
│  └────────┬────────┘  └────────┬────────┘  └────────▲────────┘  │
└───────────┼─────────────────────┼───────────────────┼───────────┘
            │                     │                   │
            │ OAuth2 + REST API   │ Redirect          │ HTTP POST
            ▼                     ▼                   │
┌───────────────────────────────────────────────────────┐
│                    API PASSE MARCHÉ                   │
├───────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   OAuth2        │  │  Gestion        │  │   Webhooks      │  │
│  │   Doorkeeper    │  │  Marchés &      │  │   Dispatcher    │  │
│  │                 │  │  Candidatures   │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Génération    │  │  APIs           │  │   Stockage      │  │
│  │   PDF           │  │  Gouvernement   │  │   Documents     │  │
│  │                 │  │                 │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└───────────────────────────────────────────────────────┘
```

### 2.2 Flux d'intégration principal

```
┌──────────┐       ┌──────────┐       ┌──────────┐       ┌──────────┐
│ Éditeur  │       │  Passe   │       │ Acheteur │       │ Candidat │
│ Backend  │       │  Marché  │       │  Public  │       │Entreprise│
└────┬─────┘       └────┬─────┘       └────┬─────┘       └────┬─────┘
     │                  │                  │                  │
     │ 1. POST /oauth/token               │                  │
     │─────────────────>│                  │                  │
     │   access_token   │                  │                  │
     │<─────────────────│                  │                  │
     │                  │                  │                  │
     │ 2. POST /api/v1/public_markets     │                  │
     │─────────────────>│                  │                  │
     │   identifier +   │                  │                  │
     │   config_url     │                  │                  │
     │<─────────────────│                  │                  │
     │                  │                  │                  │
     │       3. Redirect vers config_url  │                  │
     │────────────────────────────────────>│                  │
     │                  │                  │                  │
     │                  │ 4. Configuration │                  │
     │                  │    (wizard)      │                  │
     │                  │<─────────────────│                  │
     │                  │                  │                  │
     │ 5. Webhook market.completed        │                  │
     │<─────────────────│                  │                  │
     │                  │                  │                  │
     │ 6. POST /api/v1/public_markets/{id}/market_applications
     │─────────────────>│                  │                  │
     │   identifier +   │                  │                  │
     │   application_url│                  │                  │
     │<─────────────────│                  │                  │
     │                  │                  │                  │
     │        7. Redirect vers application_url               │
     │───────────────────────────────────────────────────────>│
     │                  │                  │                  │
     │                  │ 8. Saisie candidature               │
     │                  │<────────────────────────────────────│
     │                  │                  │                  │
     │ 9. Webhook market_application.completed               │
     │<─────────────────│                  │                  │
     │                  │                  │                  │
     │ 10. GET /api/v1/market_applications/{id}/attestation  │
     │─────────────────>│                  │                  │
     │   PDF binary     │                  │                  │
     │<─────────────────│                  │                  │
     │                  │                  │                  │
```

### 2.3 Modes d'intégration

Passe Marché supporte deux modes d'intégration pour l'interface utilisateur :

| Mode | Description | Cas d'usage |
|------|-------------|-------------|
| **Popup** | Ouverture dans une nouvelle fenêtre | Intégration légère, UX séparée |
| **iFrame** | Intégration dans la page existante | Intégration profonde, UX unifiée |

**[À COMPLÉTER]** : Spécifications détaillées pour l'intégration iFrame (dimensions, événements postMessage, CSP headers).

---

## 3. Authentification OAuth2

### 3.1 Vue d'ensemble

Passe Marché utilise le protocole **OAuth 2.0** avec le flux **Client Credentials** pour l'authentification des éditeurs. Ce flux est adapté à la communication machine-à-machine sans intervention utilisateur.

### 3.2 Prérequis

#### 3.2.1 Enregistrement de l'éditeur

L'enregistrement d'un éditeur est effectué manuellement par un administrateur Passe Marché. L'éditeur reçoit :

| Credential | Description | Format |
|------------|-------------|--------|
| `client_id` | Identifiant unique OAuth2 | Chaîne hexadécimale 32 caractères |
| `client_secret` | Clé secrète OAuth2 | Chaîne hexadécimale 64 caractères |
| `webhook_secret` | Secret pour signature HMAC | Chaîne hexadécimale 64 caractères |

#### 3.2.2 Configuration éditeur

| Paramètre | Requis | Description |
|-----------|--------|-------------|
| `name` | Oui | Nom de la plateforme éditeur |
| `completion_webhook_url` | Non | URL de réception des webhooks |
| `redirect_url` | Non | URL de redirection post-complétion |
| `authorized` | - | Statut d'autorisation (géré par admin) |
| `active` | - | Statut d'activation (géré par admin) |
| `can_create_defense_markets` | - | Autorisation marchés défense |

### 3.3 Obtention du token d'accès

#### 3.3.1 Endpoint

```
POST /oauth/token
```

#### 3.3.2 Requête

**Headers** :
```http
Content-Type: application/x-www-form-urlencoded
```

**Body** :
```
grant_type=client_credentials
client_id={client_id}
client_secret={client_secret}
scope=api_access
```

#### 3.3.3 Réponse succès (200 OK)

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "scope": "api_access"
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `access_token` | string | Token JWT à utiliser dans les requêtes |
| `token_type` | string | Toujours "Bearer" |
| `expires_in` | integer | Durée de validité en secondes (24h) |
| `scope` | string | Permissions accordées |

#### 3.3.4 Réponses d'erreur

| Code | Erreur | Description |
|------|--------|-------------|
| 400 | `invalid_request` | Paramètres manquants ou malformés |
| 400 | `unsupported_grant_type` | Grant type non supporté |
| 401 | `invalid_client` | Credentials invalides ou éditeur non autorisé |

**Exemple d'erreur** :
```json
{
  "error": "invalid_client",
  "error_description": "Client authentication failed"
}
```

### 3.4 Utilisation du token

Inclure le token dans l'en-tête `Authorization` de toutes les requêtes API :

```http
Authorization: Bearer {access_token}
```

### 3.5 Cycle de vie du token

| Caractéristique | Valeur |
|-----------------|--------|
| Durée de validité | 24 heures |
| Révocation | Automatique à l'émission d'un nouveau token |
| Refresh token | Non supporté (nouvelle authentification requise) |

### 3.6 Scopes disponibles

| Scope | Description | Permissions |
|-------|-------------|-------------|
| `api_access` | Scope par défaut recommandé | Toutes les opérations |
| `api_read` | Lecture seule | Consultation des données |
| `api_write` | Écriture | Création et modification |

### 3.7 Bonnes pratiques

1. **Stockage sécurisé** : Ne jamais exposer le `client_secret` côté client
2. **Variables d'environnement** : Stocker les secrets dans des variables d'environnement
3. **Renouvellement anticipé** : Renouveler le token avant expiration (buffer de 5 min)
4. **HTTPS obligatoire** : Toutes les communications doivent utiliser HTTPS
5. **Pas de logging des secrets** : Ne jamais logger client_secret ou access_token

---

## 4. Parcours Acheteur

### 4.1 Vue d'ensemble

Le parcours acheteur permet la création et la configuration d'un marché public. Il se décompose en :

1. **Création via API** : L'éditeur crée le marché avec les informations de base
2. **Configuration via interface** : L'acheteur configure les champs requis
3. **Notification webhook** : L'éditeur est notifié de la complétion

### 4.2 Création du marché public

#### 4.2.1 Endpoint

```
POST /api/v1/public_markets
```

#### 4.2.2 Requête

**Headers** :
```http
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Body** :
```json
{
  "public_market": {
    "name": "Fourniture de matériel informatique",
    "lot_name": "Lot 1 - Ordinateurs portables",
    "deadline": "2024-12-31T23:59:59Z",
    "siret": "13002526500013",
    "market_type_codes": ["supplies", "services"]
  }
}
```

#### 4.2.3 Paramètres

| Champ | Type | Requis | Contraintes | Description |
|-------|------|--------|-------------|-------------|
| `name` | string | Oui | Max 255 caractères | Nom du marché public |
| `deadline` | datetime | Oui | ISO 8601, futur | Date limite de candidature |
| `siret` | string | Oui | 14 chiffres, validation Luhn | SIRET de l'organisation publique |
| `market_type_codes` | array | Oui | Min 1 élément | Types de marché |
| `lot_name` | string | Non | Max 255 caractères | Nom du lot spécifique |

#### 4.2.4 Types de marché

| Code | Description | Combinaison |
|------|-------------|-------------|
| `supplies` | Fournitures (biens, consommables) | Peut être seul ou combiné |
| `services` | Services (prestations, maintenance) | Peut être seul ou combiné |
| `works` | Travaux (construction, BTP) | Peut être seul ou combiné |
| `defense` | Défense nationale | **Doit être combiné** avec un autre type |

**Règle** : Le type `defense` ne peut pas être utilisé seul. Il doit toujours être combiné avec au moins un autre type de marché.

#### 4.2.5 Réponse succès (201 Created)

```json
{
  "identifier": "VR-2024-A1B2C3D4E5F6",
  "configuration_url": "https://passemarche.data.gouv.fr/buyer/public_markets/VR-2024-A1B2C3D4E5F6/setup"
}
```

| Champ | Description |
|-------|-------------|
| `identifier` | Identifiant unique du marché (format: `VR-YYYY-XXXXXXXXXXXX`) |
| `configuration_url` | URL vers l'interface de configuration |

#### 4.2.6 Réponses d'erreur

| Code | Cas | Exemple |
|------|-----|---------|
| 401 | Token invalide | `{"error": "Not authorized"}` |
| 403 | Éditeur non autorisé | `{"error": "Forbidden"}` |
| 422 | Validation échouée | `{"errors": ["Name can't be blank"]}` |

### 4.3 Interface de configuration (Wizard)

L'acheteur est redirigé vers une interface multi-étapes pour configurer le marché.

#### 4.3.1 Étape 1 : Setup initial

**URL** : `/buyer/public_markets/{identifier}/setup`

**Objectifs** :
- Affichage des informations de base du marché
- Validation du SIRET de l'organisation publique
- Option d'ajout du type "défense" (si autorisé)

#### 4.3.2 Étape 2 : Champs obligatoires

**URL** : `/buyer/public_markets/{identifier}/required_fields`

**Objectifs** :
- Sélection des champs obligatoires pour les candidats
- Champs générés automatiquement selon les types de marché
- Groupement par catégories et sous-catégories

**[À COMPLÉTER]** : Liste exhaustive des champs obligatoires par type de marché.

#### 4.3.3 Étape 3 : Champs optionnels

**URL** : `/buyer/public_markets/{identifier}/additional_fields`

**Objectifs** :
- Sélection des champs complémentaires facultatifs
- Filtrage selon la configuration existante

**[À COMPLÉTER]** : Liste exhaustive des champs optionnels disponibles.

#### 4.3.4 Étape 4 : Résumé et validation

**URL** : `/buyer/public_markets/{identifier}/summary`

**Objectifs** :
- Récapitulatif de la configuration complète
- Validation finale par l'acheteur
- Déclenchement de la complétion

### 4.4 Catégories de champs

| Catégorie | Description |
|-----------|-------------|
| `identification` | Informations d'identification de l'entreprise |
| `capacite_economique_financiere` | Capacités économiques et financières |
| `capacite_technique_professionnelle` | Capacités techniques et professionnelles |
| `attestations` | Attestations et certifications |
| `declarations` | Déclarations sur l'honneur |
| `documents` | Documents complémentaires |

**[À COMPLÉTER]** : Sous-catégories détaillées et champs associés.

### 4.5 Callback de retour

Après complétion, l'acheteur est redirigé vers l'URL de redirection configurée avec les paramètres :

```
{redirect_url}?market_identifier={identifier}
```

**Exemple** :
```
https://editeur.com/callback?market_identifier=VR-2024-A1B2C3D4E5F6
```

---

## 5. Parcours Candidat

### 5.1 Vue d'ensemble

Le parcours candidat permet aux entreprises de soumettre leur candidature à un marché public. Il comprend :

1. **Création via API** : L'éditeur crée la candidature
2. **Saisie via interface** : Le candidat complète son dossier
3. **Génération des documents** : Attestation PDF et dossier ZIP
4. **Notification webhook** : L'éditeur est notifié de la complétion

### 5.2 Création de la candidature

#### 5.2.1 Endpoint

```
POST /api/v1/public_markets/{market_identifier}/market_applications
```

#### 5.2.2 Requête

**Headers** :
```http
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Body** :
```json
{
  "market_application": {
    "siret": "12345678901234"
  }
}
```

#### 5.2.3 Paramètres

| Champ | Type | Requis | Contraintes | Description |
|-------|------|--------|-------------|-------------|
| `market_identifier` | string | Oui | Format VR-YYYY-XXXX | Identifiant du marché |
| `siret` | string | Non | 14 chiffres, validation Luhn | SIRET de l'entreprise candidate |

**Note** : Le SIRET peut être omis à la création et fourni lors de l'étape d'identification.

#### 5.2.4 Réponse succès (201 Created)

```json
{
  "identifier": "FT20240615A1B2C3D4",
  "application_url": "https://passemarche.data.gouv.fr/candidate/market_applications/FT20240615A1B2C3D4/company_identification"
}
```

| Champ | Description |
|-------|-------------|
| `identifier` | Identifiant unique de la candidature (format: `FT` + date + hash) |
| `application_url` | URL vers l'interface de candidature |

### 5.3 Identification par SIRET

#### 5.3.1 Validation du SIRET

Le SIRET est validé selon les règles suivantes :

1. **Format** : Exactement 14 caractères numériques
2. **Algorithme de Luhn** : Validation du checksum
3. **Cas spécial La Poste** : Format `356000000XXXXX` (règle spécifique)

#### 5.3.2 Récupération automatique des données

Lors de la saisie du SIRET, Passe Marché interroge automatiquement les APIs gouvernementales pour pré-remplir les informations de l'entreprise :

| API | Données récupérées |
|-----|-------------------|
| INSEE | Dénomination, forme juridique, adresse, date création |
| RNE | Données du registre national des entreprises |
| DGFIP | Données financières (CA, résultats) |
| URSSAF | Attestation de vigilance |
| Qualibat | Qualifications BTP |
| Qualifelec | Qualifications électricité |
| OPQIBI | Qualifications ingénierie |
| RGE | Qualifications énergétiques |
| BODACC | Situation vis-à-vis des procédures collectives |

**[À COMPLÉTER]** : Détail des champs récupérés par chaque API.

### 5.4 Interface de candidature (Wizard dynamique)

Les étapes sont générées dynamiquement selon la configuration du marché par l'acheteur.

#### 5.4.1 Structure des étapes

```
company_identification → api_data_recovery_status → market_information
→ [catégories configurées] → summary
```

#### 5.4.2 Étapes fixes

| Étape | URL | Description |
|-------|-----|-------------|
| `company_identification` | `/candidate/market_applications/{id}/company_identification` | Saisie du SIRET |
| `api_data_recovery_status` | `/candidate/market_applications/{id}/api_data_recovery_status` | Statut récupération données |
| `market_information` | `/candidate/market_applications/{id}/market_information` | Informations du marché (lecture seule) |
| `summary` | `/candidate/market_applications/{id}/summary` | Récapitulatif et validation |

#### 5.4.3 Étapes dynamiques

Générées selon les catégories de champs configurées par l'acheteur :

- `capacite_economique_financiere`
- `capacite_technique_professionnelle`
- `attestations`
- `declarations`
- `documents`
- etc.

### 5.5 Types de champs de saisie

| Type | Description | Pièces jointes |
|------|-------------|----------------|
| `TextInput` | Champ texte simple | Non |
| `Textarea` | Zone de texte multiligne | Non |
| `EmailInput` | Adresse email (validation format) | Non |
| `PhoneInput` | Numéro de téléphone (validation format FR) | Non |
| `UrlInput` | URL (validation format) | Non |
| `FileUpload` | Upload de fichier simple | Oui |
| `InlineFileUpload` | Upload de fichier inline | Oui |
| `CheckboxWithDocument` | Case à cocher + document optionnel | Oui (conditionnel) |
| `RadioWithFileAndText` | Radio + fichier + texte | Oui |
| `FileOrTextarea` | Choix fichier OU texte | Oui (optionnel) |
| `PresentationIntervenants` | Champ répétable pour intervenants + CV | Oui |
| `RealisationsLivraisons` | Champ répétable pour références | Oui |
| `CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel` | CA sur 3 ans | Non |
| `CapaciteEconomiqueFinanciereEffectifsMoyensAnnuels` | Effectifs sur 3 ans | Non |

### 5.6 Formats de fichiers acceptés

| Type MIME | Extension | Description |
|-----------|-----------|-------------|
| `application/pdf` | .pdf | Document PDF |
| `image/jpeg` | .jpg, .jpeg | Image JPEG |
| `image/png` | .png | Image PNG |
| `image/gif` | .gif | Image GIF |
| `application/msword` | .doc | Document Word (legacy) |
| `application/vnd.openxmlformats-officedocument.wordprocessingml.document` | .docx | Document Word |
| `application/vnd.ms-excel` | .xls | Excel (legacy) |
| `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` | .xlsx | Excel |

### 5.7 Contraintes de fichiers

| Contrainte | Valeur |
|------------|--------|
| Taille maximale par fichier | 100 Mo |
| Longueur maximale du nom de fichier | 255 caractères |

### 5.8 Processus de complétion

Lors de la soumission finale à l'étape `summary` :

1. **Validation complète** : Vérification de tous les champs obligatoires
2. **Attestation d'exclusion** : Le candidat atteste ne pas être en situation d'exclusion
3. **Marquage complété** : `completed_at` est défini
4. **Génération PDF** : Attestation candidate et attestation acheteur
5. **Génération ZIP** : Dossier complet avec tous les documents
6. **Envoi webhook** : Notification à l'éditeur

### 5.9 Callback de retour

Après complétion, le candidat est redirigé vers :

```
{redirect_url}?market_identifier={market_id}&application_identifier={application_id}
```

**Exemple** :
```
https://editeur.com/callback?market_identifier=VR-2024-A1B2C3D4E5F6&application_identifier=FT20240615A1B2C3D4
```

---

## 6. Référence API

### 6.1 Base URL

| Environnement | Base URL |
|---------------|----------|
| Sandbox | `https://sandbox.passemarche.data.gouv.fr` |
| Staging | `https://staging.passemarche.data.gouv.fr` |
| Preprod | `https://preprod.passemarche.data.gouv.fr` |
| Production | `https://passemarche.data.gouv.fr` |

Tous les endpoints API sont préfixés par `/api/v1/`.

### 6.2 Format des réponses

- **Content-Type** : `application/json` (sauf téléchargements binaires)
- **Encoding** : UTF-8
- **Format des dates** : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)

### 6.3 Codes de statut HTTP

| Code | Signification | Description |
|------|---------------|-------------|
| 200 | OK | Requête réussie |
| 201 | Created | Ressource créée avec succès |
| 400 | Bad Request | Paramètres de requête invalides |
| 401 | Unauthorized | Token manquant ou invalide |
| 403 | Forbidden | Accès refusé |
| 404 | Not Found | Ressource non trouvée |
| 422 | Unprocessable Entity | Erreurs de validation |
| 429 | Too Many Requests | Rate limit dépassé |
| 500 | Internal Server Error | Erreur serveur |

### 6.4 Format des erreurs

**Erreur simple** :
```json
{
  "error": "Description de l'erreur"
}
```

**Erreurs multiples** :
```json
{
  "errors": [
    "Erreur 1",
    "Erreur 2"
  ]
}
```

**Erreurs par champ** :
```json
{
  "errors": {
    "siret": ["Le numéro de SIRET saisi est invalide"]
  }
}
```

### 6.5 Endpoints

#### 6.5.1 OAuth - Obtention du token

```
POST /oauth/token
```

Voir [section 3.3](#33-obtention-du-token-daccès) pour les détails.

#### 6.5.2 Marchés publics - Création

```
POST /api/v1/public_markets
```

Voir [section 4.2](#42-création-du-marché-public) pour les détails.

#### 6.5.3 Candidatures - Création

```
POST /api/v1/public_markets/{market_identifier}/market_applications
```

Voir [section 5.2](#52-création-de-la-candidature) pour les détails.

#### 6.5.4 Candidatures - Téléchargement attestation

```
GET /api/v1/market_applications/{identifier}/attestation
```

**Headers** :
```http
Authorization: Bearer {access_token}
```

**Conditions** :
- Candidature en statut `completed`
- Attestation générée et disponible
- Éditeur autorisé pour cette candidature

**Réponse succès (200 OK)** :
```http
Content-Type: application/pdf
Content-Disposition: attachment; filename="attestation_FT{identifier}.pdf"
```

**Erreurs** :
- 404 : Candidature non trouvée
- 422 : Candidature non finalisée
- 404 : Attestation non disponible

#### 6.5.5 Candidatures - Téléchargement dossier

```
GET /api/v1/market_applications/{identifier}/documents_package
```

**Headers** :
```http
Authorization: Bearer {access_token}
```

**Conditions** :
- Candidature en statut `completed`
- Dossier généré et disponible
- Éditeur autorisé pour cette candidature

**Réponse succès (200 OK)** :
```http
Content-Type: application/zip
Content-Disposition: attachment; filename="documents_package_FT{identifier}.zip"
```

**Erreurs** :
- 404 : Candidature non trouvée
- 422 : Candidature non finalisée
- 404 : Dossier non disponible

### 6.6 Rate limiting

| Catégorie | Limite |
|-----------|--------|
| Authentification | 60 requêtes/heure |
| API générale | 1000 requêtes/heure |
| Téléchargements | 100 requêtes/heure |

**Headers de réponse** :
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

**Réponse 429** :
```json
{
  "error": "Rate limit exceeded",
  "retry_after": 3600
}
```

---

## 7. Webhooks

### 7.1 Vue d'ensemble

Les webhooks permettent à Passe Marché de notifier l'éditeur en temps réel lors d'événements importants.

### 7.2 Configuration

Les webhooks sont configurés au niveau de l'éditeur par l'administrateur :

| Paramètre | Description |
|-----------|-------------|
| `completion_webhook_url` | URL de réception des webhooks |
| `webhook_secret` | Secret HMAC-SHA256 (64 caractères hex) |

### 7.3 Format des requêtes

**Headers** :
```http
POST {completion_webhook_url} HTTP/1.1
Content-Type: application/json
X-Webhook-Signature-SHA256: sha256={signature}
User-Agent: PasseMarche-Webhook/1.0
```

### 7.4 Événements

#### 7.4.1 market.completed

Déclenché lorsqu'un acheteur finalise la configuration d'un marché.

```json
{
  "event": "market.completed",
  "timestamp": "2024-06-15T14:30:45.123Z",
  "market": {
    "identifier": "VR-2024-A1B2C3D4E5F6",
    "name": "Fourniture de matériel informatique",
    "lot_name": "Lot 1 - Ordinateurs portables",
    "deadline": "2024-12-31T23:59:59.000Z",
    "market_type_codes": ["supplies", "services"],
    "completed_at": "2024-06-15T14:30:45.123Z",
    "field_keys": [
      "company_name",
      "siret",
      "legal_form",
      "turnover_year_n_minus_1"
    ]
  }
}
```

#### 7.4.2 market_application.completed

Déclenché lorsqu'un candidat finalise sa candidature.

```json
{
  "event": "market_application.completed",
  "timestamp": "2024-06-15T16:45:30.456Z",
  "market_identifier": "VR-2024-A1B2C3D4E5F6",
  "market_application": {
    "identifier": "FT20240615A1B2C3D4",
    "siret": "12345678901234",
    "company_name": "ACME Solutions SARL",
    "completed_at": "2024-06-15T16:45:30.456Z",
    "attestation_url": "https://passemarche.data.gouv.fr/api/v1/market_applications/FT20240615A1B2C3D4/attestation",
    "documents_package_url": "https://passemarche.data.gouv.fr/api/v1/market_applications/FT20240615A1B2C3D4/documents_package"
  }
}
```

### 7.5 Signature HMAC-SHA256

#### 7.5.1 Algorithme de signature

```
signature = HMAC-SHA256(webhook_secret, json_payload)
header_value = "sha256=" + hex(signature)
```

#### 7.5.2 Vérification côté récepteur

1. Extraire la signature de l'en-tête `X-Webhook-Signature-SHA256`
2. Supprimer le préfixe `sha256=`
3. Calculer `HMAC-SHA256(secret, body)` avec le body brut
4. Comparer les signatures de manière sécurisée (timing-safe comparison)
5. Rejeter si les signatures ne correspondent pas

**Exemple (pseudo-code)** :
```python
expected = hmac.new(secret, body, 'sha256').hexdigest()
received = header.replace('sha256=', '')
if not hmac.compare_digest(expected, received):
    return 401  # Unauthorized
```

### 7.6 Mécanisme de retry

#### 7.6.1 Configuration

| Paramètre | Valeur |
|-----------|--------|
| Tentatives maximales | 3 |
| Délais | Backoff polynomial (1s, 4s, 9s) |
| Timeout par tentative | 30 secondes |

#### 7.6.2 Codes de réponse et actions

| Code HTTP | Action |
|-----------|--------|
| 200-299 | Succès, pas de retry |
| 400, 401, 403, 404, 405, 410, 422 | Erreur permanente, pas de retry |
| 408, 429 | Retry avec délai |
| 500-599 | Retry avec délai |
| Timeout réseau | Retry avec délai |

### 7.7 Statuts de synchronisation

| Statut | Description |
|--------|-------------|
| `sync_pending` | En attente de traitement |
| `sync_processing` | Webhook en cours d'envoi |
| `sync_completed` | Webhook délivré avec succès |
| `sync_failed` | Tous les retries échoués |

### 7.8 Idempotence

Les webhooks peuvent être reçus plusieurs fois. L'éditeur doit implémenter une logique d'idempotence basée sur :

- `event` + `timestamp` + `identifier` de l'objet

**Recommandation** : Stocker les événements traités avec un TTL de 24h.

---

## 8. Gestion des documents

### 8.1 Documents générés

#### 8.1.1 Attestation candidat

**Nom de fichier** : `attestation_FT{identifier}.pdf`

**Contenu** :
- En-tête République Française
- Informations du marché public
- Informations de l'entreprise candidate
- Récapitulatif des informations saisies
- Horodatage de soumission
- Mention légale de certification

#### 8.1.2 Attestation acheteur

**Nom de fichier** : `buyer_attestation_FT{identifier}.pdf`

**Contenu** :
- En-tête République Française
- Informations du marché public
- Informations de l'entreprise candidate
- Récapitulatif complet pour l'acheteur
- Horodatage de soumission

### 8.2 Dossier documents (ZIP)

**Nom de fichier** : `documents_package_FT{identifier}.zip`

**Structure** :
```
documents_package_FT{identifier}.zip
├── buyer_attestation_FT{identifier}.pdf
└── documents/
    ├── api_01_01_{field_key}_{original_filename}.pdf
    ├── user_02_01_{field_key}_{original_filename}.pdf
    └── ...
```

### 8.3 Nomenclature des fichiers

**Format** : `{source}_{response_index}_{doc_index}_{field_key}_{original_filename}`

| Composant | Description |
|-----------|-------------|
| `source` | `api_` pour documents API, `user_` pour documents uploadés |
| `response_index` | Index de la réponse (01, 02, ...) |
| `doc_index` | Index du document dans la réponse (01, 02, ...) |
| `field_key` | Clé du champ de formulaire |
| `original_filename` | Nom original du fichier |

**Exemple** : `user_03_01_kbis_Kbis_Entreprise_2024.pdf`

### 8.4 Génération PDF

**Technologie** : WickedPDF (wkhtmltopdf)

**Format** :
- Taille : A4
- Marges : 20mm (haut/bas), 15mm (gauche/droite)
- Encodage : UTF-8

**Style** :
- Police : Marianne (DSFR)
- Couleur primaire : #000091 (Bleu France)

---

## 9. Sécurité et conformité

### 9.1 Exigences de sécurité

#### 9.1.1 Transport

- **HTTPS obligatoire** : Toutes les communications API et webhooks
- **TLS 1.2+** : Version minimale requise

#### 9.1.2 Authentification

- **OAuth2 Client Credentials** : Seul flux autorisé
- **Tokens de courte durée** : 24h maximum
- **Révocation automatique** : À chaque nouveau token

#### 9.1.3 Webhooks

- **Signature HMAC-SHA256** : Obligatoire pour tous les webhooks
- **Vérification côté récepteur** : Recommandée

### 9.2 Stockage des secrets

| Élément | Recommandation |
|---------|----------------|
| `client_secret` | Variables d'environnement, vault |
| `webhook_secret` | Variables d'environnement, vault |
| `access_token` | Mémoire uniquement, ne pas persister |

### 9.3 Conformité RGPD

**[À COMPLÉTER]** :
- Durée de conservation des données
- Procédure de suppression
- Transferts de données
- Droits des personnes concernées

### 9.4 Données personnelles traitées

| Catégorie | Données | Base légale |
|-----------|---------|-------------|
| Entreprise | SIRET, dénomination, adresse | Exécution contrat |
| Contact | Nom, email, téléphone | Exécution contrat |
| Documents | Fichiers uploadés | Exécution contrat |

**[À COMPLÉTER]** : Liste complète et durées de conservation.

---

## 10. Environnements

### 10.1 Tableau récapitulatif

| Environnement | URL | Données | Usage | Accès |
|---------------|-----|---------|-------|-------|
| **Sandbox** | sandbox.passemarche.data.gouv.fr | Simulées | Tests internes | Équipe PM |
| **Staging** | staging.passemarche.data.gouv.fr | Simulées | Intégration éditeurs | Éditeurs |
| **Preprod** | preprod.passemarche.data.gouv.fr | Réelles | Recette | Éditeurs autorisés |
| **Production** | passemarche.data.gouv.fr | Réelles | Production | Éditeurs validés |

### 10.2 Staging

**Cas d'usage** : Développement et tests d'intégration

**Caractéristiques** :
- Données API simulées (pas d'appels aux APIs réelles)
- Accès public pour les éditeurs
- Environnement de référence pour les tests

**Recommandation** : Utiliser cet environnement pour le développement initial de l'intégration.

### 10.3 Preprod

**Cas d'usage** : Tests de recette avec données réelles

**Caractéristiques** :
- Données API réelles
- Accès restreint (credentials spécifiques)
- Configuration iso-production

**Recommandation** : Valider l'intégration complète avant mise en production.

### 10.4 Production

**Cas d'usage** : Utilisation par les utilisateurs finaux

**Caractéristiques** :
- Données API réelles
- Haute disponibilité
- Monitoring et alerting

**Prérequis** :
- Validation complète en preprod
- Credentials production obtenus
- Webhook HTTPS configuré
- Monitoring côté éditeur en place

### 10.5 Configuration recommandée

```bash
# Variables d'environnement par environnement
export PASSEMARCHE_URL=https://{env}.passemarche.data.gouv.fr
export PASSEMARCHE_CLIENT_ID=your_client_id
export PASSEMARCHE_CLIENT_SECRET=your_client_secret
export PASSEMARCHE_WEBHOOK_SECRET=your_webhook_secret
```

---

## 11. Annexes

### 11.1 Exemples de code

#### 11.1.1 Authentification (cURL)

```bash
# Obtention du token
TOKEN=$(curl -s -X POST "${PASSEMARCHE_URL}/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${PASSEMARCHE_CLIENT_ID}" \
  -d "client_secret=${PASSEMARCHE_CLIENT_SECRET}" \
  -d "scope=api_access" \
  | jq -r '.access_token')

echo "Token: ${TOKEN:0:20}..."
```

#### 11.1.2 Création d'un marché (cURL)

```bash
curl -X POST "${PASSEMARCHE_URL}/api/v1/public_markets" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "public_market": {
      "name": "Fourniture de matériel informatique",
      "deadline": "2024-12-31T23:59:59Z",
      "siret": "13002526500013",
      "market_type_codes": ["supplies"]
    }
  }'
```

#### 11.1.3 Vérification signature webhook (Python)

```python
import hmac
import hashlib

def verify_webhook_signature(secret: str, payload: bytes, signature: str) -> bool:
    """Vérifie la signature HMAC-SHA256 d'un webhook."""
    expected = hmac.new(
        secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()

    received = signature.replace('sha256=', '')

    return hmac.compare_digest(expected, received)
```

#### 11.1.4 Vérification signature webhook (Ruby)

```ruby
def verify_webhook_signature(secret, payload, signature)
  expected = OpenSSL::HMAC.hexdigest('sha256', secret, payload)
  received = signature.sub('sha256=', '')

  ActiveSupport::SecurityUtils.secure_compare(expected, received)
end
```

### 11.2 Diagramme de séquence complet

```
┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐
│Éditeur │     │  API   │     │Acheteur│     │Candidat│     │Webhook │
│Backend │     │  PM    │     │        │     │        │     │Receiver│
└───┬────┘     └───┬────┘     └───┬────┘     └───┬────┘     └───┬────┘
    │              │              │              │              │
    │ POST /oauth/token          │              │              │
    │─────────────>│              │              │              │
    │ access_token │              │              │              │
    │<─────────────│              │              │              │
    │              │              │              │              │
    │ POST /api/v1/public_markets│              │              │
    │─────────────>│              │              │              │
    │ identifier   │              │              │              │
    │ config_url   │              │              │              │
    │<─────────────│              │              │              │
    │              │              │              │              │
    │    Redirect to config_url  │              │              │
    │─────────────────────────────>│              │              │
    │              │              │              │              │
    │              │ Configuration│              │              │
    │              │<─────────────│              │              │
    │              │              │              │              │
    │              │ POST webhook (market.completed)           │
    │              │────────────────────────────────────────────>│
    │              │              │              │              │
    │ POST /api/v1/.../market_applications      │              │
    │─────────────>│              │              │              │
    │ identifier   │              │              │              │
    │ app_url      │              │              │              │
    │<─────────────│              │              │              │
    │              │              │              │              │
    │    Redirect to app_url     │              │              │
    │─────────────────────────────────────────────>│              │
    │              │              │              │              │
    │              │ Saisie candidature         │              │
    │              │<─────────────────────────────│              │
    │              │              │              │              │
    │              │ POST webhook (application.completed)      │
    │              │────────────────────────────────────────────>│
    │              │              │              │              │
    │ GET /api/v1/.../attestation│              │              │
    │─────────────>│              │              │              │
    │ PDF binary   │              │              │              │
    │<─────────────│              │              │              │
    │              │              │              │              │
```

### 11.3 Checklist d'intégration

#### Phase 1 : Développement (Staging)

- [ ] Credentials staging obtenus
- [ ] Authentification OAuth2 implémentée
- [ ] Création de marchés testée
- [ ] Création de candidatures testée
- [ ] Webhooks reçus et signés vérifiés
- [ ] Téléchargement documents testé
- [ ] Gestion des erreurs implémentée

#### Phase 2 : Recette (Preprod)

- [ ] Credentials preprod obtenus
- [ ] Tests avec données réelles
- [ ] Performance validée
- [ ] Webhook HTTPS configuré
- [ ] Monitoring en place

#### Phase 3 : Production

- [ ] Credentials production obtenus
- [ ] Documentation utilisateur prête
- [ ] Support technique identifié
- [ ] Procédure de rollback documentée
- [ ] Validation finale

### 11.4 FAQ

**Q: Combien de temps un token est-il valide ?**
R: 24 heures. Renouvelez le token avant expiration.

**Q: Peut-on réutiliser un token révoqué ?**
R: Non. Une fois révoqué, le token ne peut plus être utilisé.

**Q: Les webhooks sont-ils garantis ?**
R: Non. En cas d'échec après 3 retries, le statut passe à `sync_failed`. Un retry manuel est possible.

**Q: Peut-on créer plusieurs candidatures pour le même SIRET ?**
R: **[À COMPLÉTER]** : Règle métier à préciser.

**Q: Quelle est la taille maximale d'un fichier ?**
R: 100 Mo par fichier.

**Q: Les données sont-elles chiffrées au repos ?**
R: **[À COMPLÉTER]** : Politique de chiffrement à préciser.

### 11.5 Contacts support technique

**[À COMPLÉTER]** :
- Email support :
- Documentation en ligne :
- Canal Mattermost/Slack :

---

## Historique des versions

| Version | Date | Auteur | Modifications |
|---------|------|--------|---------------|
| 1.0.0 | 2026-02-03 | Équipe PM | Version initiale |

---

*Document généré pour l'intégration des éditeurs de plateformes de marchés publics avec Passe Marché.*
