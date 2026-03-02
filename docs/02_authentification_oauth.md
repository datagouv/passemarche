# Authentification OAuth2 - Passe Marché

## Vue d'ensemble

Passe Marché utilise le protocole OAuth2 avec le flux **Client Credentials** pour l'authentification des plateformes de marchés publics. Cette méthode garantit une communication sécurisée et standardisée entre votre plateforme et l'API Passe Marché.

## Environnements

Les exemples de ce document utilisent la variable `$BASE_URL`. Consultez la [documentation des environnements](08_environnements.md) pour les URLs spécifiques :

| Environnement | Base URL                                   |
| ------------- | ------------------------------------------ |
| Staging       | `https://staging.passemarche.data.gouv.fr` |
| Production    | `https://passemarche.data.gouv.fr`         |

## Prérequis d'Intégration

### Enregistrement plateforme de marchés publics

**Important** : L'enregistrement d'une plateforme de marchés publics doit être effectué manuellement par un administrateur Passe Marché pour des raisons de sécurité et de contrôle d'accès.

#### Processus d'Enregistrement

1. **Demande d'Intégration**
   * Contactez l'équipe Passe Marché
   * Fournissez les informations de votre plateforme
   * Décrivez votre cas d'usage
2. **Configuration Administrateur** L'administrateur créera votre compte éditeur avec :
   * **Nom éditeur** : Identifiant unique de votre plateforme
   * **Client ID** : Identifiant OAuth2 unique
   * **Client Secret** : Clé secrète OAuth2
   * **Statut autorisé** : `authorized: true`
   * **Statut actif** : `active: true`
   * **URL webhook** (optionnel) : Pour recevoir les notifications
   * **URL redirection** (optionnel) : Retour après complétion
3.  **Réception des Identifiants** Vous recevrez de manière sécurisée :

    ```json
    {
      "client_id": "votre_client_id_unique",
      "client_secret": "votre_cle_secrete",
      "webhook_secret": "secret_hmac_genere"
    }
    ```

## Spécifications OAuth2

### Flux Client Credentials

#### Obtention du Token d'Accès

**Endpoint** : `POST /oauth/token`

**En-têtes Requis** :

```http
Content-Type: application/x-www-form-urlencoded
```

**Corps de la Requête** :

```
grant_type=client_credentials
client_id={votre_client_id}
client_secret={votre_client_secret}
scope=api_access
```

**Exemple cURL** :

```bash
curl -X POST "${BASE_URL}/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api_access"
```

#### Réponse de Succès

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "scope": "api_access"
}
```

**Paramètres de Réponse** :

* `access_token` : Token JWT à utiliser pour les appels API
* `token_type` : Toujours "Bearer"
* `expires_in` : Durée de validité en secondes (24 heures)
* `scope` : Permissions accordées

#### Réponses d'Erreur

**Client invalide (401)** :

```json
{
  "error": "invalid_client",
  "error_description": "Client authentication failed"
}
```

**Éditeur non autorisé (401)** :

```json
{
  "error": "invalid_client",
  "error_description": "Editor is not authorized or active"
}
```

**Grant type non supporté (400)** :

```json
{
  "error": "unsupported_grant_type",
  "error_description": "The grant type is not supported"
}
```

### Utilisation du Token

#### En-tête d'Authentification

Incluez le token dans toutes les requêtes API :

```http
Authorization: Bearer {votre_access_token}
```

#### Gestion du Cycle de Vie

**Caractéristiques** :

* **Durée de vie** : 24 heures exactement
* **Révocation automatique** : L'ancien token est révoqué lors de l'émission d'un nouveau
* **Renouvellement** : Répétez la requête `/oauth/token`
* **Validation** : Vérifiez `expires_in` pour anticiper le renouvellement

## Scopes Disponibles

| Scope        | Description           | Permissions                    |
| ------------ | --------------------- | ------------------------------ |
| `api_access` | Accès général à l'API | Création marchés, candidatures |
| `api_read`   | Lecture seule         | Consultation données           |
| `api_write`  | Écriture              | Modification données           |

**Note** : Le scope `api_access` est recommandé et inclut les permissions de lecture et écriture nécessaires.

## Sécurité et Bonnes Pratiques

### Exigences de Sécurité

1. **HTTPS Obligatoire** : Toutes les communications doivent utiliser HTTPS
2. **Stockage Sécurisé** : Ne jamais exposer le `client_secret` côté client
3. **Variables d'Environnement** : Stocker les secrets dans des variables d'environnement
4. **Rotation Régulière** : Renouveler les tokens selon leur expiration

### Gestion des Erreurs

**Stratégies recommandées** :

* **Retry automatique** pour les erreurs 5xx (serveur)
* **Circuit breaker** pour éviter les appels répétés
* **Logging** des erreurs sans exposer les secrets
* **Validation** de l'expiration avant utilisation

**🔗 Scripts avec retry** : [Scripts de Référence - Authentification avec retry](99_scripts_reference.md#script-dauthentification-avec-retry)

### Validation du Token

**Bonnes pratiques** :

* Vérifier l'expiration avec buffer de 5 minutes
* Renouveler automatiquement si nécessaire
* Stocker avec timestamp d'émission
* Éviter les appels redondants

**🔗 Scripts de validation** : [Scripts de Référence - Validation de token](99_scripts_reference.md#validation-de-token)

## Exemples d'Implémentation

### Obtention et utilisation basique

```bash
# Obtenir le token et l'utiliser dans une requête API
TOKEN=$(curl -s -X POST "${BASE_URL}/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api_access" \
  | jq -r '.access_token')

# Utiliser le token pour une requête API
curl -X GET "${BASE_URL}/api/v1/public_markets" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json"
```

**🔗 Scripts avancés** :

* [Gestionnaire complet de token](99_scripts_reference.md#gestionnaire-de-token-complet)
* [Test d'intégration complet](99_scripts_reference.md#test-dintégration-complet)
* [Scripts avec logging](99_scripts_reference.md#logging-et-monitoring)

## Monitoring et Débogage

### Logs Recommandés

**Éléments à logger** :

* Demandes de token (timestamp, client\_id)
* Réussites d'authentification (durée, expiration)
* Échecs d'authentification (code HTTP, raison)
* **Important** : Ne jamais logger les secrets

### Métriques Importantes

* **Taux de succès des authentifications**
* **Temps de réponse du endpoint OAuth**
* **Fréquence de renouvellement des tokens**
* **Erreurs d'authentification par type**

**🔗 Scripts de logging** : [Scripts de Référence - Logging et monitoring](99_scripts_reference.md#logging-et-monitoring)

## Codes d'Erreur Détaillés

| Code HTTP | Erreur OAuth             | Description           | Action                           |
| --------- | ------------------------ | --------------------- | -------------------------------- |
| 400       | `invalid_request`        | Paramètres manquants  | Vérifier le format de la requête |
| 400       | `unsupported_grant_type` | Grant type incorrect  | Utiliser `client_credentials`    |
| 401       | `invalid_client`         | Credentials invalides | Vérifier client\_id/secret       |
| 401       | `invalid_client`         | Éditeur non autorisé  | Contacter l'administration       |
| 429       | `rate_limit_exceeded`    | Trop de requêtes      | Implémenter un délai             |
| 500       | `server_error`           | Erreur serveur        | Réessayer plus tard              |

Cette spécification OAuth2 garantit une intégration sécurisée et standardisée avec l'API Passe Marché.
