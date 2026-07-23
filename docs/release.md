# Release guide

This document defines the canonical flow for publishing a new version of the image. Follow the steps in order — each one is a precondition for the next.

## Step 1 — Check preconditions

A release can only be made from `main`, with the local branch aligned with `origin/main` and a clean working tree.

> **Run on the development server**

```bash
git branch --show-current
git fetch origin
git rev-parse HEAD
git rev-parse origin/main
git diff --quiet && git diff --cached --quiet
```

If any condition is not met, **abort**. Do not commit, stash or reset automatically to unblock the release.

## Step 2 — Determine the next version

Read the current version:

> **Run on the development server**

```bash
cat VERSION
```

Choose the bump type:

| Type | When to use |
|---|---|
| `patch` | Fixes and minor adjustments |
| `minor` | New features without breaking compatibility |
| `major` | Changes that significantly alter behavior |

Confirm the chosen version before continuing.

## Step 3 — Local gate (smoke test)

Run the smoke test before creating the tag: it builds the image locally, starts a container and validates the runtime (see `docs/testing.md` for what is checked).

> **Run on the development server**

```bash
bash test/smoke.sh
```

If the smoke test fails, **abort**. Do not create a tag on an image that fails the local gate.

## Step 4 — Apply the bump

Update the `VERSION` file and commit:

> **Run on the development server**

```bash
echo "X.Y.Z" > VERSION
git add VERSION
git commit -m "chore: bump VERSION to X.Y.Z"
git push
```

## Step 5 — Publish

Create the release on GitHub. This creates the tag automatically and triggers the build workflow:

> **Run on the development server**

```bash
gh release create vX.Y.Z --title "vX.Y.Z" --notes "Summary of the changes in this version."
```

If the command fails, **abort** and investigate before trying again.

## Step 6 — Validate the external chain

After the push, confirm:

1. **GitHub Actions** — there is a run of the `Build and Release` workflow for the tag; the job finished with `success`.
2. **GHCR** — the `ghcr.io/henricos/devbox` package has the `vX.Y.Z` and `latest` tags published and `Public` visibility.

Wait for the workflow to finish before declaring success. If the workflow fails, report and investigate.

## Step 7 — Final summary

Confirm: previous version, new version, bump type, commit, tag, workflow status and tags published on GHCR.
