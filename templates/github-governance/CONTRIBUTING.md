# Contributing

Thank you for contributing to this repository. These guidelines keep history clean and reviews predictable across the DevOps portfolio.

## Branching

Use short-lived branches from `main`:

```
feature/<ticket>-<short-description>
fix/<ticket>-<short-description>
docs/<topic>
chore/<task>
ci/<change>
```

Examples:

- `feature/DEV-101-add-health-check`
- `fix/DEV-204-workflow-typo`
- `docs/update-readme`

See [`docs/branching-strategy.md`](docs/branching-strategy.md) for merge policy and release tagging.

## Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):

| Type | Use for |
|------|---------|
| `feat` | New capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `chore` | Tooling, deps, housekeeping |
| `ci` | CI/CD workflow changes |
| `refactor` | Code change without behavior change |
| `test` | Tests only |

Examples:

```
feat: add nginx reverse proxy config
fix: correct terraform backend key
docs: document prerequisites in README
ci: add governance workflow
```

## Pull requests

1. Open a PR early; use **draft** for work in progress.
2. Fill out the PR template checklist completely.
3. Keep PRs focused — one logical change per PR.
4. Ensure the **Governance** workflow is green before merge.
5. Prefer **squash merge** for feature branches.

## Security

Never commit:

- Secrets, API keys, or passwords
- `.env` files (use `.env.example` for shape only)
- `*.tfstate` or `.terraform/` directories
- Private keys (`*.pem`, `*.key`)

## Local checks

Before pushing:

```bash
# Verify governance files exist
test -f README.md
test -f CODEOWNERS
test -f CONTRIBUTING.md
test -f .github/pull_request_template.md
```
