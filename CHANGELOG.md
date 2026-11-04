## [Unreleased]

## [0.5.0] - 2026-11-04

### Added

- Content checks reporting: registry, runner, persistence, and `Kubik::ContentChecksReport` model with upgrade migrations.
- GEO reporting tab, discoverability views, and admin content-resource helpers (checks summary, HTML quality offcanvas hooks).
- `Kubik::Discoverability` integration, social meta backfill tasks, and expanded SEO/reporting admin partials.
- Generators for `last_content_checks_report` / `kubik_content_checks_reports` tables.

### Changed

- Reporting admin helpers and summary indicators; reporting stylesheet for multi-check dashboards.
- Meta tags partial and controller methods for canonical/robots alongside discoverability.
- Upgrade generator covers new reporting columns and content-check tables.

## [0.4.2] - 2026-10-19

### Added

- SEO reporting updates and canonical checks; social share preview refinements.

## [0.4.0] - 2026-10-19

### Added

- Discoverability layer backed by `ai-crawler-index`: bot catalog, policy resolver, robots.txt and llms.txt routes, settings admin sidebar, robots/canonical in `kubik/meta_tags` partial.

## [0.3.2] - 2026-10-13

### Added

- SEO broken-link check optionally flags `data-kubik-nav-broken` / `data-kubik-nav-noncanonical` when kubik_navigation rewrote those links. Markup without those attributes is unchanged (safe to deploy without a navigation gem upgrade).

## [0.3.0] - 2026-09-30

### Fixed

- SEO view helpers and `robots_meta_content` no longer raise when `kubik_meta_tags` SEO columns are missing (e.g. before `rails g kubik:metatagable:upgrade` and `db:migrate`).

## [0.1.11] - 2026-09-28

### Added

- `Kubik::MetatagAdminHelper` and `admin/metatagable/*` partials for shared Active Admin Meta / preview UI.
- `Kubik::Metatagable::SocialMetaResolver` and `KubikMetatagable::SocialMetaImages` for link preview data.
- `register_canonical_path` on configuration for host-specific `og_url` paths.

## [0.1.0] - 2021-06-04

- Initial release.
