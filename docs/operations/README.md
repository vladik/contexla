# Operating Contexla

> The Operations Console reports the unified Tool and Tool Invocation model
> defined in [Tool architecture and runtime](../architecture/tool-runtime.md).

Contexla's first deployment model is one organization per installation. An
installation consists of one platform release, PostgreSQL, durable Artifact
storage, and the curated trusted packages selected for the customer Solution.

- [Installation and upgrades](installation.md)
- [Backup and restore](backup-and-restore.md)

The platform exposes unauthenticated infrastructure probes with no customer
content:

```text
GET /health/live   process/HTTP liveness
GET /health/ready  database, storage, Oban, and runtime registry readiness
```

Use liveness only to decide whether the process should be restarted. Use
readiness to decide whether the installation should receive traffic.

## Administrator Operations Console

An installation administrator can open `/operations` from the platform
sidebar. The console refreshes every 15 seconds and presents:

- the bounded readiness checks;
- installed Application, Integration, and Tool counts;
- registered Application package versions and OTP running state;
- recent Application Operation and Tool Invocations;
- recent Oban background jobs;
- recent append-only audit activity;
- Application Instance links and short support reference IDs.

The header action downloads a sanitized support bundle for remote diagnosis.
See [Support bundles](support-bundles.md) for its allow-list and exclusions.

This is a diagnostic projection, not a second execution or logging system. It
never exposes invocation inputs or outputs, job arguments, credentials,
Artifact contents, or exception text. Application-owned Runs, evidence,
findings, and reports remain in the owning Application. Installation logs remain
external to the web console and are correlated using the displayed Invocation
or job identifier.

The console is restricted to users with the `admin` role. In the initial
single-organization deployment model, that role means installation
administrator; there is no separate super-administrator or cross-installation
control plane.

## Support investigation

When an operator reports a failure, collect the Application Instance, time,
requested action, and any Run or Invocation identifier. Then:

1. check `/health/live` and `/health/ready`;
2. open `/operations` and inspect the relevant Operation, Tool Invocation, and job;
3. follow the Instance link and inspect the Application-owned Run and evidence;
4. correlate the support reference with the service or container logs;
5. run `Contexla.Release.diagnostics/0` when the web process cannot provide the
   console;
6. restart only for a process failure, and do not blindly repeat a business
   Operation unless its idempotency semantics permit it.

The console reports retained failure totals, not rolling-window alert metrics.
External uptime checks, process supervision, log collection, and alerting are
still required for production because an unavailable platform cannot report its
own outage.

Run the repository's [operational failure drill](failure-drill.md) after changes
to execution persistence, operational projections, authorization, bundle
contents, or job handling.
