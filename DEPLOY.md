# DEPLOY.md – Google Cloud setup and CI/CD

Step by step, from an empty Google account to a live site deployed automatically from `main`.

Everything here is copy-pasteable. Set the shell variables in step 1 and the rest follow from them.

---

## 0. Choose your hosting shape first

This decision changes everything downstream, so make it before you type anything.

| | **Option A – Firebase Hosting** | **Option B – Cloud Storage + Load Balancer** |
|---|---|---|
| Setup | About 15 minutes | About 90 minutes |
| Cost | Effectively free at this traffic | ~US$30–40/month before any traffic |
| CDN + HTTPS | Included, automatic | Cloud CDN + Google-managed cert |
| Cloud Armor WAF | Not available | Yes – OWASP rulesets, rate limiting, DDoS |
| Custom domain | Yes | Yes |

**My recommendation: start with Option A.** Right now this is a static page with no backend, no forms hitting your servers, and no database. Cloud Armor protects an origin you don't have yet, and US$40/month is A$600 over a year-long campaign – real money against a A$21,250 target.

Move to Option B when the Stripe backend lands on Cloud Run. That's when a WAF starts earning its cost, and the load balancer you build then will front both the static site and the API.

Both are documented below. Steps 1–3 are shared.

**Apply for [Google for Nonprofits](https://www.google.com/nonprofits/) first.** ACNC registration should qualify you, and it includes Google Cloud credits that may cover Option B entirely.

---

## 1. Prerequisites and variables

Install the gcloud CLI, then:

```bash
gcloud auth login
gcloud components update
```

Set these once per terminal session. Everything below uses them.

```bash
export PROJECT_ID="rebuild-damminna-central"      # must be globally unique
export PROJECT_NAME="Rebuild Damminna Central"
export BILLING_ACCOUNT="000000-000000-000000"     # gcloud billing accounts list
export REGION="asia-southeast1"                   # Singapore
export DOMAIN="rebuilddamminna.org"               # your real domain
export GITHUB_REPO="niro-pathi/rebuild-damminna-central"
export BUCKET="rdc-site-prod"                     # must be globally unique
```

**On the region.** There is no Google Cloud region in Sri Lanka. `asia-southeast1` (Singapore) or `asia-south1` (Mumbai) are the nearest. Singapore has better connectivity to Australia, where most of your donors are, and a stronger compliance story. Pick one and pin every resource to it – mixing regions costs you in latency and egress.

This matters legally as well as technically: Sri Lanka's Personal Data Protection Act No. 9 of 2022 has cross-border transfer provisions, and your privacy policy must name the region your data actually sits in.

---

## 2. Create the project

```bash
gcloud projects create "$PROJECT_ID" --name="$PROJECT_NAME"
gcloud config set project "$PROJECT_ID"
gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT"
```

### Set a budget alert immediately

Do this now, not later. A misconfigured load balancer or a runaway log sink is how charities get surprise bills.

```bash
gcloud billing budgets create \
  --billing-account="$BILLING_ACCOUNT" \
  --display-name="Rebuild Damminna Central" \
  --budget-amount=100AUD \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=90 \
  --threshold-rule=percent=100 \
  --filter-projects="projects/$PROJECT_ID"
```

Add email recipients in the console under **Billing → Budgets & alerts** – the CLI creates the budget but notification channels are easier to attach there.

### Enable the APIs you need

```bash
gcloud services enable \
  compute.googleapis.com \
  storage.googleapis.com \
  certificatemanager.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudresourcemanager.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com
```

Add these when the backend arrives: `run.googleapis.com`, `sqladmin.googleapis.com`, `secretmanager.googleapis.com`, `artifactregistry.googleapis.com`, `redis.googleapis.com`, `vpcaccess.googleapis.com`.

---

## 3. Baseline hardening

Two organisation policies worth setting on day one. These only apply if you have a Google Cloud organisation (a Workspace or Cloud Identity account); on a personal account you can skip to step 4.

```bash
# Block creation of service account keys - the credential most likely to leak.
# We use Workload Identity Federation instead, so nothing here needs a key.
gcloud resource-manager org-policies enable-enforce \
  iam.disableServiceAccountKeyCreation --project="$PROJECT_ID"

# Require uniform bucket-level access; no per-object ACLs.
gcloud resource-manager org-policies enable-enforce \
  storage.uniformBucketLevelAccess --project="$PROJECT_ID"
```

**A gotcha that will cost you an afternoon:** if your organisation enforces `iam.allowedPolicyMemberDomains` (domain restricted sharing), you **cannot** grant `allUsers` read access to a bucket – which is exactly what public web hosting requires. If step 5 fails with a policy error, that's why. You need an exception for this project, added by whoever administers the organisation.

Turn on Security Command Center at the Standard tier – it's free and will flag public buckets and open firewall rules:

```bash
# Console: Security → Security Command Center → Enable
```

---

# OPTION A – Firebase Hosting

The fast path. Skip to Option B if you need Cloud Armor now.

## A1. Set up Firebase

```bash
npm install -g firebase-tools
firebase login
firebase projects:addfirebase "$PROJECT_ID"
```

In your repo:

```bash
firebase init hosting
# - Use an existing project → rebuild-damminna-central
# - Public directory: dist
# - Single-page app: No
# - Set up automatic builds with GitHub: No (we write our own workflow)
```

Replace the generated `firebase.json` with this – the cache headers matter more than anything else here:

```json
{
  "hosting": {
    "public": "dist",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "headers": [
      {
        "source": "**/*.@(woff|woff2)",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" },
          { "key": "Access-Control-Allow-Origin", "value": "*" }
        ]
      },
      {
        "source": "/index.html",
        "headers": [
          { "key": "Cache-Control", "value": "no-cache, max-age=0, must-revalidate" }
        ]
      },
      {
        "source": "**",
        "headers": [
          { "key": "X-Content-Type-Options", "value": "nosniff" },
          { "key": "X-Frame-Options", "value": "DENY" },
          { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
          { "key": "Strict-Transport-Security", "value": "max-age=31536000; includeSubDomains; preload" },
          { "key": "Content-Security-Policy",
            "value": "default-src 'self'; img-src 'self' data:; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'" }
        ]
      }
    ]
  }
}
```

**On the CSP.** `'unsafe-inline'` is there because the prototype keeps its CSS and JS inline in one file. That's fine for a static page with no user input reaching the server, but **it must be tightened before the site takes payments.** When you split the JS out and add Stripe, move to a nonce-based policy and add `https://js.stripe.com` and `https://api.stripe.com`. Note this as a launch blocker.

## A2. Custom domain

```bash
firebase hosting:sites:list
# Console: Hosting → Add custom domain → rebuilddamminna.org
```

Firebase gives you A records to add at your registrar and provisions a certificate automatically, usually within an hour.

## A3. GitHub Actions deploy

Create the deploy service account and grant it Firebase Hosting admin:

```bash
gcloud iam service-accounts create github-deployer \
  --display-name="GitHub Actions deployer"

export DEPLOY_SA="github-deployer@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$DEPLOY_SA" \
  --role="roles/firebasehosting.admin"
```

Now do **step 6 (Workload Identity Federation)** below – it's shared between both options – then use this workflow instead of the bundled `deploy.yml`:

```yaml
      - id: auth
        uses: google-github-actions/auth@v3
        with:
          workload_identity_provider: ${{ vars.WIF_PROVIDER }}
          service_account: ${{ vars.DEPLOY_SA }}

      - name: Deploy
        run: |
          npm install -g firebase-tools
          firebase deploy --only hosting --project ${{ vars.GCP_PROJECT }} --non-interactive
```

Firebase Hosting keeps every release, so rollback is one click in the console – a genuine advantage over Option B.

---

# OPTION B – Cloud Storage + Load Balancer + Cloud Armor

The production shape. Build this when the Cloud Run backend arrives, or now if you want the WAF from day one.

## B1. Create and populate the bucket

```bash
gcloud storage buckets create "gs://$BUCKET" \
  --location="$REGION" \
  --uniform-bucket-level-access \
  --public-access-prevention=inherited

# Make it world-readable. This is a public website; that's the point.
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" \
  --member=allUsers --role=roles/storage.objectViewer

# Versioning gives you a rollback path for a bad deploy.
gcloud storage buckets update "gs://$BUCKET" --versioning
```

Seed it so the load balancer has something to serve:

```bash
gcloud storage cp index.html "gs://$BUCKET/index.html" \
  --cache-control="no-cache, max-age=0, must-revalidate" \
  --content-type="text/html; charset=utf-8"

gcloud storage rsync fonts "gs://$BUCKET/fonts" --recursive \
  --cache-control="public, max-age=31536000, immutable"
```

**The cache headers are the whole game here.** `index.html` must be uncached, or a donor sees a stale "218 of 425 places filled" for hours after the number moves. Fonts are immutable and should cache for a year. Getting this backwards is the single most common static-hosting mistake.

## B2. Reserve an IP and create the backend

```bash
gcloud compute addresses create rdc-ip --global

export IP=$(gcloud compute addresses describe rdc-ip --global --format='value(address)')
echo "Point your DNS A record at: $IP"

gcloud compute backend-buckets create rdc-backend \
  --gcs-bucket-name="$BUCKET" \
  --enable-cdn \
  --cache-mode=CACHE_ALL_STATIC \
  --default-ttl=3600 \
  --max-ttl=86400 \
  --negative-caching
```

## B3. Point DNS at it before requesting the certificate

At your registrar, create an A record for `$DOMAIN` (and `www` if you want it) pointing at `$IP`.

**The managed certificate will not provision until DNS resolves to the load balancer.** Do this step now and let it propagate while you build the rest.

```bash
gcloud compute ssl-certificates create rdc-cert \
  --domains="$DOMAIN,www.$DOMAIN" --global
```

Provisioning takes 15–60 minutes once DNS is live. Check with:

```bash
gcloud compute ssl-certificates describe rdc-cert --global \
  --format='value(managed.status, managed.domainStatus)'
```

## B4. Cloud Armor

```bash
gcloud compute security-policies create rdc-armor \
  --description="WAF for the campaign site"

# OWASP preconfigured rulesets. Sensitivity 1 is the least aggressive tier -
# start here. Higher sensitivity blocks more but generates false positives,
# and a donor blocked at checkout is worse than most attacks you'd catch.
gcloud compute security-policies rules create 1000 \
  --security-policy=rdc-armor \
  --expression="evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})" \
  --action=deny-403 --description="SQL injection"

gcloud compute security-policies rules create 1001 \
  --security-policy=rdc-armor \
  --expression="evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})" \
  --action=deny-403 --description="Cross-site scripting"

gcloud compute security-policies rules create 1002 \
  --security-policy=rdc-armor \
  --expression="evaluatePreconfiguredWaf('lfi-v33-stable', {'sensitivity': 1})" \
  --action=deny-403 --description="Local file inclusion"

gcloud compute security-policies rules create 1003 \
  --security-policy=rdc-armor \
  --expression="evaluatePreconfiguredWaf('rce-v33-stable', {'sensitivity': 1})" \
  --action=deny-403 --description="Remote code execution"

# Rate limit per IP. Generous for a browsing donor, tight enough to blunt
# scripted abuse. Tighten hard on the checkout endpoint once it exists.
gcloud compute security-policies rules create 2000 \
  --security-policy=rdc-armor \
  --expression="true" \
  --action=throttle \
  --rate-limit-threshold-count=120 \
  --rate-limit-threshold-interval-sec=60 \
  --conform-action=allow \
  --exceed-action=deny-429 \
  --enforce-on-key=IP \
  --description="Per-IP rate limit"

gcloud compute security-policies update rdc-armor --enable-layer7-ddos-defense

gcloud compute backend-buckets update rdc-backend --security-policy=rdc-armor
```

**Run the WAF rules in preview mode for the first week.** Add `--preview` to each rule, watch Cloud Logging for what *would* have been blocked, then remove `--preview`. Shipping a WAF straight to enforce is how you discover it was blocking legitimate donors after the campaign launch email went out.

## B5. Wire up the load balancer

```bash
gcloud compute url-maps create rdc-url-map --default-backend-bucket=rdc-backend

gcloud compute target-https-proxies create rdc-https-proxy \
  --url-map=rdc-url-map --ssl-certificates=rdc-cert

gcloud compute forwarding-rules create rdc-https-rule \
  --address=rdc-ip --global \
  --target-https-proxy=rdc-https-proxy --ports=443
```

Redirect plain HTTP to HTTPS – this needs its own url-map, proxy and forwarding rule:

```bash
cat > /tmp/redirect.yaml <<'YAML'
name: rdc-redirect
defaultUrlRedirect:
  redirectResponseCode: MOVED_PERMANENTLY_DEFAULT
  httpsRedirect: true
YAML

gcloud compute url-maps import rdc-redirect --source=/tmp/redirect.yaml --global --quiet

gcloud compute target-http-proxies create rdc-http-proxy --url-map=rdc-redirect

gcloud compute forwarding-rules create rdc-http-rule \
  --address=rdc-ip --global \
  --target-http-proxy=rdc-http-proxy --ports=80
```

## B6. Security headers

Backend buckets can set response headers via the URL map's `headerAction`. Export, edit, re-import:

```bash
gcloud compute url-maps export rdc-url-map --destination=/tmp/urlmap.yaml --global
```

Add under the default route action:

```yaml
headerAction:
  responseHeadersToAdd:
    - headerName: Strict-Transport-Security
      headerValue: "max-age=31536000; includeSubDomains; preload"
      replace: true
    - headerName: X-Content-Type-Options
      headerValue: "nosniff"
      replace: true
    - headerName: X-Frame-Options
      headerValue: "DENY"
      replace: true
    - headerName: Referrer-Policy
      headerValue: "strict-origin-when-cross-origin"
      replace: true
```

```bash
gcloud compute url-maps import rdc-url-map --source=/tmp/urlmap.yaml --global --quiet
```

---

## 6. Workload Identity Federation (both options)

This is how GitHub Actions authenticates to Google Cloud **without a stored key**. The old pattern – a service account JSON key base64'd into a GitHub secret – is a long-lived credential sitting in your repo settings, and it's the thing the `iam.disableServiceAccountKeyCreation` policy in step 3 exists to prevent.

```bash
export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')

# 1. The pool
gcloud iam workload-identity-pools create github-pool \
  --location=global --display-name="GitHub Actions"

# 2. The OIDC provider, trusting GitHub's token issuer
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --location=global \
  --workload-identity-pool=github-pool \
  --display-name="GitHub" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
  --attribute-condition="assertion.repository == '${GITHUB_REPO}'"
```

**The `--attribute-condition` is not optional.** Without it, *any* GitHub repository on the internet can present a token to your pool. It is the difference between "my repo can deploy" and "anyone's repo can deploy."

```bash
# 3. The service account GitHub will impersonate
gcloud iam service-accounts create github-deployer \
  --display-name="GitHub Actions deployer"

export DEPLOY_SA="github-deployer@${PROJECT_ID}.iam.gserviceaccount.com"

# 4. Least privilege. Option B needs these two; Option A needs
#    roles/firebasehosting.admin instead.
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$DEPLOY_SA" --role="roles/storage.objectAdmin"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$DEPLOY_SA" --role="roles/compute.loadBalancerAdmin"

# 5. Let only pushes to main impersonate it
gcloud iam service-accounts add-iam-policy-binding "$DEPLOY_SA" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/attribute.repository/${GITHUB_REPO}"

# 6. The value GitHub needs
echo "WIF_PROVIDER = projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/providers/github-provider"
echo "DEPLOY_SA    = ${DEPLOY_SA}"
```

### Add the variables in GitHub

**Settings → Secrets and variables → Actions → Variables** (these are *variables*, not secrets – none of them is confidential, which is the point of WIF):

| Name | Value |
|---|---|
| `WIF_PROVIDER` | the `projects/…/providers/github-provider` string printed above |
| `DEPLOY_SA` | `github-deployer@rebuild-damminna-central.iam.gserviceaccount.com` |
| `GCS_BUCKET` | `rdc-site-prod` |
| `URL_MAP` | `rdc-url-map` |
| `SITE_URL` | `https://rebuilddamminna.org/` |
| `GCP_PROJECT` | `rebuild-damminna-central` |

### Protect the production environment

**Settings → Environments → New environment → `production`**, then add yourself as a required reviewer. The deploy workflow declares `environment: production`, so every deploy pauses for approval. For a site handling donations that's worth the extra click.

---

## 7. The workflows

Two are already in the repo.

**`.github/workflows/checks.yml`** runs on every pull request:
- `scripts/brand-audit.sh` – em dashes, raw hex outside `:root`, synthesised font weights, missing fonts
- the inline JavaScript actually parses
- no `localStorage` or `sessionStorage`
- a secret scan for Stripe keys, private keys and service account JSON

**`.github/workflows/deploy.yml`** runs on push to `main`:
- re-runs the brand audit
- replaces `https://example.org/` with `SITE_URL` (this is why the placeholder is safe to leave in the repo)
- uploads fonts with a one-year immutable cache
- uploads `index.html` with no-cache
- invalidates the CDN

Test the auth wiring before trusting it:

```bash
git commit --allow-empty -m "test deploy" && git push
```

Watch the Actions tab. If the auth step fails, the cause is almost always one of: `id-token: write` missing from the job permissions, the `WIF_PROVIDER` string being the pool rather than the provider, or the attribute condition not matching your repo name exactly.

---

## 8. When the backend arrives

The site is static today. Once Stripe checkout exists, add:

```bash
# Artifact Registry for the API container
gcloud artifacts repositories create rdc-api \
  --repository-format=docker --location="$REGION"

# Cloud SQL, private IP only - no public endpoint, ever
gcloud sql instances create rdc-db \
  --database-version=POSTGRES_16 \
  --tier=db-g1-small \
  --region="$REGION" \
  --no-assign-ip \
  --network=default \
  --backup-start-time=17:00 \
  --enable-point-in-time-recovery

# Secrets. Never in the repo, never in an env file.
echo -n "sk_live_…" | gcloud secrets create stripe-secret-key --data-file=-
echo -n "whsec_…"   | gcloud secrets create stripe-webhook-secret --data-file=-

# Cloud Run, scaling to zero between donation waves
gcloud run deploy rdc-api \
  --image="${REGION}-docker.pkg.dev/${PROJECT_ID}/rdc-api/api:latest" \
  --region="$REGION" \
  --service-account="rdc-api-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --set-secrets="STRIPE_SECRET_KEY=stripe-secret-key:latest,STRIPE_WEBHOOK_SECRET=stripe-webhook-secret:latest" \
  --min-instances=0 --max-instances=10 \
  --no-allow-unauthenticated
```

Then add a serverless NEG to the load balancer and route `/api/*` to Cloud Run while `/*` continues to the bucket. Three things to carry across from `CLAUDE.md`:

1. **Restore a backup before you launch.** An untested backup is not a backup.
2. **Give the API its own service account**, never the default compute one.
3. **The Stripe webhook endpoint must be publicly reachable but signature-verified.** It's the one route that can't sit behind auth, so the signature check is the only thing protecting it.

---

## 9. Monitoring

```bash
# Uptime check
gcloud monitoring uptime create rdc-uptime \
  --resource-type=uptime-url \
  --resource-labels="host=${DOMAIN},project_id=${PROJECT_ID}" \
  --period=5 --timeout=10
```

In the console, add alert policies for: uptime check failing, 5xx rate above 1%, Cloud Armor blocking a spike of requests, and the budget thresholds from step 2. Route them to a real phone, not just an inbox.

Log retention: `_Default` keeps 30 days free. If you need longer for the ACNC External Conduct Standards audit trail, create a log sink to a Cloud Storage bucket with a lifecycle rule – far cheaper than extending Logging retention.

---

## 10. Rollback

**Option A:** Firebase Hosting console → Hosting → release history → Rollback. One click.

**Option B:** bucket versioning is on, so:

```bash
gcloud storage ls --all-versions "gs://$BUCKET/index.html"
gcloud storage cp "gs://$BUCKET/index.html#<GENERATION>" "gs://$BUCKET/index.html" \
  --cache-control="no-cache, max-age=0, must-revalidate"
gcloud compute url-maps invalidate-cdn-cache rdc-url-map --path="/*"
```

Or just `git revert` and let the workflow redeploy – slower, but it keeps the repo and production in agreement, which matters more than speed.

---

## 11. Cost

Rough monthly, in USD, at campaign traffic levels:

| Item | Option A | Option B |
|---|---|---|
| Hosting / storage | ~$0 | ~$1 |
| Load balancer forwarding rule | – | ~$18 |
| Cloud CDN | – | ~$2 |
| Cloud Armor policy + 5 rules | – | ~$10 |
| Egress | ~$0 | ~$2 |
| Logging, monitoring | ~$0 | ~$1 |
| **Total** | **~$0–2** | **~$34** |

Add roughly $10–25/month for Cloud SQL and Cloud Run once the backend exists, on either option.

---

## 12. Pre-launch checklist

Infrastructure:

- [ ] Budget alert set, with a real email attached
- [ ] HTTPS working; HTTP redirects to it
- [ ] HSTS, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy` present – check with `curl -sI https://$DOMAIN`
- [ ] `index.html` returns `no-cache`; fonts return `max-age=31536000`
- [ ] No service account keys exist: `gcloud iam service-accounts keys list --iam-account=$DEPLOY_SA` shows only the Google-managed key
- [ ] WIF attribute condition names your repo exactly
- [ ] `production` environment requires a reviewer
- [ ] Uptime check and 5xx alerting live
- [ ] Cloud Armor rules taken out of preview after a week of clean logs
- [ ] Rollback rehearsed at least once

Before it takes a real donation:

- [ ] CSP tightened off `'unsafe-inline'`
- [ ] Backend deployed; server-side pricing, signed webhook, reservation locks
- [ ] Cloud SQL restore tested
- [ ] Penetration test done and findings closed
- [ ] Privacy policy names the hosting region
- [ ] Everything in the "Before opening a PR" and safeguarding sections of `CLAUDE.md`
