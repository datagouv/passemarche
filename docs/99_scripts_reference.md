# Scripts de Référence - Passe Marché

## Vue d'ensemble

Cette section regroupe tous les scripts bash, exemples curl et utilitaires pratiques pour l'intégration avec l'API Passe Marché. Ces scripts sont des outils complémentaires à la documentation technique principale.

## Configuration des environnements

Tous les scripts utilisent la variable `BASE_URL`. Définissez-la selon votre environnement :

```bash
# Staging (recommandé pour le développement)
export BASE_URL="https://staging.passemarche.data.gouv.fr"

# Production
export BASE_URL="https://passemarche.data.gouv.fr"
```

Consultez la [documentation des environnements](08_environnements.md) pour plus de détails.

***

## Authentification OAuth2

### Script d'authentification de base

```bash
#!/bin/bash
# Authentification OAuth2 simple

CLIENT_ID="${CLIENT_ID:?CLIENT_ID requis}"
CLIENT_SECRET="${CLIENT_SECRET:?CLIENT_SECRET requis}"
BASE_URL="${BASE_URL:-https://staging.passemarche.data.gouv.fr}"

get_access_token() {
  curl -s -X POST "$BASE_URL/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api_access" \
    | jq -r '.access_token'
}

# Utilisation
TOKEN=$(get_access_token)
echo "Token obtenu: ${TOKEN:0:20}..."
```

### Script d'authentification avec retry

```bash
#!/bin/bash
# Script de retry pour l'authentification OAuth

authenticate_with_retry() {
  local max_attempts=3
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    echo "Tentative d'authentification $attempt/$max_attempts"

    response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST \
      ${BASE_URL}/oauth/token \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api_access")

    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo $response | sed -e 's/HTTPSTATUS:.*//g')

    if [ $http_code -eq 200 ]; then
      echo "Authentification réussie"
      echo $body | jq '.access_token' -r
      return 0
    elif [ $http_code -eq 401 ]; then
      echo "Erreur d'authentification (401): Vérifiez vos identifiants"
      return 1
    elif [ $http_code -ge 500 ]; then
      echo "Erreur serveur ($http_code), retry dans 5s..."
      sleep 5
      ((attempt++))
    else
      echo "Erreur HTTP $http_code: $body"
      return 1
    fi
  done

  echo "Échec après $max_attempts tentatives"
  return 1
}
```

### Validation de token

```bash
#!/bin/bash
# Validation de l'expiration du token

validate_token() {
  local token_file="$1"
  local buffer_minutes=5

  if [ ! -f "$token_file" ]; then
    echo "false"
    return 1
  fi

  local issued_at=$(jq -r '.issued_at' "$token_file")
  local expires_in=$(jq -r '.expires_in' "$token_file")
  local current_time=$(date +%s)
  local expiration=$((issued_at + expires_in))
  local buffer_time=$((buffer_minutes * 60))

  if [ $current_time -lt $((expiration - buffer_time)) ]; then
    echo "true"
    return 0
  else
    echo "false"
    return 1
  fi
}

# Utilisation
if [ "$(validate_token ./token.json)" = "true" ]; then
  echo "Token encore valide"
else
  echo "Token expiré, renouvellement nécessaire"
fi
```

### Gestionnaire de token complet

```bash
#!/bin/bash
# Script complet de gestion OAuth avec curl

# Configuration
CLIENT_ID="${CLIENT_ID:-your_client_id}"
CLIENT_SECRET="${CLIENT_SECRET:-your_client_secret}"
BASE_URL="${BASE_URL:-https://staging.passemarche.data.gouv.fr}"
TOKEN_FILE="./oauth_token.json"

# Fonction d'obtention du token d'accès
get_access_token() {
  echo "Demande d'un nouveau token OAuth..."

  local response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST \
    "$BASE_URL/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api_access")

  local http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
  local body=$(echo $response | sed -e 's/HTTPSTATUS:.*//g')

  if [ $http_code -eq 200 ]; then
    # Ajouter timestamp d'émission
    echo $body | jq ". + {\"issued_at\": $(date +%s)}" > "$TOKEN_FILE"
    echo "Token obtenu et sauvegardé"
    echo $body | jq -r '.access_token'
  else
    echo "Erreur lors de l'obtention du token: HTTP $http_code"
    echo $body
    return 1
  fi
}

# Fonction de validation du token
is_token_valid() {
  if [ ! -f "$TOKEN_FILE" ]; then
    return 1
  fi

  local issued_at=$(jq -r '.issued_at // 0' "$TOKEN_FILE")
  local expires_in=$(jq -r '.expires_in // 0' "$TOKEN_FILE")
  local current_time=$(date +%s)
  local buffer_time=300  # 5 minutes

  if [ $issued_at -eq 0 ] || [ $expires_in -eq 0 ]; then
    return 1
  fi

  local expiration=$((issued_at + expires_in - buffer_time))

  [ $current_time -lt $expiration ]
}

# Fonction de requête authentifiée
make_authenticated_request() {
  local endpoint="$1"
  local method="${2:-GET}"
  local data="$3"

  # Obtenir un token valide
  local token
  if is_token_valid; then
    token=$(jq -r '.access_token' "$TOKEN_FILE")
    echo "Utilisation du token existant"
  else
    echo "Token invalide ou expiré, renouvellement..."
    token=$(get_access_token)
    if [ $? -ne 0 ]; then
      echo "Impossible d'obtenir un token"
      return 1
    fi
  fi

  # Effectuer la requête
  local curl_args=(
    -H "Authorization: Bearer $token"
    -H "Content-Type: application/json"
    -H "Accept: application/json"
  )

  if [ "$method" = "POST" ] && [ -n "$data" ]; then
    curl_args+=(-X POST -d "$data")
  elif [ "$method" = "PUT" ] && [ -n "$data" ]; then
    curl_args+=(-X PUT -d "$data")
  elif [ "$method" = "DELETE" ]; then
    curl_args+=(-X DELETE)
  fi

  curl -s "${curl_args[@]}" "$BASE_URL$endpoint"
}

# Exemples d'utilisation
# make_authenticated_request "/api/v1/public_markets"
# make_authenticated_request "/api/v1/public_markets" "POST" '{"public_market":{"name":"Test"}}'
```

***

## Gestion des Marchés Publics

### Création de marché - Script complet

```bash
#!/bin/bash
# market-creation.sh
create_market() {
  # Configuration
  local CLIENT_ID="${CLIENT_ID:?CLIENT_ID requis}"
  local CLIENT_SECRET="${CLIENT_SECRET:?CLIENT_SECRET requis}"
  local BASE_URL="${BASE_URL:-https://staging.passemarche.data.gouv.fr}"

  echo "🚀 Création d'un marché de test..."

  # 1. Authentification OAuth
  echo "🔐 Authentification..."
  local auth_response=$(curl -s -X POST "$BASE_URL/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api_access")

  local token=$(echo "$auth_response" | jq -r '.access_token')

  if [ "$token" = "null" ] || [ -z "$token" ]; then
    echo "❌ Échec authentification"
    echo "$auth_response" | jq .
    return 1
  fi

  echo "✅ Token obtenu: ${token:0:20}..."

  # 2. Création du marché
  echo "📝 Création du marché..."
  local market_data='{
    "public_market": {
      "name": "Test - Fourniture équipements informatiques",
      "lots": [{"name": "Lot unique - Ordinateurs"}],
      "deadline": "2024-12-31T23:59:59Z",
      "siret": "13002526500013",
      "market_type_codes": ["supplies"]
    }
  }'

  local api_response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X POST "$BASE_URL/api/v1/public_markets" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$market_data")

  local http_code=$(echo "$api_response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
  local response_body=$(echo "$api_response" | sed -e 's/HTTPSTATUS:.*//g')

  if [ "$http_code" -eq 201 ]; then
    local identifier=$(echo "$response_body" | jq -r '.identifier')
    local config_url=$(echo "$response_body" | jq -r '.configuration_url')

    echo "✅ Marché créé: $identifier"
    echo "🔗 Configuration URL: $config_url"

    # Sauvegarde pour utilisation ultérieure
    echo "$response_body" > "./market_$identifier.json"
    echo "📄 Détails sauvegardés dans: market_$identifier.json"

    return 0
  else
    echo "❌ Erreur création marché: HTTP $http_code"
    echo "$response_body" | jq .
    return 1
  fi
}

# Test d'exécution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  create_market
fi
```

### Création de candidature

```bash
#!/bin/bash
# Création de candidature via API

create_application() {
  local market_identifier="$1"
  local siret="$2"

  # Obtenir token (réutilise la fonction précédente)
  local token=$(get_access_token)

  local application_data='{
    "market_application": {}'

  if [ -n "$siret" ]; then
    application_data=$(echo "$application_data" | jq --arg siret "$siret" '.market_application.siret = $siret')
  fi

  curl -s -X POST "$BASE_URL/api/v1/public_markets/$market_identifier/market_applications" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "$application_data"
}

# Utilisation
# create_application "VR-2024-A1B2C3D4E5F6" "12345678901234"
```

***

## Webhooks

### Serveur webhook minimal (Node.js)

```javascript
// webhook-server.js
const express = require('express');
const crypto = require('crypto');

const app = express();
const WEBHOOK_SECRET = 'VOTRE_WEBHOOK_SECRET';

// Middleware pour raw body (requis pour signature)
app.use('/webhooks', express.raw({type: 'application/json'}));

function verifySignature(payload, signature, secret) {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(payload, 'utf8')
    .digest('hex');

  const cleanSignature = signature.replace('sha256=', '');

  return crypto.timingSafeEqual(
    Buffer.from(expectedSignature, 'hex'),
    Buffer.from(cleanSignature, 'hex')
  );
}

app.post('/webhooks/passemarche', (req, res) => {
  const payload = req.body.toString('utf8');
  const signature = req.headers['x-webhook-signature-sha256'];

  // 1. Vérification signature
  if (!signature || !verifySignature(payload, signature, WEBHOOK_SECRET)) {
    console.error('⚠️ Signature invalide');
    return res.status(401).send('Unauthorized');
  }

  try {
    // 2. Parsing JSON
    const event = JSON.parse(payload);

    console.log(`📨 Webhook reçu: ${event.event}`);
    console.log(`⏰ Timestamp: ${event.timestamp}`);

    // 3. Traitement selon le type
    switch (event.event) {
      case 'market.completed':
        handleMarketCompleted(event);
        break;
      case 'market_application.completed':
        handleApplicationCompleted(event);
        break;
      default:
        console.log(`⚠️ Type d'événement inconnu: ${event.event}`);
    }

    res.status(200).send('OK');
  } catch (error) {
    console.error('❌ Erreur traitement webhook:', error);
    res.status(500).send('Internal Server Error');
  }
});

function handleMarketCompleted(event) {
  const { market } = event;
  console.log('🎯 Marché configuré:');
  console.log(`   ID: ${market.identifier}`);
  console.log(`   Nom: ${market.name}`);
  console.log(`   Champs: ${market.field_keys.length} configurés`);
  console.log(`   Types: ${market.market_type_codes.join(', ')}`);
}

function handleApplicationCompleted(event) {
  const { market_application, market_identifier } = event;
  console.log('🎯 Candidature finalisée:');
  console.log(`   ID: ${market_application.identifier}`);
  console.log(`   Marché: ${market_identifier}`);
  console.log(`   Entreprise: ${market_application.company_name}`);
  console.log(`   SIRET: ${market_application.siret}`);
  console.log(`   Attestation: ${market_application.attestation_url}`);
  console.log(`   Dossier: ${market_application.documents_package_url}`);
}

app.listen(3001, () => {
  console.log('🚀 Serveur webhook démarré sur le port 3001');
  console.log('🔗 URL webhook: http://localhost:3001/webhooks/passemarche');
});
```

### Vérification signature HMAC (Bash)

```bash
#!/bin/bash
# Vérification signature webhook avec bash

verify_webhook_signature() {
  local payload="$1"
  local signature_header="$2"
  local secret="$3"

  # Extraire la signature (retirer sha256=)
  local signature=$(echo "$signature_header" | sed 's/^sha256=//')

  # Calculer la signature attendue
  local expected_signature=$(echo -n "$payload" | openssl dgst -sha256 -hmac "$secret" -hex | cut -d' ' -f2)

  # Comparaison sécurisée
  if [ "$signature" = "$expected_signature" ]; then
    echo "✅ Signature valide"
    return 0
  else
    echo "❌ Signature invalide"
    return 1
  fi
}

# Test
test_webhook_signature() {
  local secret="test_secret_123"
  local payload='{"event":"test","timestamp":"2024-01-01T00:00:00Z"}'

  # Générer signature (comme Passe Marché)
  local signature=$(echo -n "$payload" | openssl dgst -sha256 -hmac "$secret" -hex | cut -d' ' -f2)
  local header_value="sha256=$signature"

  echo "Signature générée: $header_value"

  # Vérifier signature
  verify_webhook_signature "$payload" "$header_value" "$secret"
}

# test_webhook_signature
```

***

## Tests et Monitoring

### Test d'intégration complet

```bash
#!/bin/bash
# Test d'intégration OAuth complète

set -e  # Arrêt en cas d'erreur

# Configuration
CLIENT_ID="${CLIENT_ID:?CLIENT_ID requis}"
CLIENT_SECRET="${CLIENT_SECRET:?CLIENT_SECRET requis}"
BASE_URL="${BASE_URL:-https://staging.passemarche.data.gouv.fr}"

echo "=== Test d'authentification OAuth ==="
echo "Client ID: $CLIENT_ID"
echo "Base URL: $BASE_URL"
echo

# Étape 1: Obtenir le token
echo "1. Obtention du token..."
auth_response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST \
  "$BASE_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api_access")

http_code=$(echo $auth_response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo $auth_response | sed -e 's/HTTPSTATUS:.*//g')

if [ $http_code -ne 200 ]; then
  echo "❌ Échec de l'authentification: HTTP $http_code"
  echo $body | jq .
  exit 1
fi

token=$(echo $body | jq -r '.access_token')
expires_in=$(echo $body | jq -r '.expires_in')

echo "✅ Token obtenu (expire dans ${expires_in}s)"
echo

# Étape 2: Test d'une requête API
echo "2. Test d'appel API authentifié..."
api_response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -H "Authorization: Bearer $token" \
  -H "Accept: application/json" \
  "$BASE_URL/api/v1/status")

api_http_code=$(echo $api_response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
api_body=$(echo $api_response | sed -e 's/HTTPSTATUS:.*//g')

if [ $api_http_code -eq 200 ]; then
  echo "✅ Appel API réussi"
  echo $api_body | jq .
else
  echo "❌ Échec de l'appel API: HTTP $api_http_code"
  echo $api_body
fi

echo
echo "=== Test terminé ==="
```

### Logging et monitoring

```bash
#!/bin/bash
# Fonctions de logging pour OAuth

# Configuration du logging
LOG_FILE="/var/log/passemarche-oauth.log"

log_message() {
  local level="$1"
  local message="$2"
  local timestamp=$(date -Iseconds)
  echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_token_request() {
  log_message "INFO" "Demande de token OAuth"
}

log_token_received() {
  local expires_in="$1"
  local expiration=$(date -Iseconds -d "+${expires_in} seconds")
  log_message "INFO" "Token reçu, expire le: $expiration"
}

log_auth_error() {
  local error="$1"
  log_message "ERROR" "Erreur authentification: $error"
}

# Exemple d'obtention de token avec logging
get_token_with_logging() {
  log_token_request

  local response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST \
    "$BASE_URL/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api_access")

  local http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
  local body=$(echo $response | sed -e 's/HTTPSTATUS:.*//g')

  if [ $http_code -eq 200 ]; then
    local expires_in=$(echo $body | jq -r '.expires_in')
    log_token_received "$expires_in"
    echo $body | jq -r '.access_token'
  else
    local error_desc=$(echo $body | jq -r '.error_description // "Erreur inconnue"')
    log_auth_error "HTTP $http_code: $error_desc"
    return 1
  fi
}
```

***

## Utilitaires

### Configuration d'environnement

```bash
#!/bin/bash
# setup-env.sh - Configuration d'environnement

create_env_file() {
  cat > .env << EOF
# Configuration Passe Marché
CLIENT_ID=votre_client_id
CLIENT_SECRET=votre_client_secret
BASE_URL=https://staging.passemarche.data.gouv.fr

# Configuration webhook
WEBHOOK_SECRET=votre_webhook_secret
WEBHOOK_PORT=3001

# Environnement
RACK_ENV=development
EOF

  echo "✅ Fichier .env créé"
  echo "⚠️  Éditez .env avec vos vraies valeurs"
}

load_env() {
  if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Variables d'environnement chargées"
  else
    echo "❌ Fichier .env non trouvé"
    return 1
  fi
}

# create_env_file
# load_env
```

### Oneshot quick test

```bash
#!/bin/bash
# Test rapide en une ligne

quick_auth_test() {
  curl -s -X POST ${BASE_URL}/oauth/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api_access" \
    | jq -r '.access_token // "ERREUR"'
}

quick_api_test() {
  local token="$1"
  curl -s -H "Authorization: Bearer $token" \
    -H "Accept: application/json" \
    ${BASE_URL}/api/v1/status \
    | jq .
}

# Usage: TOKEN=$(quick_auth_test) && quick_api_test "$TOKEN"
```

***

## Support et Debugging

### Diagnostics réseau

```bash
#!/bin/bash
# Tests de connectivité et diagnostics

# Configuration
BASE_URL="${BASE_URL:-https://staging.passemarche.data.gouv.fr}"
# Extraire le hostname de BASE_URL
HOSTNAME=$(echo "$BASE_URL" | sed -e 's|https://||' -e 's|/.*||')

test_connectivity() {
  echo "=== Tests de connectivité pour $HOSTNAME ==="

  # Test DNS
  echo "1. Test DNS..."
  if nslookup "$HOSTNAME" > /dev/null 2>&1; then
    echo "✅ DNS OK"
  else
    echo "❌ Problème DNS"
  fi

  # Test HTTPS
  echo "2. Test HTTPS..."
  if curl -s -I "$BASE_URL" | head -n 1 | grep -q "200\|301\|302"; then
    echo "✅ HTTPS accessible"
  else
    echo "❌ HTTPS inaccessible"
  fi

  # Test certificat SSL
  echo "3. Test certificat SSL..."
  if echo | openssl s_client -connect "$HOSTNAME:443" -servername "$HOSTNAME" 2>/dev/null | grep -q "Verify return code: 0"; then
    echo "✅ Certificat SSL valide"
  else
    echo "⚠️ Problème certificat SSL"
  fi
}

# test_connectivity
```

***

Ces scripts sont fournis comme utilitaires complémentaires. Adaptez-les selon vos besoins spécifiques et votre environnement de production.
