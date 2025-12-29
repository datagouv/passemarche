# Flux Acheteur - Configuration des Marchés Publics

## Vue d'ensemble

Le flux acheteur dans Passe Marché permet aux éditeurs de créer et configurer des marchés publics via API, puis de rediriger les acheteurs vers une interface dédiée pour finaliser la configuration. Ce processus garantit une expérience utilisateur optimale tout en maintenant le contrôle technique via API.

## Environnements

Les exemples de ce document utilisent `${BASE_URL}` comme placeholder. Consultez la [documentation des environnements](08_ENVIRONNEMENTS.md) pour les URLs spécifiques à chaque environnement.

## Architecture du Flux

```
┌─────────────────┐    1. Authentification   ┌─────────────────┐
│   Plateforme    │ ────────────────────────▶│   Passe Marché  │
│   Éditeur       │◄──────────────────────── │   API OAuth     │
└─────────────────┘    2. Token d'accès      └─────────────────┘

┌─────────────────┐    3. Création marché    ┌─────────────────┐
│   Plateforme    │ ────────────────────────▶│   Passe Marché  │
│   Éditeur       │◄──────────────────────── │   API           │
└─────────────────┘    4. URL config         └─────────────────┘

┌─────────────────┐    5. Redirection        ┌─────────────────┐
│   Acheteur      │ ────────────────────────▶│   Interface     │
│   Public        │◄──────────────────────── │   Configuration │
└─────────────────┘    6. Configuration      └─────────────────┘

┌─────────────────┐    7. Notification       ┌─────────────────┐
│   Plateforme    │ ◄────────────────────────│   Webhook       │
│   Éditeur       │                          │   Complétion    │
└─────────────────┘                          └─────────────────┘
```

## Étapes Détaillées du Flux

### 1. Authentification OAuth

**Prérequis** : Token d'accès valide obtenu via le flux OAuth2 Client Credentials.

Consultez la [Documentation OAuth](AUTHENTIFICATION_OAUTH.md) pour les détails d'implémentation.

### 2. Création du Marché Public

#### Endpoint
`POST /api/v1/public_markets`

#### Requête
```http
POST /api/v1/public_markets HTTP/1.1
Host: ${BASE_URL}
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "public_market": {
    "name": "Fourniture de matériel informatique pour les services municipaux",
    "lot_name": "Lot 1 - Ordinateurs portables et stations de travail",
    "deadline": "2024-06-15T23:59:59Z",
    "siret": "13002526500013",
    "market_type_codes": ["supplies", "services"]
  }
}
```

#### Paramètres Requis

| Champ | Type | Description | Contraintes |
|-------|------|-------------|-------------|
| `name` | string | Nom du marché public | Requis, max 255 caractères |
| `deadline` | datetime | Date limite de candidature | Requis, format ISO 8601 |
| `siret` | string | SIRET de l'organisation publique | Requis, exactement 14 chiffres, validation Luhn |
| `market_type_codes` | array | Types de marché | Requis, minimum 1 élément |
| `lot_name` | string | Nom du lot spécifique | Optionnel, max 255 caractères |

#### Codes de Types de Marché

| Code | Description | Utilisation |
|------|-------------|-------------|
| `supplies` | Fournitures | Biens matériels, consommables |
| `services` | Services | Prestations intellectuelles, maintenance |
| `works` | Travaux | Construction, rénovation, BTP |
| `defense` | Défense | Marchés liés à la défense nationale |

**Note** : Le type `defense` ne peut pas être utilisé seul et doit être combiné avec un autre type.

#### Réponse de Succès (201 Created)

```json
{
  "identifier": "VR-2024-A1B2C3D4E5F6",
  "configuration_url": "${BASE_URL}/buyer/public_markets/VR-2024-A1B2C3D4E5F6/setup"
}
```

**Paramètres de Réponse** :
- `identifier` : Identifiant unique du marché (format VR-YYYY-XXXXXXXXXXXX)
- `configuration_url` : URL vers l'interface de configuration

#### Réponses d'Erreur

**Paramètres manquants (422)** :
```json
{
  "errors": [
    "Name can't be blank",
    "Deadline can't be blank",
    "Market type codes can't be blank"
  ]
}
```

**Types de marché invalides (422)** :
```json
{
  "errors": [
    "Market type codes defense cannot be used alone"
  ]
}
```

**Éditeur non autorisé (403)** :
```json
{
  "error": "Forbidden"
}
```

### 3. Interface de Configuration

Une fois le marché créé, l'éditeur redirige l'acheteur vers l'URL fournie dans la réponse. L'interface de configuration suit un processus en 4 étapes :

#### Étape 1 : Setup Initial
- **URL** : `/buyer/public_markets/{identifier}/setup`
- **Objectif** : Configuration initiale et validation des informations
- **Actions** :
  - Vérification de l'identifiant marché
  - Ajout optionnel du type "defense" si pertinent
  - Affichage des informations de base du marché (incluant le SIRET de l'organisation publique)

**Note** : Le SIRET de l'organisation publique est requis pour la conformité avec l'API Entreprise

#### Étape 2 : Champs Obligatoires
- **URL** : `/buyer/public_markets/{identifier}/required_fields`
- **Objectif** : Sélection et configuration des champs obligatoires
- **Logique** :
  - Génération automatique des champs selon les types de marché
  - Prise en compte du contexte défense/civil
  - Groupement par catégories et sous-catégories

#### Étape 3 : Champs Optionnels
- **URL** : `/buyer/public_markets/{identifier}/additional_fields`
- **Objectif** : Sélection des champs optionnels complémentaires
- **Fonctionnalités** :
  - Filtrage des champs selon la configuration existante
  - Organisation par domaines métier
  - Aperçu des champs sélectionnés

#### Étape 4 : Résumé et Finalisation
- **URL** : `/buyer/public_markets/{identifier}/summary`
- **Objectif** : Validation finale et complétion du marché
- **Actions** :
  - Affichage de tous les champs configurés
  - Confirmation de la configuration
  - Déclenchement du processus de complétion

### 4. Processus de Complétion

#### Finalisation Automatique

Lorsque l'acheteur confirme la configuration à l'étape "Résumé" :

1. **Marquage comme complété** : Le marché passe en statut `completed`
2. **Génération de l'identifiant** : Attribution d'un identifiant unique stable
3. **Sauvegarde de la configuration** : Snapshot des champs sélectionnés
4. **Initialisation du webhook** : Préparation de la notification

#### Statuts de Synchronisation

| Statut | Description | Action |
|--------|-------------|---------|
| `sync_pending` | En attente de traitement | Webhook en file d'attente |
| `sync_processing` | Traitement en cours | Webhook en cours d'envoi |
| `sync_completed` | Synchronisation réussie | Webhook délivré avec succès |
| `sync_failed` | Échec de synchronisation | Webhook échoué, retry programmé |

### 5. Webhook de Complétion

#### Déclenchement

Le webhook est automatiquement déclenché lors de la finalisation du marché et envoyé à l'URL configurée pour votre éditeur.

#### Payload du Webhook

```json
{
  "event": "market.completed",
  "timestamp": "2024-06-15T14:30:45Z",
  "market": {
    "identifier": "VR-2024-A1B2C3D4E5F6",
    "name": "Fourniture de matériel informatique pour les services municipaux",
    "lot_name": "Lot 1 - Ordinateurs portables et stations de travail",
    "deadline": "2024-06-15T23:59:59Z",
    "market_type_codes": ["supplies", "services"],
    "completed_at": "2024-06-15T14:30:45Z",
    "field_keys": [
      "company_name",
      "siret",
      "legal_form",
      "turnover_year_n_minus_1",
      "employee_count",
      "certifications_iso"
    ]
  }
}
```

#### Paramètres du Payload

| Champ | Description |
|-------|-------------|
| `event` | Type d'événement (`market.completed`) |
| `timestamp` | Horodatage ISO 8601 de l'événement |
| `market.identifier` | Identifiant unique du marché |
| `market.field_keys` | Liste des clés des champs configurés |
| `market.completed_at` | Date/heure de complétion |

#### Sécurité du Webhook

Chaque webhook inclut une signature HMAC-SHA256 dans l'en-tête `X-Webhook-Signature-SHA256`.

Consultez la [Documentation Webhooks](WEBHOOKS.md) pour les détails de vérification.

## Gestion des Erreurs et Edge Cases

### Marché Déjà Complété

Si un utilisateur tente d'accéder à un marché déjà complété :
- Redirection vers une page de statut
- Affichage des informations de complétion
- Option de retry de synchronisation si échec webhook

### Session Expirée

- Sauvegarde automatique de la progression
- Possibilité de reprendre à l'étape interrompue
- Conservation des données pendant 24h

### Erreurs de Validation

- Messages d'erreur contextuels par champ
- Préservation des données saisies
- Indication claire des corrections requises

## Surveillance et Monitoring

### Métriques Clés

- **Taux de conversion** : Marchés créés vs complétés
- **Temps de configuration** : Durée moyenne par étape
- **Taux d'abandon** : Abandons par étape
- **Succès webhook** : Pourcentage de webhooks délivrés

### Logs Recommandés

**Éléments à logger** :

- Création de marchés (nom, identifiant, statut HTTP)
- Webhooks reçus (événement, identifiant marché, nombre de champs)
- Erreurs d'API (codes HTTP, messages d'erreur)
- Temps de réponse des appels API

**Format recommandé** : JSON structuré avec timestamps ISO pour faciliter l'analyse.

**🔗 Scripts de logging** : [Scripts de Référence - Logging et monitoring](99_SCRIPTS_REFERENCE.md#logging-et-monitoring)

## Interface de Retry

En cas d'échec de synchronisation, une interface de retry est disponible :

### Endpoint de Retry
`POST /buyer/public_markets/{identifier}/retry_sync`

### Conditions d'Utilisation
- Marché en statut `sync_failed`
- Éditeur autorisé pour ce marché
- Limite : 3 tentatives par heure

## Bonnes Pratiques d'Intégration

### Côté Éditeur

1. **Validation Préalable** : Vérifier les données avant envoi API
2. **Gestion d'État** : Suivre le statut des marchés créés
3. **Webhook Robuste** : Implémenter une réception idempotente
4. **Monitoring** : Surveiller les taux de succès et les erreurs
5. **UX Cohérente** : Intégrer harmonieusement la redirection

### Scripts d'Automatisation

**Fonctionnalités disponibles** :
- Gestionnaire complet de marchés (création, listing, détails)
- Validation automatique des données
- Cache local des marchés créés
- Test de webhooks avec signature HMAC
- Gestion d'erreurs et retry intelligent
- Statistiques et monitoring

**🔗 Scripts complets** : [Scripts de Référence - Gestionnaire de marchés](99_SCRIPTS_REFERENCE.md#gestionnaire-de-marchés---script-complet)

Ce flux acheteur garantit une expérience optimale tout en maintenant le contrôle technique et la traçabilité nécessaires pour les marchés publics.
