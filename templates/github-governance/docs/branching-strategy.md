# Branching Strategy

## Main branches

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Production-ready code | CI green, no force-push |
| `develop` | Integration branch (optional) | CI green |

## Short-lived branches

```
feature/<ticket>-<short-description>
fix/<ticket>-<short-description>
docs/<topic>
chore/<task>
ci/<change>
```

Examples:

- `feature/DEV-101-add-pr-template`
- `fix/DEV-204-workflow-typo`

## Workflow

1. Branch from `main` (or `develop` if used).
2. Make small, focused commits with Conventional Commit messages.
3. Open a PR early; use draft PRs for work in progress.
4. Ensure the Governance workflow passes before merge.
5. Squash merge preferred for feature branches; rebase merge for hotfixes when audit trail matters.

## Release tags

Tag releases as `vMAJOR.MINOR.PATCH` on `main` after merge:

```bash
git tag -a v1.2.0 -m "Release 1.2.0"
git push origin v1.2.0
```

## Hotfix process

1. Branch `fix/<ticket>-hotfix` from latest `main` tag.
2. Fix, test, PR with expedited review.
3. Merge to `main` and tag patch release.

## Anti-patterns

- Long-lived feature branches diverging weeks from `main`
- Committing secrets or `.tfstate` files
- Mixing unrelated changes in one PR
