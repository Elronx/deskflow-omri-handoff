# Security

This repository contains only reusable source, configuration templates, and
installation guidance. It must never contain passwords, API tokens, private
keys, certificates, signed identity material, personal IP/MAC addresses,
BetterTouchTool databases, logs, or generated machine configuration.

The Mac is the only Deskflow server. Bind it to the selected local LAN
interface and do not expose TCP 24800 to a VPN or public network. Windows UAC
secure desktop stays enabled. Normal Deskflow input cannot approve every
protected Windows prompt; do not weaken UAC as a workaround.

Release prompts pin the downloadable archive by SHA-256. Stop before execution
if the downloaded bytes do not match exactly. The archive contains source
scripts rather than secrets or pre-paired machine identity.

Report a suspected vulnerability privately to the repository owner through
GitHub rather than opening an issue containing sensitive machine details.
