# API Voie Rapide - Guide d'Intégration pour les Éditeurs

Ce document décrit comment intégrer votre plateforme d'édition avec l'API Voie Rapide pour permettre l'authentification OAuth2 et l'accès aux services de candidature simplifiée aux marchés publics.

## Vue d'ensemble

Voie Rapide propose une API OAuth2 permettant aux plateformes d'éditeurs de s'authentifier et d'accéder aux services de candidature aux marchés publics. L'authentification utilise le flux **Client Credentials** pour une communication sécurisée entre applications.

### Architecture

```
┌─────────────────┐     OAuth2 Token     ┌─────────────────┐
│                 │ ─────────────────────▶│                 │
│ Plateforme      │                       │ Voie Rapide     │
│ Éditeur         │ ◄───────────────────── │ API             │
│                 │   API Calls + Bearer   │                 │
└─────────────────┘       Token           └─────────────────┘
```

## Prérequis

### 1. Enregistrement de l'Éditeur

**Important** : L'enregistrement d'un éditeur doit être effectué par un administrateur de Voie Rapide. Il n'existe pas d'interface d'auto-enregistrement pour des raisons de sécurité.

Pour demander l'enregistrement de votre plateforme :

1. **Contactez l'équipe Voie Rapide** avec les informations suivantes :
   - Nom de votre plateforme d'édition
   - Description de votre plateforme
   - Contact technique responsable
   - Cas d'usage prévus

2. **L'administrateur créera votre compte éditeur** avec :
   - **Nom de l'éditeur** : Identifiant unique de votre plateforme
   - **Client ID** : Identifiant client OAuth2 (généré par Voie Rapide)
   - **Client Secret** : Secret client OAuth2 (généré par Voie Rapide)
   - **Statut autorisé** : Votre éditeur doit être marqué comme `authorized: true`
   - **Statut actif** : Votre éditeur doit être marqué comme `active: true`

3. **Réception des identifiants** : Les identifiants vous seront transmis de manière sécurisée par l'administrateur.

### 2. Informations d'Authentification

Une fois enregistré, vous recevrez :

```json
{
  "client_id": "your_unique_client_id",
  "client_secret": "your_secret_key",
  "api_base_url": "https://voie-rapide.example.com"
}
```

## Authentification OAuth2

### Flux Client Credentials

Voie Rapide utilise le flux OAuth2 **Client Credentials** pour l'authentification entre applications.

#### 1. Obtenir un Token d'Accès

**Endpoint :** `POST /oauth/token`

**Headers :**
```http
Content-Type: application/x-www-form-urlencoded
```

**Body :**
```
grant_type=client_credentials
client_id=your_client_id
client_secret=your_client_secret
scope=api_access
```

**Exemple avec cURL :**
```bash
curl -X POST https://voie-rapide.example.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=your_client_id&client_secret=your_client_secret&scope=api_access"
```

#### 2. Réponse Succès

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "scope": "api_access"
}
```

#### 3. Réponse Erreur

**Client invalide (401 Unauthorized) :**
```json
{
  "error": "invalid_client",
  "error_description": "Client authentication failed"
}
```

**Éditeur non autorisé :**
```json
{
  "error": "invalid_client",
  "error_description": "Editor is not authorized or active"
}
```

### Scopes Disponibles

| Scope | Description |
|-------|-------------|
| `api_access` | Accès général à l'API (scope par défaut) |
| `api_read` | Lecture des données |
| `api_write` | Écriture et modification des données |

## Utilisation du Token

### Headers d'Authentification

Une fois le token obtenu, incluez-le dans toutes les requêtes API :

```http
Authorization: Bearer your_access_token
```

### Expiration et Renouvellement

- **Durée de vie** : 24 heures
- **Renouvellement** : Obtenez un nouveau token en répétant la requête `/oauth/token`
- **Révocation** : Les anciens tokens sont automatiquement révoqués lors de l'émission d'un nouveau token

## Exemples d'Intégration

### JavaScript/Node.js

```javascript
class VoieRapideClient {
  constructor(clientId, clientSecret, baseUrl) {
    this.clientId = clientId;
    this.clientSecret = clientSecret;
    this.baseUrl = baseUrl;
    this.accessToken = null;
    this.tokenExpiration = null;
  }

  async authenticate() {
    const response = await fetch(`${this.baseUrl}/oauth/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'client_credentials',
        client_id: this.clientId,
        client_secret: this.clientSecret,
        scope: 'api_access'
      })
    });

    if (!response.ok) {
      throw new Error(`Authentication failed: ${response.status}`);
    }

    const data = await response.json();
    this.accessToken = data.access_token;
    this.tokenExpiration = Date.now() + (data.expires_in * 1000);
    
    return data;
  }

  async makeApiRequest(endpoint, options = {}) {
    // Renouveler le token si nécessaire
    if (!this.accessToken || Date.now() >= this.tokenExpiration) {
      await this.authenticate();
    }

    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.accessToken}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    });

    return response;
  }
}

// Utilisation
const client = new VoieRapideClient(
  'your_client_id',
  'your_client_secret',
  'https://voie-rapide.example.com'
);

// Authentification
await client.authenticate();

// Utilisation de l'API
const response = await client.makeApiRequest('/api/v1/some-endpoint');
```

### PHP

```php
<?php
class VoieRapideClient {
    private $clientId;
    private $clientSecret;
    private $baseUrl;
    private $accessToken;
    private $tokenExpiration;

    public function __construct($clientId, $clientSecret, $baseUrl) {
        $this->clientId = $clientId;
        $this->clientSecret = $clientSecret;
        $this->baseUrl = $baseUrl;
    }

    public function authenticate() {
        $data = [
            'grant_type' => 'client_credentials',
            'client_id' => $this->clientId,
            'client_secret' => $this->clientSecret,
            'scope' => 'api_access'
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $this->baseUrl . '/oauth/token');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/x-www-form-urlencoded'
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode !== 200) {
            throw new Exception("Authentication failed: " . $httpCode);
        }

        $tokenData = json_decode($response, true);
        $this->accessToken = $tokenData['access_token'];
        $this->tokenExpiration = time() + $tokenData['expires_in'];

        return $tokenData;
    }

    public function makeApiRequest($endpoint, $method = 'GET', $data = null) {
        // Renouveler le token si nécessaire
        if (!$this->accessToken || time() >= $this->tokenExpiration) {
            $this->authenticate();
        }

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $this->baseUrl . $endpoint);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $this->accessToken,
            'Content-Type: application/json'
        ]);

        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        }

        $response = curl_exec($ch);
        curl_close($ch);

        return $response;
    }
}

// Utilisation
$client = new VoieRapideClient(
    'your_client_id',
    'your_client_secret',
    'https://voie-rapide.example.com'
);

$client->authenticate();
$response = $client->makeApiRequest('/api/v1/some-endpoint');
?>
```

### Python

```python
import requests
import time
from datetime import datetime, timedelta

class VoieRapideClient:
    def __init__(self, client_id, client_secret, base_url):
        self.client_id = client_id
        self.client_secret = client_secret
        self.base_url = base_url
        self.access_token = None
        self.token_expiration = None

    def authenticate(self):
        data = {
            'grant_type': 'client_credentials',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'scope': 'api_access'
        }

        response = requests.post(
            f"{self.base_url}/oauth/token",
            data=data,
            headers={'Content-Type': 'application/x-www-form-urlencoded'}
        )

        if response.status_code != 200:
            raise Exception(f"Authentication failed: {response.status_code}")

        token_data = response.json()
        self.access_token = token_data['access_token']
        self.token_expiration = datetime.now() + timedelta(seconds=token_data['expires_in'])

        return token_data

    def make_api_request(self, endpoint, method='GET', data=None):
        # Renouveler le token si nécessaire
        if not self.access_token or datetime.now() >= self.token_expiration:
            self.authenticate()

        headers = {
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json'
        }

        response = requests.request(
            method,
            f"{self.base_url}{endpoint}",
            headers=headers,
            json=data
        )

        return response

# Utilisation
client = VoieRapideClient(
    'your_client_id',
    'your_client_secret',
    'https://voie-rapide.example.com'
)

client.authenticate()
response = client.make_api_request('/api/v1/some-endpoint')
```

## Gestion des Erreurs

### Codes d'Erreur HTTP

| Code | Description |
|------|-------------|
| `200` | Succès |
| `400` | Requête invalide |
| `401` | Non autorisé (token invalide ou expiré) |
| `403` | Accès refusé |
| `404` | Ressource non trouvée |
| `500` | Erreur serveur |

### Erreurs d'Authentification

```json
{
  "error": "invalid_client",
  "error_description": "Client authentication failed"
}
```

```json
{
  "error": "invalid_grant",
  "error_description": "The provided authorization grant is invalid"
}
```

```json
{
  "error": "unsupported_grant_type",
  "error_description": "The grant type is not supported"
}
```

## Bonnes Pratiques

### Sécurité

1. **Stockage sécurisé** : Ne jamais exposer le `client_secret` côté client
2. **HTTPS uniquement** : Toujours utiliser HTTPS en production
3. **Rotation des tokens** : Renouveler les tokens régulièrement
4. **Validation des certificats** : Vérifier les certificats SSL/TLS

### Performance

1. **Mise en cache** : Stocker le token jusqu'à expiration
2. **Gestion des erreurs** : Implémenter une logique de retry
3. **Limitation des requêtes** : Respecter les limites de taux d'API

### Monitoring

1. **Logs d'authentification** : Enregistrer les tentatives d'authentification
2. **Métriques** : Surveiller les temps de réponse et les erreurs
3. **Alertes** : Configurer des alertes pour les échecs d'authentification

## Processus d'Enregistrement et Sécurité

### Pourquoi un enregistrement manuel ?

L'enregistrement des éditeurs est effectué manuellement par un administrateur pour garantir :

1. **Vérification d'identité** : S'assurer que l'éditeur est une plateforme légitime
2. **Contrôle d'accès** : Limiter l'accès aux plateformes autorisées uniquement
3. **Traçabilité** : Maintenir un registre des éditeurs et de leurs activités
4. **Sécurité** : Éviter les enregistrements automatisés malveillants

### Gestion des Accès

Les administrateurs peuvent :

- **Activer/Désactiver** un éditeur (statut `active`)
- **Autoriser/Révoquer** l'accès (statut `authorized`)
- **Régénérer** les identifiants en cas de compromission
- **Auditer** l'utilisation de l'API par éditeur

### Révocation d'Accès

En cas de :
- Utilisation abusive de l'API
- Suspicion de compromission des identifiants
- Non-respect des conditions d'utilisation

L'administrateur peut immédiatement révoquer l'accès en mettant l'éditeur en statut `active: false` ou `authorized: false`.

## Support et Contact

Pour toute question technique ou problème d'intégration :

- **Documentation** : Consulter ce guide et le README du projet
- **Issues** : Créer une issue sur le dépôt GitHub
- **Support** : Contacter l'équipe de développement

## Versions et Mises à Jour

- **Version actuelle** : 1.0.0
- **Rétrocompatibilité** : Les changements breaking seront annoncés
- **Changelog** : Consulter le fichier CHANGELOG.md pour les mises à jour

---

*Ce document est mis à jour régulièrement. Consultez la version la plus récente sur le dépôt GitHub.*