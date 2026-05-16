# AI Governance Document — kijani-capstone

## What the AI does

When a Jenkins pipeline smoke test fails, the `diagnose-failure.sh`
script collects three signals from the staging namespace — pod status,
recent events, and pod logs — and sends them to Claude with one
question: what is the most likely cause and what should the engineer
check first?

The response is printed to the Jenkins console output.

## What the AI does not do

- It never triggers a rollback
- It never modifies any Kubernetes resource
- It never makes a deployment decision

## Human review step

After the diagnosis is printed, the pipeline stops with a failure.
The engineer on duty must:

1. Read the AI diagnosis in the Jenkins console
2. Check the raw diagnostic data printed above it
3. Make their own decision — rollback manually, fix the issue, or
   investigate further
4. The AI output is one input among several, not a conclusion

## If the AI is unavailable

If the Claude API is unreachable, the script will print an error
but the pipeline has already failed at the smoke test stage. The
engineer investigates using the raw diagnostic data alone.

## Credential management

The `ANTHROPIC_API_KEY` is stored as a Jenkins credential named
`anthropic-api-key` and injected as an environment variable at
runtime. It is never written to any file or logged to the console.

## Model

- Model: claude
