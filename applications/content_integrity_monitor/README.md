# Content Integrity Monitor

An independent Contexla Application that detects important facts that are
missing, delayed, unavailable, or inconsistent across authoritative sources
and delivered digital representations.

The first vertical slice monitors three program facts across JSON authority,
JSON delivery, public HTML, and search HTML sources. It owns Monitors, Sources,
Facts, Runs, Observations, Issues, and Evidence in the `contexla_integrity`
PostgreSQL schema. It requests exact extraction Tool versions through the
Application SDK and never depends on platform modules.

See `docs/product/content-integrity-monitor-v1.md` at the repository root for
the product contract and explicit v1 boundaries.

```powershell
mix deps.get
mix test
mix contexla.application.package
```
