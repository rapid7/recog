# Contributing to Recog

The users and maintainers of Recog would greatly appreciate any contributions
you can make to the project.  These contributions typically come in the form of
filed bugs/issues or pull requests (PRs).  These contributions routinely result
in new versions of the [recog gem](https://rubygems.org/gems/recog) being
released.  The process for everything is described below.

## Table of Contents

1. [Contributing Issues / Bug Reports](#contributing-issues-/-bug-reports)
1. [Contributing Code](#contributing-code)
    1. [Fork and Clone](#fork-and-clone)
    1. [Branch and Improve](#branch-and-improve)
    1. [Testing](#testing)
1. [Fingerprints](#fingerprints)
    1. [Best Practices](#best-practices)
    1. [Fingerprint Testing](#fingerprint-testing)
    1. [Updating CPEs](#updating-cpes)
1. [Project Operations](#project-operations)
    1. [Landing PRs](#landing-prs)

## Contributing Issues / Bug Reports

If you encounter any bugs or problems with Recog, please file them
[here](https://github.com/rapid7/recog/issues/new), providing as much detail as
possible.  If the bug is straight-forward enough and you understand the fix for
the bug well enough, you may take the simpler, less-paperwork route and simply
fill a PR with the fix and the necessary details.

[^back to top](#contributing-to-recog)

## Contributing Code

Recog uses a model nearly identical to that of
[Metasploit](https://github.com/rapid7/metasploit-framework) as outlined
[here](https://github.com/rapid7/metasploit-framework/wiki/Setting-Up-a-Metasploit-Development-Environment),
at least from a ```git``` perspective.  If you've been through that process
(or, even better, you've been through it many times with many people), you can
do exactly what you did for Metasploit but with Recog and ignore the rest of
this document.

On the other hand, if you haven't, read on!

[^back to top](#contributing-to-recog)

### Fork and Clone

Generally, this should only need to be done once, or if you need to start over.

1. Fork Recog: Visit https://github.com/rapid7/recog and click Fork,
   selecting your github account if prompted
1. Clone `git@github.com:<your-github-username>/recog.git`, replacing
`<your-github-username>` with, you guessed it, your Github username.

    ```bash
    git clone git@github.com:<your-github-username>/recog.git
    ```

1. Add the Rapid7 recog repository as your upstream:

    ```bash
    git remote add upstream git@github.com:rapid7/recog.git
    ```

1. Update your `.git/config` to ensure that the `remote ["upstream"]` section is configured to pull both branches and PRs from upstream.  It should look something like the following, in particular the second `fetch` option:

    ```bash
     [remote "upstream"]
      url = git@github.com:rapid7/recog.git
      fetch = +refs/heads/*:refs/remotes/upstream/*
      fetch = +refs/pull/*/head:refs/remotes/upstream/pr/*
    ```

1. Fetch the latest revisions, including PRs:

    ```bash
    git fetch --all
    ```

1. Set up git hooks to help identify potential issues with your contributions:

    ```bash
    ln -sf ../../tools/dev/hooks/pre-commit .git/hooks/pre-commit
    ```

[^back to top](#contributing-to-recog)

### Branch and Improve

If you have a contribution to make, first create a branch to contain your
work.  The name is yours to choose, however generally it should roughly
describe what you are doing.  In this example, and from here on out, the
branch will be FOO, but you should obviously change this:

```bash
git fetch --all
git checkout main
git rebase upstream/main
git checkout -b FOO
```

Now, make your changes, commit as necessary with useful commit messages.

Now push your changes to your fork:

```bash
git push origin FOO
```

Finally, submit the PR.  Navigate to ```https://github.com/<your-github-username>/recog/compare/FOO```, fill in the details and submit.

[^back to top](#contributing-to-recog)

### Testing

When your PR is submitted, it will be automatically subjected to the full run of tests in the [CI workflow](.github/workflows/ci.yml) and the [Verify workflow](.github/workflows/verify.yml), however you are encourage to perform testing _before_ submitting the PR.  To do this, simply run `rake tests`.

[^back to top](#contributing-to-recog)

## Fingerprints

### Best Practices

* Create a single fingerprint for each product as long as the pattern remains clear and readable. If that is not possible, the pattern should be logically decomposed into additional fingerprints.

* Create regular expressions that allow for flexible version number matching. This ensures greater probability of matching a product. For example, all known public releases of a product report either `major.minor` or `major.minor.build` format version numbers. If the fingerprint strictly matches this version number format, it would fail to match a modified build of the product that reports only a `major` version number format.

[^back to top](#contributing-to-recog)

### Fingerprint Testing

Once a fingerprint has been added, the `example` entries can be tested by executing `bin/recog_verify` against the fingerprint file:

```shell
bin/recog_verify xml/ssh_banners.xml
```

Matches can be tested on the command-line in a similar fashion:

```shell
$ echo 'OpenSSH_6.6p1 Ubuntu-2ubuntu1' | bin/recog_match xml/ssh_banners.xml -
MATCH: {"matched"=>"OpenSSH running on Ubuntu 14.04", "service.version"=>"6.6p1", "openssh.comment"=>"Ubuntu-2ubuntu1", "service.vendor"=>"OpenBSD", "service.family"=>"OpenSSH", "service.product"=>"OpenSSH", "os.vendor"=>"Ubuntu", "os.device"=>"General", "os.family"=>"Linux", "os.product"=>"Linux", "os.version"=>"14.04", "service.protocol"=>"ssh", "fingerprint_db"=>"ssh.banner", "data"=>"OpenSSH_6.6p1 Ubuntu-2ubuntu1"}
```

Additionally, in Visual Studio Code, there is a task (.vscode/tasks.json) which will automatically run recog_verify in the background to watch all the XML fingerprint files (under the xml/ subdirectory of this repository). Additionally, if [fswatch](https://github.com/emcrisostomo/fswatch) is installed, whenever XML fingerprint files are added or modified this task will automatically update the Visual Studio Code user interface and highlight any errors or warnings discovered through recog_verify on the correct file/line. You can also manually run the task by bringing up the Visual Studio Code command menu (cmd + shift + P on mac, or ctrl + shift + P for linux/windows) -> Tasks: Run Task -> Recog Verify). Note that in order for the task to run successfully, you must have a valid ruby installed on your PATH with the gems from `bundle install` installed using bundler for that ruby engine. JRuby is not supported as it has issues related to line numbering due to a bug in Nokogiri.

[^back to top](#contributing-to-recog)

### Standardizing Vendors, Products, and Services

Given the number of fingerprints in Recog, it can be common for specific products, vendors, or services to be identified with different spellings and casing.
To limit the creep of slightly-different-names, the `bin/recog_standardize` script can be used to extract all identifiers and merge them into the known lists.

To get started, run the `recog_standardize` tool:

```shell
ruby bin/recog_standardize -w xml/*.xml
```

Review any changes to the text files under `identifiers/`. If any additions are
similar to an existing name, update the offending fingerprint to use the
existing name instead. Once the fingerprints are fixed run the tool again and
verify the results.

[^back to top](#contributing-to-recog)

### Updating CPEs

There exists some automation to update the CPEs that might be asserted with
some recog fingerprints.  This should be run periodically to ensure that all
fingerprints that could have CPEs do, etc.

First, setup a python3 venv:

  ```bash
  python3 -m venv venv
  source venv/{bin,Scripts}/activate
  pip install -r requirements.txt
  ```

Download the latest CPE 2.3 dictionary:

```bash
curl -o official-cpe-dictionary_v2.3.xml.gz https://nvd.nist.gov/feeds/xml/cpe/dictionary/official-cpe-dictionary_v2.3.xml.gz && \
gunzip official-cpe-dictionary_v2.3.xml.gz
```

Run the CPE automation against every XML file:

```bash
# Update the CPEs (sequentially)
ls xml/*.xml | xargs -i python update_cpes.py {} official-cpe-dictionary_v2.3.xml cpe-remap.yaml 2>>errors.txt
```

You may want to use GNU `parallel` to speed things up:
```bash
# Update the CPEs (with GNU Parallel)
ls xml/*.xml | parallel --gnu "python update_cpes.py {} official-cpe-dictionary_v2.3.xml cpe-remap.yaml"  2>>errors.txt
```

Clean up the whitespace across all fingerprints:
```bash
ruby bin/recog_cleanup
```

Any mismatched fingerprints will be listed in `errors.txt` for eventual
maintenance.  The `cpe-remap.yaml` file can be used to map between
vendor/product/etc differences between Recog and CPE, or to work around bugs in
either.

[^back to top](#contributing-to-recog)

## Project Operations

### Landing PRs

(Note: this portion is a work-in-progress.  Please update it as things change)

Much like with the process of submitting PRs, Recog's process for landing PRs
is very similar to [Metasploit's process for landing
PRs](https://github.com/rapid7/metasploit-framework/wiki/Landing-Pull-Requests).
In short:

1. Follow the "Fork and Clone" steps from above
2. Update your `.git/config` to ensure that the `remote ["upstream"]` section is configured to pull both branches and PRs from upstream.  It should look something like the following, in particular the second `fetch` option:

    ```bash
     [remote "upstream"]
      url = git@github.com:rapid7/recog.git
      fetch = +refs/heads/*:refs/remotes/upstream/*
      fetch = +refs/pull/*/head:refs/remotes/upstream/pr/*
    ```

3. Fetch the latest revisions, including PRs:

    ```bash
    git fetch --all
    ```

4. Checkout and branch the PR for testing.  Replace ```PR``` below with the actual PR # in question:

    ```bash
    git checkout -b landing-PR upstream/pr/PR
    ```

5. Test the PR (see the Testing section above)
6. Merge with main, re-test, validate and push:

    ```bash
    git checkout -b upstream-main --track upstream/main
    git merge -S --no-ff --edit landing-PR # merge the PR into upstream-main

    # re-test if/as necessary
    git push upstream upstream-main:main --dry-run # confirm you are pushing what you expect

    git push upstream upstream-main:main # push upstream-main to upstream:main
    ```

7. If applicable, release a new version (see next section)

[^back to top](#contributing-to-recog)
