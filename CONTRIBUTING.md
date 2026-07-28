# Contributing

Three developers and an AI pair share this repository. These conventions keep the history readable and the two sides in sync.

## Branches

`main` is protected and always deployable. Never commit to it directly.

Branch per milestone or task, named for the milestone in `docs/BUILD_SPEC.md` §6:

```
m1/schema-and-seeders
m3/orders-endpoint
m7/booking-flow
fix/tracking-poll-leak
```

## Commits

Conventional commits, scoped to the side you touched:

```
feat(api): add order status state machine
fix(mobile): cancel poll timer on dispose
docs: correct region list in API contract
chore(ci): cache composer packages
```

A change to `docs/API_CONTRACT.md` lands as one commit touching docs, api and mobile together — that atomicity is why this is a monorepo. Never ship one half of a contract change.

## Pull requests

Open a PR into `main`, wait for CI, get one review. In the description say which milestone, what the acceptance criteria were, and anything the spec got wrong.

## Never commit

`.env` files, credentials, signing keys, real phone numbers, real names, real addresses, real MoMo numbers, or database dumps containing any of the above. This repository is public — a secret pushed once stays in the history even after you delete it. If it happens, rotate the secret first, then rewrite history.
