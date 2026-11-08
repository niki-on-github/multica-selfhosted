#!/usr/bin/env bash
# Turns upstream's Google OAuth login into a generic OAuth2/OIDC login (used with Kanidm) by replacing the three
# hardcoded Google URLs, the button label and the Google logo. Nothing else is touched, so this survives most upstream updates; if a string is gone the
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

# like r, but OLD is a Perl regex (multi-line, /s) that must match exactly once
rx() {
  local file="$1" old="$2" new="$3" n
  n=$(OLD="$old" perl -0ne '$c = () = /$ENV{OLD}/gs; print $c' "$file")
  if [ "$n" != 1 ]; then
    echo "::error file=$file::patch regex matched $n times (want 1): $old" >&2
    exit 1
  fi
  OLD="$old" NEW="$new" perl -0pi -e 's/$ENV{OLD}/$ENV{NEW}/s' "$file"
  echo "patched $file: /$old/"
}

r server/internal/handler/auth.go    '"https://oauth2.googleapis.com/token"'           'os.Getenv("OAUTH_TOKEN_URL")'
r server/internal/handler/auth.go    '"https://www.googleapis.com/oauth2/v2/userinfo"' 'os.Getenv("OAUTH_USERINFO_URL")'
r packages/views/auth/login-page.tsx 'https://accounts.google.com/o/oauth2/v2/auth'    '/kanidm/authorize'

# Button: generic label ("Continue with SSO", i18n key signin.google in every locale) and a key icon instead of the
# Google logo. Locales without a translation below get the English text.
declare -A label=(
  [en]="Continue with SSO" [es]="Continuar con SSO" [fr]="Continuer avec SSO" [ja]="SSOで続ける"
  [ko]="SSO로 계속" [zh-Hans]="使用 SSO 继续" [zh-Hant]="使用 SSO 繼續"
)
for f in packages/views/locales/*/auth.json; do
  l=$(basename "$(dirname "$f")")
  rx "$f" '"google": "[^"]*"' "\"google\": \"${label[$l]:-${label[en]}}\""
done
rx packages/views/auth/login-page.tsx \
  '<svg className="mr-2 h-4 w-4" viewBox="0 0 24 24">.*?</svg>' \
  '<svg className="mr-2 h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M2.586 17.414A2 2 0 0 0 2 18.828V21a1 1 0 0 0 1 1h3a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1h1a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1h.172a2 2 0 0 0 1.414-.586l.814-.814a6.5 6.5 0 1 0-4-4z" /><circle cx="16.5" cy="7.5" r=".5" fill="currentColor" /></svg>'
