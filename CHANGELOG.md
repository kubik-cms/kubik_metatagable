## [Unreleased]

## [0.3.0] - 2026-09-30

### Fixed

- SEO view helpers and `robots_meta_content` no longer raise when `kubik_meta_tags` SEO columns are missing (e.g. before `rails g kubik:metatagable:upgrade` and `db:migrate`).

## [0.1.11] - 2026-09-28

### Added

- `Kubik::MetatagAdminHelper` and `admin/metatagable/*` partials for shared Active Admin Meta / preview UI.
- `Kubik::Metatagable::SocialMetaResolver` and `KubikMetatagable::SocialMetaImages` for link preview data.
- `register_canonical_path` on configuration for host-specific `og_url` paths.
- `doc/admin_metatagable.md`.

## [0.1.10] - 2026-09-28

### Added

- `kubik/metatagable/social_share_previews` partial for admin link previews via `kubik_interface_elements`.
- `KubikMetatagable::VERSION` constant.

### Changed

- README documents social link preview integration.

## [0.1.0] - 2021-06-04

- Initial release
