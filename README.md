# graph

The `konradodwrot` workspace's dependency graph, as data. Five files, each with
one job, so a change moves exactly the file that owns it.

| file | holds | moved by |
|---|---|---|
| `artifacts.yml` | identity: `type`, `versionEnvVar` | editing a producer's declaration |
| `latest-artifacts.yml` | the latest published version per artifact | a producer's release |
| `dependency-graph.yml` | unversioned edges | a dependency changing |
| `desired-dependency-graph.yml` | versioned edges, from the applied CI variables | `ci-variables` applying |
| `current-dependency-graph.yml` | versioned edges, as consumers resolved them | a consumer merging a bump |

Identity appears once, in `artifacts.yml`. Edge shape appears once, in
`dependency-graph.yml`. The two versioned graphs carry versions only, so a
lagging repo is a line-level diff between them.

## Three states, not two

- **latest** — a producer released, a tag exists.
- **desired** — an operator raised the pin, the CI variable says so.
- **current** — a consumer merged the bump and recorded it in its `.repo/`.

They differ in normal operation. `configs` can be published at `v0.0.20` while a
consumer's project variable deliberately holds `v0.0.18`: that is a pin sitting
behind on purpose, not drift. Convergence is `desired == current`; when the two
differ the system has not finished adopting a release, and the diff names
exactly what is behind.

## This repo holds data only

No Ruby, no build, no release, no tags. `.gitlab-ci.yml` carries a single
`EmitEvents` job, because a commit here is a state change other things react to.

Four files are written by `cross-repo/automation`, which aggregates every repo's
`.repo/` declarations, clones this repo, writes and commits.
`desired-dependency-graph.yml` comes from `cross-repo/infra/ci-variables`
instead: it owns the applied variables, and automation's aggregation runs with
no GitLab token, so it cannot read them.

**Never hand-edit these files.** A hand edit is drift, and the next
regeneration overwrites it. Change the repo's `.repo/dependency-graph.yml`
instead, which is where the facts actually live.

## Why the history matters

`git log` here is a chronological record of every version that moved anywhere in
the workspace, and `git diff` between any two commits answers "what changed in
the system between these points". That record stays readable only because
nothing else lives in this repo.

## Reading an entry

An artifact is a versioned addressable thing, identified by its `uri`:

```yaml
# artifacts.yml
artifacts:
  us-central1-docker.pkg.dev/staging-499418/ci/ci-linux:
    type: ociImage
    versionEnvVar: OCI_IMAGES_CI_LINUX_REF
```

`uri` is where it is published, and `versionEnvVar` is the bare CI variable name
carrying its version (`GRP_KO_VAR_` at group scope, `REPO_VAR_` at project
scope).

`dependsOn` states which upstreams each artifact is built from. An upstream no
artifact lists has its version recorded and nothing else: no build, no release.

```yaml
# dependency-graph.yml
dependsOn:
  us-central1-docker.pkg.dev/staging-499418/ci/ci-linux:
    - gitlab.com/konradodwrot/go-modules/che
  us-central1-docker.pkg.dev/staging-499418/ci/ci-linux-dind: []
```

The versioned graphs repeat that shape, each edge carrying the version the
consuming repo holds or targets:

```yaml
# current-dependency-graph.yml
dependsOn:
  us-central1-docker.pkg.dev/staging-499418/ci/ci-linux:
    - {artifact: gitlab.com/konradodwrot/go-modules/che, version: che/v0.0.95}
```

A version reads `unknown` when no repo records one for that edge: a `go.work`
sibling a repo builds against without pinning it.

The `dependsOn` block is the merge of every repo's own
`.repo/dependency-graph.yml`.
