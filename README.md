# Bummr

[![CircleCI](https://circleci.com/gh/lpender/bummr.svg?style=svg)](https://circleci.com/gh/lpender/bummr)
[![Code Climate](https://codeclimate.com/github/lpender/bummr/badges/gpa.svg)](https://codeclimate.com/github/lpender/bummr)
[![Test Coverage](https://codeclimate.com/github/lpender/bummr/badges/coverage.svg)](https://codeclimate.com/github/lpender/bummr/coverage)

Updating Gems one by one is a bumm(e)r: especially when one gem causes your build
to fail.

Gems should be updated in [separate commits](http://ilikestuffblog.com/2012/07/01/you-should-update-one-gem-at-a-time-with-bundler-heres-how/).

The bummr gem allows you to automatically update all gems which pass your
build in separate commits, and logs the name and sha of each gem that fails.

Bummr assumes you have good test coverage and follow a [pull-request workflow] (https://help.github.com/articles/using-pull-requests/) with `master` as your
base branch.

The base branch can be overridden by setting the environment variable
`BUMMR_BASE_BRANCH` to another branch when running commands.

Please note that this gem is *alpha* stage and may have bugs.

## Installation

```bash
$ gem install bummr
```

By default, bummr will use `bundle exec rake` to run your build.

To customize your build command, `export BUMMR_TEST="./bummr-build.sh"`

If you prefer, you can [run the build more than once]
(https://gist.github.com/lpender/f6b55e7f3649db3b6df5), to protect against
brittle tests and false positives.

## Usage:

Using bummr can take anywhere from a few minutes to several hours, depending
on the number of outdated gems you have and the number of tests in your test
suite.

- After installing, create a new, clean branch off of your base branch.
- Run `bummr update`. This may take some time.
- `Bummr` will give you the opportunity to interactively rebase your branch
  before running the tests. Delete any commits for gems which you don't want
  to update and close the file.
- At this point, you can leave `bummr` to work for some time.
- If your build fails, `bummr` will attempt to automatically remove breaking
  commits, until the build passes, logging any failures to `/log/bummr.log`.
- Once your build passes, open a pull-request and merge it to your base branch.

##### `bummr update`

- Finds all your outdated gems
- Updates them each individually, using `bundle update --source #{gemname}`
- Commits each gem update separately, with a commit message like:

`Update gemname from 0.0.1 to 0.0.2`

- Runs `git rebase -i your_base_branch` to allow you the chance to review and make changes.
- Runs `bummr test`

##### `bummr test`

- Runs your build script (`.bummr-build.sh`).
- If there is a failure, runs `bummr bisect`.

##### `bummr bisect`

- `git bisect`s against your base branch.
- Finds the bad commit and attempts to remove it.
- Logs the bad commit in `log/bummr.log`.
- Runs `bummr test`.

## Notes

- Bummr assumes you have good test coverage and follow a [pull-request workflow]
  (https://help.github.com/articles/using-pull-requests/) with `master` as your
  base branch.
- Once the build passes, you can push your branch and create a pull-request!
- You may wish to `tail -f log/bummr.log` in a separate terminal window so you
  can see which commits are being removed.
- Bummr conservatively updates gems using `bundle update --source gemname`
- Bummr automatically rebases out commits which fail the build using an "ours"
  merge strategy.
- Bummr may not be able to remove the bad commit due to a merge conflict, in
  which case you will have to remove it manually, continue the rebase, and
  run `bummr test` again.

## Developing

`rake build` to build locally

`gem install --local ~/dev/mine/bummr/pkg/bummr-X.X.X.gem` in the app you
wish to use it with.

`rake` will run the suite of unit tests.

I'd like to create feature tests, but because Bummr relies on command line
manipulations which need to be doubled, I'm waiting on [this
issue](https://github.com/bjoernalbers/aruba-doubles/issues/5)

## Thank you!

Thanks to Ryan Sonnek for the [Bundler
Updater](https://github.com/wireframe/bundler-updater) gem.
