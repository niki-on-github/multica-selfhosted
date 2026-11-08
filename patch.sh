#!/usr/bin/env bash
# Turns upstream's Google OAuth login into a generic OAuth2/OIDC login (used with Kanidm) by replacing the three
# hardcoded Google URLs. Nothing else is touched, so this survives most upstream updates; if a string is gone the
# script fails and no image is built.
#
# Runtime config (backend):
#   GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET  client of the provider (upstream names, unchanged)
#   OAUTH_TOKEN_URL                          token endpoint, e.g. https://id.example.com/oauth2/token
#   OAUTH_USERINFO_URL                       userinfo endpoint, e.g. https://id.example.com/oauth2/openid/<client>/userinfo
# Web: the login button goes to the relative path /kanidm/authorize; the reverse proxy redirects it (query string
# kept) to the provider's authorization endpoint, e.g. https://id.example.com/ui/oauth2.
set -euo pipefail
cd "${1:-.}"

r() {
  local file="$1" old="$2" new="$3"
  if ! grep -qF -- "$old" "$file"; then
    echo "::error file=$file::patch string not found: $old" >&2
    exit 1
  fi
  OLD="$old" NEW="$new" perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/g' "$file"
  echo "patched $file: $old -> $new"
}

r server/internal/handler/auth.go    '"https://oauth2.googleapis.com/token"'           'os.Getenv("OAUTH_TOKEN_URL")'
r server/internal/handler/auth.go    '"https://www.googleapis.com/oauth2/v2/userinfo"' 'os.Getenv("OAUTH_USERINFO_URL")'
r packages/views/auth/login-page.tsx 'https://accounts.google.com/o/oauth2/v2/auth'    '/kanidm/authorize'
