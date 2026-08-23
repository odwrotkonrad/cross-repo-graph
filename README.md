# graph

The `konradodwrot` workspace's dependency graph, as data. Three files, all
written by `cross-repo/automation`, all generated from the repos' own
`.repo/` declarations.

| file | what it holds |
|---|---|
| `bare-system-graph.yml` | every artifact and dependency. No versions. |
| `desired-system-graph.yml` | bare + the version each upstream *should* be |
| `current-system-graph.yml` | bare + the version each upstream *is* |

Convergence is `desired == current`. When the two differ the system has not
finished adopting a release, and the diff names exactly what is behind.

## This repo holds data only

No Ruby, no build, no release, no tags. The generator lives in
`cross-repo/automation`, which clones this repo, writes the files and commits.
`.gitlab-ci.yml` carries a single `EmitEvents` job, because a commit here is a
state change other things may react to.

**Never hand-edit these files.** A hand edit is drift, and the next
regeneration overwrites it. Change a repo's `.repo/artifacts-graph.yml`
instead, which is where the facts actually live.

## Why the history matters

`git log` here is a chronological record of every version that moved anywhere
in the workspace, and `git diff` between any two commits answers "what changed
in the system between these points". That record stays readable only because
nothing else lives in this repo.

## Reading an entry

An artifact is a versioned addressable thing, identified by its `uri`:

```yaml
artifacts:
  us-central1-docker.pkg.dev/staging-499418/ci/ci-linux:
    type: oci-image
    git-uri: https://gitlab.com/konradodwrot/cross-repo/infra/oci-images
    version-env-var: OCI_IMAGES_CI_LINUX_REF
```

`git-uri` is the repo that builds it, `uri` is where it is published, and
`version-env-var` is the bare CI variable name carrying its version
(`GRP_KO_VAR_` at group scope, `REPO_VAR_` at project scope).

`depends_on` states which upstreams each artifact is built from. An upstream no
artifact lists has its version recorded and nothing else: no build, no release.

```yaml
depends_on:
  us-central1-docker.pkg.dev/staging-499418/ci/ci-linux:
    - gitlab.com/konradodwrot/go-modules/che
  us-central1-docker.pkg.dev/staging-499418/ci/ci-linux-dind: []
```

This is the same syntax each repo uses in its own `.repo/artifacts-graph.yml`:
the graph's block is the merge of every repo's block.
