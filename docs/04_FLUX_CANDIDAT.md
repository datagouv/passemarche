# Flux Candidat - Soumission des Candidatures

## Vue d'ensemble

Le flux candidat dans Voie Rapide permet aux éditeurs de créer des candidatures pour leurs entreprises utilisatrices, puis de les rediriger vers une interface dédiée pour compléter leur dossier de candidature. Ce processus garantit la conformité réglementaire tout en simplifiant l'expérience utilisateur.

## Architecture du Flux

```
┌─────────────────┐    1. Token d'accès      ┌─────────────────┐
│   Plateforme    │ ◄────────────────────────│   Authentification │
│   Éditeur       │                          │   OAuth2           │
└─────────────────┘                          └─────────────────┘

┌─────────────────┐    2. Création candidature ┌─────────────────┐
│   Plateforme    │ ──────────────────────────▶│   API Voie      │
│   Éditeur       │◄────────────────────────── │   Rapide        │
└─────────────────┘    3. URL candidature     └─────────────────┘

┌─────────────────┐    4. Redirection         ┌─────────────────┐
│   Candidat      │ ──────────────────────────▶│   Interface     │
│   Entreprise    │◄────────────────────────── │   Candidature   │
└─────────────────┘    5. Formulaire dynamique└─────────────────┘

┌─────────────────┐    6. Finalisation        ┌─────────────────┐
│   Candidat      │ ──────────────────────────▶│   Génération    │
│   Entreprise    │◄────────────────────────── │   Documents     │
└─────────────────┘    7. Attestation/Dossier └─────────────────┘

┌─────────────────┐    8. Notification        ┌─────────────────┐
│   Plateforme    │ ◄────────────────────────  │   Webhook       │
│   Éditeur       │                          │   Complétion    │
└─────────────────┘                          └─────────────────┘
```

## Étapes Détaillées du Flux

### 1. Prérequis d'Authentification

**Token OAuth requis** : Token d'accès valide obtenu via le flux Client Credentials.

Consultez la [Documentation OAuth](AUTHENTIFICATION_OAUTH.md) pour l'implémentation.

### 2. Création de la Candidature

#### Endpoint
`POST /api/v1/public_markets/{market_identifier}/market_applications`

#### Requête
```http
POST /api/v1/public_markets/VR-2024-A1B2C3D4E5F6/market_applications HTTP/1.1
Host: voie-rapide.gouv.fr
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "market_application": {
    "siret": "12345678901234"
  }
}
```

#### Paramètres

| Champ | Type | Description | Contraintes |
|-------|------|-------------|-------------|
| `market_identifier` | string | Identifiant du marché public | Requis, format VR-YYYY-XXXXXXXXXXXX |
| `siret` | string | Numéro SIRET de l'entreprise | Optionnel à la création, 14 chiffres |

**Note importante** : Le SIRET peut être fourni à la création ou lors de l'étape d'identification dans l'interface candidat.

#### Réponse de Succès (201 Created)

```json
{
  "identifier": "FT20240615A1B2C3D4",
  "application_url": "https://voie-rapide.gouv.fr/candidate/market_applications/FT20240615A1B2C3D4/company_identification"
}
```

**Paramètres de Réponse** :
- `identifier` : Identifiant unique de la candidature (format FT + date + hash)
- `application_url` : URL vers l'interface de candidature

#### Réponses d'Erreur

**Marché non trouvé (404)** :
```json
{
  "error": "Resource not found"
}
```

**Marché non accessible par l'éditeur (403)** :
```json
{
  "error": "Forbidden"
}
```

**SIRET invalide si fourni (422)** :
```json
{
  "errors": [
    "Siret is invalid (must be 14 digits)"
  ]
}
```

### 3. Interface de Candidature

L'éditeur redirige l'entreprise vers l'URL fournie. L'interface s'adapte dynamiquement selon la configuration du marché public.

#### Génération Dynamique des Étapes

Les étapes sont générées automatiquement selon les champs configurés par l'acheteur :

```
company_identification → [catégories_configurées] → summary
```

**Exemple pour un marché "supplies + services"** :
```
company_identification → capacite_economique_financiere →
capacite_technique_professionnelle → summary
```

#### Étape 1 : Identification Entreprise
- **URL** : `/candidate/market_applications/{identifier}/company_identification`
- **Objectif** : Validation de l'identité de l'entreprise
- **Champs** :
  - SIRET (si non fourni à la création)
  - Nom de l'entreprise
  - Forme juridique
  - Adresse du siège social

#### Étapes Intermédiaires : Champs Métier
Chaque catégorie configurée par l'acheteur génère une étape :

**Capacité Économique et Financière** :
- Chiffre d'affaires des 3 dernières années
- Résultat net
- Capitaux propres
- Ratios financiers

**Capacité Technique et Professionnelle** :
- Effectifs
- Encadrement technique
- Certifications
- Références clients

**Autres Catégories** (selon configuration) :
- Assurances
- Sous-traitance
- Développement durable
- Innovation

#### Étape Finale : Résumé et Validation
- **URL** : `/candidate/market_applications/{identifier}/summary`
- **Objectif** : Validation finale et soumission
- **Actions** :
  - Récapitulatif de toutes les informations
  - Vérification de cohérence
  - Confirmation de soumission

### 4. Processus de Complétion

#### Validation et Génération

Lors de la soumission finale :

1. **Validation des Données** : Vérification de la cohérence et complétude
2. **Marquage Complété** : Passage en statut `completed`
3. **Génération de l'Attestation** : PDF officiel avec horodatage
4. **Création du Dossier** : Archive ZIP avec tous les éléments
5. **Déclenchement Webhook** : Notification vers l'éditeur

#### Types de Documents Générés

**Attestation PDF** :
- Document officiel de soumission
- Horodatage légal
- Résumé des informations clés
- QR code de vérification

**Dossier Documents ZIP** :
- Attestation acheteur (PDF officiel)
- Documents des candidats issus de tous les types de champs permettant l'attachement de fichiers :
  - `FileUpload` : Fichiers téléchargés standard
  - `InlineFileUpload` : Fichiers téléchargés en ligne
  - `CheckboxWithDocument` : Fichiers conditionnels aux cases à cocher
  - `RadioWithFileAndText` : Fichiers avec sélection radio
  - `RadioWithJustificationRequired` : Justifications obligatoires
  - `RadioWithJustificationOptional` : Justifications optionnelles
  - `FileOrTextarea` : Fichiers ou texte
  - `PresentationIntervenants` : CV des intervenants
  - `RealisationsLivraisons` : Attestations de réalisations
  - `CapacitesTechniquesProfessionnellesOutillageEchantillons` : Échantillons et outillage
- Nom de fichiers structuré : `{index_réponse}_{index_document}_{clé_champ}_{nom_original}`
- Exemple : `01_01_kbis_Kbis_Entreprise.pdf`

### 5. Statuts de la Candidature

| Statut | Description | Actions Disponibles |
|--------|-------------|---------------------|
| `pending` | En cours de saisie | Modification, progression |
| `completed` | Finalisée et validée | Consultation, téléchargement |
| `sync_pending` | Attente notification | - |
| `sync_processing` | Webhook en cours | - |
| `sync_completed` | Notification réussie | - |
| `sync_failed` | Échec notification | Retry disponible |

### 6. Webhook de Complétion

#### Déclenchement Automatique

Le webhook est envoyé automatiquement lors de la finalisation de la candidature.

#### Payload du Webhook

```json
{
  "event": "market_application.completed",
  "timestamp": "2024-06-15T16:45:30Z",
  "market_identifier": "VR-2024-A1B2C3D4E5F6",
  "market_application": {
    "identifier": "FT20240615A1B2C3D4",
    "siret": "12345678901234",
    "company_name": "ACME Solutions SARL",
    "completed_at": "2024-06-15T16:45:30Z",
    "attestation_url": "https://voie-rapide.gouv.fr/api/v1/market_applications/FT20240615A1B2C3D4/attestation",
    "documents_package_url": "https://voie-rapide.gouv.fr/api/v1/market_applications/FT20240615A1B2C3D4/documents_package"
  }
}
```

#### Paramètres du Payload

| Champ | Description |
|-------|-------------|
| `event` | Type d'événement (`market_application.completed`) |
| `market_identifier` | Identifiant du marché public |
| `market_application.identifier` | Identifiant de la candidature |
| `market_application.siret` | SIRET de l'entreprise candidate |
| `market_application.attestation_url` | URL de téléchargement de l'attestation |
| `market_application.documents_package_url` | URL de téléchargement du dossier |

### 7. Téléchargement des Documents

Une fois la candidature finalisée, l'éditeur peut télécharger les documents générés.

#### Téléchargement de l'Attestation

**Endpoint** : `GET /api/v1/market_applications/{identifier}/attestation`

```http
GET /api/v1/market_applications/FT20240615A1B2C3D4/attestation HTTP/1.1
Host: voie-rapide.gouv.fr
Authorization: Bearer {access_token}
```

**Réponse** : Fichier PDF en binaire
```http
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Disposition: attachment; filename="attestation_FT20240615A1B2C3D4.pdf"
Content-Length: 245760

[Binary PDF content]
```

#### Téléchargement du Dossier Complet

**Endpoint** : `GET /api/v1/market_applications/{identifier}/documents_package`

```http
GET /api/v1/market_applications/FT20240615A1B2C3D4/documents_package HTTP/1.1
Host: voie-rapide.gouv.fr
Authorization: Bearer {access_token}
```

**Réponse** : Archive ZIP en binaire
```http
HTTP/1.1 200 OK
Content-Type: application/zip
Content-Disposition: attachment; filename="documents_package_FT20240615A1B2C3D4.zip"
Content-Length: 1048576

[Binary ZIP content]
```

#### Conditions de Téléchargement

- Candidature en statut `completed`
- Token d'accès valide de l'éditeur propriétaire
- Documents générés et disponibles

#### Réponses d'Erreur pour Téléchargement

**Candidature non finalisée (422)** :
```json
{
  "error": "Application not completed"
}
```

**Document non disponible (404)** :
```json
{
  "error": "Attestation not available"
}
```

## Champs de Candidature Dynamiques

### Types de Champs Supportés

#### Champs de Base
- **Texte libre** : Descriptions, commentaires
- **Nombre entier** : Effectifs, quantités
- **Nombre décimal** : Montants, ratios
- **Date** : Échéances, créations
- **Oui/Non** : Certifications, capacités
- **Choix unique** : Sélection dans une liste
- **Choix multiple** : Sélections multiples

#### Champs Composites Métier
- **Chiffre d'affaires annuel** : 3 années + pourcentages marché
- **Références client** : Nom, montant, période, contact
- **Assurances** : Compagnie, garantie, montant, période
- **Certifications** : Organisme, norme, validité

### Validation des Données

#### Validation Frontend
- Contrôles en temps réel
- Messages d'erreur contextuels
- Prévention de soumission incomplète

#### Validation Backend
- Vérification de cohérence
- Validation métier (SIRET, dates)
- Contrôles d'intégrité

### Exemple de Champ Composite : Chiffre d'Affaires

```json
{
  "field_type": "capacite_economique_financiere_chiffre_affaires_global_annuel",
  "value": {
    "year_1": {
      "turnover": 1500000,
      "market_percentage": 75,
      "fiscal_year_end": "2023-12-31"
    },
    "year_2": {
      "turnover": 1350000,
      "market_percentage": 80,
      "fiscal_year_end": "2022-12-31"
    },
    "year_3": {
      "turnover": 1200000,
      "market_percentage": 70,
      "fiscal_year_end": "2021-12-31"
    }
  }
}
```

## Gestion des Erreurs et Cas Limites

### Candidature Déjà Finalisée
- Redirection vers page de statut
- Affichage des informations de complétion
- Liens de téléchargement si disponibles

### Session Expirée
- Sauvegarde automatique de la progression
- Reprise à la dernière étape validée
- Conservation des données 7 jours

### Erreurs de Validation
- Messages d'erreur détaillés par champ
- Préservation des données saisies
- Navigation facilitée vers les erreurs

### Marché Expiré
- Vérification de la date limite
- Blocage de soumission si dépassée
- Message informatif avec détails

## Monitoring et Observabilité

### Métriques de Performance
- **Taux de complétion** : Candidatures démarrées vs finalisées
- **Temps de saisie** : Durée moyenne par étape
- **Taux d'abandon** : Abandons par étape et raison
- **Erreurs de validation** : Fréquence par type de champ

### Logs Applicatifs

**Éléments recommandés à logger** :
- Création de candidatures (identifiant, marché, SIRET)
- Webhooks reçus (événement, statut, documents disponibles)
- Téléchargements de documents (type, taille)
- Erreurs de validation et d'API

**🔗 Scripts de logging** : [Scripts de Référence - Logging candidatures](99_SCRIPTS_REFERENCE.md#logging-candidatures)

## Bonnes Pratiques d'Intégration

### Côté Éditeur

1. **Validation Préalable** : Vérifier la validité du marché avant création
2. **Gestion du SIRET** : Permettre saisie ultérieure si non disponible
3. **Webhook Idempotent** : Gérer les réceptions multiples du même événement
4. **Stockage Sécurisé** : Protéger les URLs de téléchargement
5. **UX Cohérente** : Intégrer harmonieusement les redirections

### Scripts d'Automatisation

**Fonctionnalités disponibles** :
- Gestionnaire complet de candidatures (création, webhooks, téléchargements)
- Cache local des candidatures créées
- Gestion d'erreurs et logging détaillé
- Téléchargement automatique des documents (PDF/ZIP)
- Statistiques et monitoring des opérations

**🔗 Scripts complets** : [Scripts de Référence - Gestionnaire de candidatures](99_SCRIPTS_REFERENCE.md#gestionnaire-de-candidatures---script-complet)

Ce flux candidat assure une expérience utilisateur optimisée tout en maintenant la conformité réglementaire et la traçabilité requises pour les marchés publics.