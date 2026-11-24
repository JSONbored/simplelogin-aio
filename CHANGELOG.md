# Changelog

All notable changes to this project will be documented in this file.

## v4.83.6-aio.1 - 2026-11-24

### Fixes

- Update SimpleLogin to 4.83.6 and repair mail startup (#204)

## v4.81.4-aio.1 - 2026-06-18

### Maintenance

- Bump simplelogin to v4.81.4

## v4.81.3-aio.2 - 2026-06-18

### Refactors

- Migrate to the shared aio-base s6 overlay (#97)

## v4.81.3-aio.1 - 2026-06-12

### Maintenance

- Refresh fleet manifest contract

- Bump simplelogin to v4.81.3 (#95)

### Tests

- Use shared app test helpers

## v4.81.2-aio.1 - 2026-05-31

### Maintenance

- Bump simplelogin to v4.81.2

## v4.81.0-aio.1 - 2026-05-28

### Maintenance

- Bump simplelogin to v4.81.0

## v4.80.6-aio.4 - 2026-05-26

### Documentation

- Add CA readme and utility category

## v4.80.6-aio.3 - 2026-05-20

### Fixes

- Enforce verified TLS for SMTP relays

- Prevent DKIM symlink ownership takeover

- Harden internal Postgres auth defaults

- Restrict SimpleLogin state dir permissions

- Default registration to disabled

## v4.80.6-aio.2 - 2026-05-17

### Documentation

- Clarify simplelogin registration mailbox

## v4.80.6-aio.1 - 2026-05-17

### Maintenance

- Bump simplelogin to v4.80.6 (#73)

## v4.80.4-aio.1 - 2026-05-05

### Build

- Harden apt package installs

### CI

- Use shared AIO build workflow
- Centralize release workflows
- Repin shared workflow ref
- Centralize workflow drift checks
- Repin caller workflows
- Pin shared validation policy
- Use shared AIO workflows
- Sync workflow path filters
- Sync catalog publication state
- Pin publish helper workflow fix
- Pin next-wave aio-fleet workflows
- Pin Docker Hub primary workflow
- Pin control-plane workflow foundation

### Dependency Updates

- Update SimpleLogin to v4.80.3

### Documentation

- Document central app test dependencies

### Features

- Expose manual publish targets

### Fixes

- Normalize simplelogin CA name and fleet cleanup
- Sync release shim path fallback
- Prefer Docker Hub image metadata

### Maintenance

- Sync shared repository boilerplate
- Move shared automation to aio-fleet
- Declare aio-fleet ownership
- Bump simplelogin to v4.80.4

### Refactors

- Use shared derived repo validation
- Use shared release helper shim
- Remove legacy shared contract tests

### Tests

- Repin workflow expectation

## v4.80.1-aio.2 - 2026-04-25

### CI

- Allow manual awesome-unraid sync
- Require Trunk uploads and PR integration
- Gate releases on validated CI and template checks
- Run integration tests for release metadata commits
- Align release and pytest tooling with fleet
- Preserve changelog history and publish release commits
- Capture integration diagnostics on pytest failure
- Standardize fleet tool configuration
- Centralize fleet plugin config
- Centralize trunk config and gate release tags
- Accept squash release titles
- Pin package tags to release targets
- Fetch history for release tag lookup
- Consolidate pytest workflow steps

### Dependency Updates

- Update trunk-io/analytics-uploader action to v2
- Update dependency pytest to v9 [security]

### Documentation

- Clarify config field instructions
- Tighten CA metadata
- Add donation links
- Add buy me a coffee

### Fixes

- Unblock first login and tighten required fields
- Support encoded external database credentials
- Sync relay mode with catalog
- Enforce catalog-safe option syntax
- Handle admin fido env quirks
- Harden simplelogin AIO runtime and template
- Make derived repo validator portable
- Use workflow file selector for CI checks
- Classify local action changes
- Fail fast on init errors

### Other Changes

- Merge branch 'main' into codex/manual-awesome-sync
- Migrate smoke tests to pytest
- Merge branch 'main' into codex/ci-diagnostics-fixes
- Merge branch 'main' into codex/release-target-immutability

### Tests

- Use docker volumes for runtime persistence
- Add derived repo guardrail validation
- Cover action and container contracts

## v4.80.1-aio.1 - 2026-04-16

### Dependency Updates

- Bump dockerfile frontend digest

### Documentation

- Clarify in-app SimpleLogin feature coverage

### Features

- Align simplelogin-aio with sure-aio parity

### Fixes

- Skip no-op release drafts
- Make releases manual and gate heavy workflows
- Harden publish and changelog range
- Expose full upstream env surface

## v4.79.0-aio.1 - 2026-03-31

### Dependency Updates

- Update non-major infrastructure updates
- Update docker/setup-buildx-action action to v4
- Update docker/login-action action to v4
- Update docker/build-push-action action to v7
- Pin dependencies

### Documentation

- Add badges to README
- Enhanced README formatting, added shields/badges, improved layout, and embedded animated Star History chart.
- Add repository guidance

### Features

- Initial release SimpleLogin-AIO v1.0.0 — self-host email aliases, replace Proton Unlimited
- True AIO architecture bundle. Included internal Postgres, Redis, and Postfix to eliminate external container dependencies. Rewrote XML to provide a simple, binhex-style UX for new users with advanced external DB fallback support.
- Added categorized advanced variables for self-hosted maximalists. Included mapping for generic OIDC (Tailscale/Authelia), SpamAssassin offloading, PGP encryption, and self-hosted telemetry (Plausible/Sentry).
- Added fully automated foolproof PGP Server Key generation script triggered by XML toggle. Prints public key to docker logs for secure, air-gapped export.
- Added Postfix auto-configurator, JWT auto-generator for OIDC Provider support, Apple SSO vars, HIBP integration, and completely rewrote setup docs to match the new AIO architecture.
- Add git-cliff release workflow

### Fixes

- Install xz-utils before extracting s6-overlay tarballs
- Tighten changelog spacing

### Maintenance

- Clean up internal research artifacts and draft docs, standardize XML filename
- Standardize README, add FUNDING.yml, and clean up legacy files
- Standardize template
- Add template sync workflow
- Revert to verifiable bot identity for non-repudiation

### Other Changes

- Force rebuild to publish docker image
- Security & CI: Fix node24 deprecation and package write permissions
- Harden simplelogin-aio runtime, workflows, and upstream tracking
- Add Codex repo memory notes
- Add renovate.json
- Merge branch 'main' into codex/harden-simplelogin-aio
- Point template icon at awesome-unraid
- Reduce smoke-test CI usage
- Standardize repo metadata files
- Add standard community templates
- Consolidate CI workflows
- Refresh runtime and consolidate CI workflows
- Merge main into consolidate-ci-workflows
- Fix smoke test bind mount permissions
- Merge remote-tracking branch 'origin/main' into codex/fix-template-icons
- Fix awesome-unraid sync for protected main
- Standardize upstream-aligned image tags

<!-- generated by git-cliff -->
