# Operating Contexla

Contexla's first deployment model is one organization per installation. An
installation consists of one platform release, PostgreSQL, durable Artifact
storage, and the curated trusted packages selected for the customer Solution.

- [Installation and upgrades](installation.md)
- [Backup and restore](backup-and-restore.md)

The platform exposes unauthenticated infrastructure probes with no customer
content:

```text
GET /health/live   process/HTTP liveness
GET /health/ready  database, storage path, and runtime registry readiness
```

Use liveness only to decide whether the process should be restarted. Use
readiness to decide whether the installation should receive traffic.
