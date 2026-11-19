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

### Second provider (e.g. tsidp for Tailscale logins)

The provider is picked by the host Multica is opened on: logins on `OAUTH_ALT_HOST` use the `OAUTH_ALT_*` variables,
all other hosts the ones above. Typical setup: Kanidm on `multica.example.com`, [tsidp](https://github.com/tailscale/tsidp)
on `multica.<tailnet>.ts.net`.

| Env (backend) | Value |
|---|---|
| `OAUTH_ALT_HOST` | host of the second login, e.g. `multica.<tailnet>.ts.net` |
| `OAUTH_ALT_GOOGLE_CLIENT_ID` / `OAUTH_ALT_GOOGLE_CLIENT_SECRET` | client of the second provider |
| `OAUTH_ALT_OAUTH_TOKEN_URL` | tsidp: `https://idp.<tailnet>.ts.net/token` |
| `OAUTH_ALT_OAUTH_USERINFO_URL` | tsidp: `https://idp.<tailnet>.ts.net/userinfo` |

- On `OAUTH_ALT_HOST`, redirect `/kanidm/authorize` (keep the query string) to the second provider, tsidp:
  `https://idp.<tailnet>.ts.net/authorize`. Its client gets the redirect URL `https://<OAUTH_ALT_HOST>/auth/callback`.
- `/api/config` picks the client ID from `X-Forwarded-Host`, else `Host`: the proxy has to pass the original host
  through to the backend (also via the web container).
- The backend must reach the second provider (for tsidp: be on the tailnet). Auth cookies must be valid on both hosts,
  so don't set a cookie domain that excludes one of them.
- Accounts are matched by email, so the same email from either provider is the same Multica user.
