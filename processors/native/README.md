# Native Contexla Processors

Trusted BEAM implementations of Contexla Capability contracts. Applications do
not call these modules directly; they request a Capability through the platform
runtime, which resolves a Binding, validates I/O and permissions, runs the
Processor, and records an Invocation.

The first Processor implements `Parse Composer Dependencies` version `1`.
