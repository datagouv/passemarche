# 05\_REFERENCE\_API

## Référence API - Passe Marché

### Vue d'ensemble

Cette référence technique détaille tous les endpoints disponibles dans l'API Passe Marché pour l'intégration des plateformes de marchés publics. L'API suit les standards REST avec authentification OAuth2.

### Base URL et Versioning

```
Version API: v1
```

| Environnement | Base URL                                   |
| ------------- | ------------------------------------------ |
| Sandbox       | `https://sandbox.passemarche.data.gouv.fr` |
| Staging       | `https://staging.passemarche.data.gouv.fr` |
| Preprod       | `https://preprod.passemarche.data.gouv.fr` |
| Production    | `https://passemarche.data.gouv.fr`         |

Tous les endpoints API sont préfixés par `/api/v1/`.

[**Documentation complète des environnements**](08_environnements.md)

### Authentification

Tous les endpoints API (sauf OAuth) requièrent un token d'accès valide dans l'en-tête `Authorization`.

```http
Authorization: Bearer {access_token}
```

Consultez la [Documentation OAuth](AUTHENTIFICATION_OAUTH.md) pour l'obtention du token.

### Format des Réponses

#### Réponses de Succès

* **Content-Type** : `application/json`
* **Encoding** : UTF-8
* **Format** : JSON structuré

#### Réponses d'Erreur

```json
{
  "error": "Description de l'erreur",
  "errors": ["Détail erreur 1", "Détail erreur 2"]
}
```

### Codes de Statut HTTP

| Code | Signification         | Description                       |
| ---- | --------------------- | --------------------------------- |
| 200  | OK                    | Requête réussie                   |
| 201  | Created               | Ressource créée avec succès       |
| 400  | Bad Request           | Paramètres de requête invalides   |
| 401  | Unauthorized          | Token manquant ou invalide        |
| 403  | Forbidden             | Accès refusé pour cette ressource |
| 404  | Not Found             | Ressource non trouvée             |
| 422  | Unprocessable Content | Erreurs de validation             |
| 429  | Too Many Requests     | Limite de taux dépassée           |
| 500  | Internal Server Error | Erreur serveur interne            |

***

## Endpoints OAuth

### Obtenir un Token d'Accès

Authentification via le flux OAuth2 Client Credentials.

#### `POST /oauth/token`

**Paramètres de Requête**

**En-têtes** :

```http
Content-Type: application/x-www-form-urlencoded
```

**Corps** (form-encoded) :

```
grant_type=client_credentials
client_id={votre_client_id}
client_secret={votre_client_secret}
scope=api_access
```

**Réponse de Succès (200)**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "scope": "api_access"
}
```

**Réponses d'Erreur**

**401 - Client invalide** :

```json
{
  "error": "invalid_client",
  "error_description": "Client authentication failed"
}
```

**401 - Éditeur non autorisé** :

```json
{
  "error": "invalid_client",
  "error_description": "Editor is not authorized or active"
}
```

**400 - Grant type invalide** :

```json
{
  "error": "unsupported_grant_type",
  "error_description": "The authorization grant type is not supported"
}
```

***

## Endpoints API Métier

### Gestion des Marchés Publics

#### Créer un Marché Public

Création d'un nouveau marché public par une plateforme de marchés publics autorisée.

**`POST /api/v1/public_markets`**

**En-têtes** :

```http
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Corps de Requête** :

```json
{
  "public_market": {
    "name": "Fourniture de matériel informatique",
    "lots": [
      {"name": "Lot 1 - Ordinateurs portables"},
      {"name": "Lot 2 - Serveurs et infrastructure"}
    ],
    "deadline": "2024-12-31T23:59:59Z",
    "siret": "13002526500013",
    "market_type_codes": ["supplies", "services"],
    "provider_user_id": "user-acheteur-42"
  }
}
```

**Paramètres**

| Champ               | Type     | Requis | Description                                                     | Contraintes                       |
| ------------------- | -------- | ------ | --------------------------------------------------------------- | --------------------------------- |
| `name`              | string   | Oui    | Nom du marché public                                            | Max 255 caractères                |
| `deadline`          | datetime | Oui    | Date limite candidature                                         | Format ISO 8601, futur            |
| `siret`             | string   | Oui    | SIRET de l'organisation publique (14 chiffres, validation Luhn) | Exactement 14 chiffres numériques |
| `market_type_codes` | array    | Oui    | Types de marché                                                 | Au moins 1 élément                |
| `lots`              | array    | Non    | Liste des lots du marché                                        | Chaque lot requiert un `name`     |
| `provider_user_id`  | string   | Non    | Identifiant de l'utilisateur côté éditeur (acheteur)            | Max 255 caractères                |

**Types de Marché Valides**

| Code       | Description                     |
| ---------- | ------------------------------- |
| `supplies` | Fournitures                     |
| `services` | Services                        |
| `works`    | Travaux                         |
| `defense`  | Défense (ne peut pas être seul) |

**Réponse de Succès (201)**

```json
{
  "identifier": "VR-2024-A1B2C3D4E5F6",
  "configuration_url": "${BASE_URL}/buyer/public_markets/VR-2024-A1B2C3D4E5F6/setup"
}
```

**Réponses d'Erreur**

**422 - Erreurs de validation** :

```json
{
  "errors": [
    "Name can't be blank",
    "Deadline can't be blank",
    "Market type codes can't be blank"
  ]
}
```

**422 - Type défense seul** :

```json
{
  "errors": [
    "Market type codes defense cannot be used alone"
  ]
}
```

**422 - SIRET invalide** :

```json
{
  "errors": {
    "siret": ["Le numéro de SIRET saisi est invalide ou non reconnu"]
  }
}
```

***

### Gestion des Candidatures

#### Créer une Candidature

Création d'une nouvelle candidature pour un marché public existant.

**`POST /api/v1/public_markets/{market_identifier}/market_applications`**

**En-têtes** :

```http
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Corps de Requête** :

```json
{
  "market_application": {
    "siret": "12345678901234",
    "provider_user_id": "user-candidat-7"
  }
}
```

**Paramètres**

| Paramètre           | Type   | Requis | Description                                          | Contraintes                 |
| ------------------- | ------ | ------ | ---------------------------------------------------- | --------------------------- |
| `market_identifier` | string | Oui    | Identifiant du marché                                | Format VR-YYYY-XXXXXXXXXXXX |
| `siret`             | string | Non    | SIRET de l'entreprise                                | 14 chiffres exactement      |
| `provider_user_id`  | string | Non    | Identifiant de l'utilisateur côté éditeur (candidat) | Max 255 caractères          |

**Note** : Le SIRET peut être omis à la création et fourni lors de l'étape d'identification.

**Réponse de Succès (201)**

```json
{
  "identifier": "FT20240615A1B2C3D4",
  "application_url": "${BASE_URL}/candidate/market_applications/FT20240615A1B2C3D4/company_identification"
}
```

**Réponses d'Erreur**

**404 - Marché non trouvé** :

```json
{
  "error": "Resource not found"
}
```

**403 - Marché non accessible** :

```json
{
  "error": "Forbidden"
}
```

**422 - SIRET invalide** :

```json
{
  "errors": [
    "Siret is invalid"
  ]
}
```

#### Télécharger l'Attestation

Téléchargement de l'attestation PDF d'une candidature finalisée.

**`GET /api/v1/market_applications/{identifier}/attestation`**

**En-têtes** :

```http
Authorization: Bearer {access_token}
```

**Paramètres**

| Paramètre    | Type   | Description                   |
| ------------ | ------ | ----------------------------- |
| `identifier` | string | Identifiant de la candidature |

**Conditions**

* Candidature en statut `completed`
* Attestation générée et disponible
* Éditeur autorisé pour cette candidature

**Réponse de Succès (200)**

```http
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Disposition: attachment; filename="attestation_FT20240615A1B2C3D4.pdf"
Content-Length: 245760

[Binary PDF content]
```

**Réponses d'Erreur**

**404 - Candidature non trouvée** :

```json
{
  "error": "Resource not found"
}
```

**422 - Candidature non finalisée** :

```json
{
  "error": "Application not completed"
}
```

**404 - Attestation non disponible** :

```json
{
  "error": "Attestation not available"
}
```

#### Télécharger le Dossier Complet

Téléchargement de l'archive ZIP contenant tous les documents de candidature.

**`GET /api/v1/market_applications/{identifier}/documents_package`**

**En-têtes** :

```http
Authorization: Bearer {access_token}
```

**Paramètres**

| Paramètre    | Type   | Description                   |
| ------------ | ------ | ----------------------------- |
| `identifier` | string | Identifiant de la candidature |

**Conditions**

* Candidature en statut `completed`
* Archive générée et disponible
* Éditeur autorisé pour cette candidature

**Réponse de Succès (200)**

```http
HTTP/1.1 200 OK
Content-Type: application/zip
Content-Disposition: attachment; filename="documents_package_FT20240615A1B2C3D4.zip"
Content-Length: 1048576

[Binary ZIP content]
```

**Réponses d'Erreur**

**404 - Candidature non trouvée** :

```json
{
  "error": "Resource not found"
}
```

**422 - Candidature non finalisée** :

```json
{
  "error": "Application not completed"
}
```

**404 - Dossier non disponible** :

```json
{
  "error": "Documents package not available"
}
```

***

## Gestion des Erreurs Avancées

### Types d'Erreur par Endpoint

#### Erreurs d'Authentification

**Token manquant** :

```json
{
  "error": "Not authorized"
}
```

**Token expiré** :

```json
{
  "error": "Not authorized"
}
```

**Scope insuffisant** :

```json
{
  "error": "Forbidden"
}
```

#### Erreurs de Validation

**Format de date invalide** :

```json
{
  "errors": [
    "Deadline must be a valid ISO 8601 datetime"
  ]
}
```

**Valeur trop longue** :

```json
{
  "errors": [
    "Name is too long (maximum is 255 characters)"
  ]
}
```

**Valeur manquante** :

```json
{
  "errors": [
    "Name can't be blank"
  ]
}
```

#### Erreurs Métier

**Date limite passée** :

```json
{
  "errors": [
    "Deadline must be in the future"
  ]
}
```

**Marché déjà finalisé** :

```json
{
  "error": "Market is already completed"
}
```

**Candidature déjà existante** :

```json
{
  "errors": [
    "Application already exists for this SIRET"
  ]
}
```

### Gestion des Timeouts

#### Timeouts par Défaut

* **Connexion** : 30 secondes
* **Lecture** : 60 secondes
* **Téléchargement** : 300 secondes (5 minutes)

#### Recommandations Clients

**Recommandations techniques** :

* Utiliser des timeouts adaptés (30s standard, 300s téléchargements)
* Implémenter une stratégie de retry avec backoff exponentiel
* Gérer les codes d'erreur non récupérables (400, 401, 403)
* Logger les erreurs pour débogage

**🔗 Configuration avancée** : [Scripts de Référence - Client curl avec retry](99_scripts_reference.md#client-curl-avec-retry)

### Limitation de Taux (Rate Limiting)

#### Limites par Platforme de marchés publics

* **Authentification** : 60 requêtes/heure
* **API générale** : 1000 requêtes/heure
* **Téléchargements** : 100 requêtes/heure

#### En-têtes de Réponse

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

#### Réponse Limite Dépassée (429)

```json
{
  "error": "Rate limit exceeded",
  "retry_after": 3600
}
```

***

## Exemples d'Utilisation Complète

### Scripts d'Intégration

**Fonctionnalités disponibles** :

* **Workflow complet** : Création marché → configuration → candidature → téléchargement
* **Gestion d'erreurs robuste** : Analyse automatique des codes HTTP avec actions suggérées
* **Retry intelligent** : Backoff exponentiel avec gestion des erreurs non-récupérables
* **Logging structuré** : Traçabilité complète des appels API

**🔗 Scripts complets** : [Scripts de Référence - Workflows et gestion d'erreurs](99_scripts_reference.md#workflows-api)

Cette référence API fournit tous les détails techniques nécessaires pour une intégration complète et robuste avec l'API Passe Marché.
