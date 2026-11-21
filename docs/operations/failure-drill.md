# Operational failure drill

The drill validates the support path without breaking or polluting a running
installation. It uses the isolated test database and the same operational query
and support-bundle services used in production.

Run it from `platform/`:

```powershell
mix test test/contexla/operations_failure_drill_test.exs
```

The drill creates temporary test records for:

- a failed declared Application Operation;
- a failed Capability Invocation with an exact Processor reference;
- a discarded Oban job;
- an Application Instance lifecycle audit event;
- generation of an administrator support bundle.

It then opens the generated ZIP in memory and verifies that the Operation,
Capability, job, audit action, safe error codes, and support references can be
correlated. It also plants unique private markers in invocation output, error
details, Oban arguments/errors, audit metadata, content-like input, and the
administrator email and verifies that none occur in any bundle entry.

The drill must pass before changing the support-bundle allow-list. It does not
replace a manual pre-release smoke check of `/operations`, `/health/live`,
`/health/ready`, an actual Application Run, and the deployment's external log
collection.

Do not create a production endpoint that deliberately crashes workers or
modifies runtime health. Controlled failure injection belongs in isolated tests
or a disposable installation.
