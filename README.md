# async-gem_kit

A template for creating async-native Ruby gems in the `Async::` namespace,
laid out like [`async-matrix`](https://github.com/general-intelligence-systems/async-matrix)
and the rest of the [Socketry](https://github.com/socketry) ecosystem: nested
modules, a matching directory tree, and the `async` gem as a runtime dependency.

## Usage

Create a repo from this template ("Use this template" on GitHub, or `gh` below),
then run the numbered bootstrap scripts in order:

```bash
gh repo create my-org/async-http --template general-intelligence-systems/async-gem_kit --private --clone
cd async-http

bin/01-rename-gem async-http   # rename the gem and its files
bin/02-choose-license          # pick a license interactively
bin/03-update-spec             # fill in authors, summary, homepage, etc.
bin/04-setup                   # bundle install + tidy .gitignore
```

To cut a release later:

```bash
bin/increment-version patch    # major | minor | patch
bin/tag-version                # git tag vX.Y.Z
bin/release-gem                # build + push to RubyGems
```

## Naming

**Every hyphen in the gem name is a directory boundary.** The last segment is the
file (and deepest module); underscores stay within a segment and camelize. The
name must contain at least one hyphen.

```
gem name                       file                                  module
async-http                     lib/async/http.rb                     Async::Http
async-container                lib/async/container.rb                Async::Container
async-job-processor-redis      lib/async/job/processor/redis.rb      Async::Job::Processor::Redis
async-job-adapter-active_job   lib/async/job/adapter/active_job.rb   Async::Job::Adapter::ActiveJob
async-http-protocol-http3      lib/async/http/protocol/http3.rb      Async::Http::Protocol::Http3
```
