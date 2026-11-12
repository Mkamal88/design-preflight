# Changelog

All notable changes to this project are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-11-12

### Added

- In-flight work: the skill finds open, unmerged pull requests for the item and its linked items (parent, sub-tasks, blockers, related) with `gh`, `glab`, tracker development links or branch names, and reads their diffs.
- Each finding has a status: `Open`, `In PR #n` or `Conflicts with PR #n`. The report has an "In-flight work" section.

## [0.1.1] - 2026-11-12

### Changed

- README: a short use case for each lens and each option.
- Intake: list searches ask only for the fields they need, to keep large Jira results small.

## [0.1.0] - 2026-11-12

### Added

- `design-preflight` skill for Claude Code and OpenAI Codex.
- Intake from Jira, GitHub, GitLab, Linear, files and pasted text.
- Five review lenses: database, latency, architecture, security, reliability.
- Constraint-challenging proposals written as decision records with a within-rules alternative.
- `--diff`, `--batch`, `--lens`, `--strict`, `--open`, `--measure` and `--save` modes.
- `detect_stack.sh` for stack detection.
- `install.sh` for user-wide or per-project installs, with uninstall.
- Claude Code plugin marketplace manifest.
