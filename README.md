# multica-selfhosted

[Multica](https://github.com/multica-ai/multica) images with upstream's Google login turned into a generic
OAuth2/OIDC login (used with Kanidm). `patch.sh` replaces the three hardcoded Google URLs, the button label
("Continue with SSO", all locales) and the Google logo (key icon), nothing else.

- `ghcr.io/niki-on-github/multica-backend:<upstream tag>`
- `ghcr.io/niki-on-github/multica-web:<upstream tag>`

Tags equal the upstream release. `upstream.env` holds the version, Renovate bumps it (automerge), every push to
`main` builds both images. If upstream renames one of the patched strings the build fails with the missing string.

## Configuration

Backend:

| Env | Value |
|---|---|
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | OAuth2 client of the provider (enables the login button) |
| `OAUTH_TOKEN_URL` | token endpoint, Kanidm: `https://<idm>/oauth2/token` |
| `OAUTH_USERINFO_URL` | userinfo endpoint, Kanidm: `https://<idm>/oauth2/openid/<client>/userinfo` |

Web: the login button opens `/kanidm/authorize?...`. Redirect that path (keep the query string) to the
authorization endpoint, Kanidm: `https://<idm>/ui/oauth2`.

Provider client: redirect URL `https://<multica>/auth/callback`, scopes `openid email profile`, no PKCE (upstream's
flow does not send it), client secret sent in the POST body.
