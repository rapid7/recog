# Contributing to Recog

The users and maintainers of Recog would greatly appreciate any contributions
you can make to the project.  These contributions typically come in the form of
filed bugs/issues or pull requests (PRs).  These contributions routinely result
in new versions of the [recog gem](https://rubygems.org/gems/recog) and the
[recog release](https://github.com/rapid7/recog/releases) to be released.  The
process for each is outlined below.

## Contributing Issues / Bug Reports

If you encounter any bugs or problems with Recog, please file them
[here](https://github.com/rapid7/recog/issues/new), providing as much detail as
possible.  If the bug is straight-forward enough and you understand the fix for
the bug well enough, you may take the simpler, less-paperwork route and simply
fill a PR with the fix and the necessary details.

## Contributing Code

Recog uses a model nearly identical to that of
[Metasploit](https://github.com/rapid7/metasploit-framework) as outlined
[here](https://github.com/rapid7/metasploit-framework/wiki/Setting-Up-a-Metasploit-Development-Environment),
at least from a ```git``` perspective.  If you've been through that process
(or, even better, you've been through it many times with many people), you can
do exactly what you did for Metasploit but with Recog and ignore the rest of
this document.

On the other hand, if you haven't, read on!

### Fork and Clone

Generally, this should only need to be done once, or if you need to start over.

1. Fork Recog: Visit https://github.com/rapid7/recog and click Fork,
   selecting your github account if prompted
2.  Clone ```git@github.com:<your-github-username>/recog.git```, replacing
```<your-github-username>``` with, you guessed it, your Github username.
3.  Add the master Recog repository as your upstream:
```
git remote add upstream git://github.com/rapid7/recog.git
git fetch --all
```

### Branch and Improve

If you have a contribution to make, first create a branch to contain your
work.  The name is yours to choose, however generally it should roughly
describe what you are doing.  In this example, and from here on out, the
branch will be FOO, but you should obviously change this

```
git fetch --all
git checkout master
git rebase upstream/master
git checkout -b FOO
```

Now, make your changes, committing as necessary, using useful commit messages:

```
vim CONTRIBUTING.md
git add CONTRIBUTING.md
git commit -m "Add a document on how to contribute to recog" -a
```

Please note that changes to [lib/recog/version.rb](https://github.com/rapid7/recog/blob/master/lib/recog/version.rb) in PRs are almost never necessary.

Now push your changes to your fork:

```
git push origin FOO
```

Finally, submit the PR.  Navigate to ```https://github.com/<your-github-username>/recog/compare/FOO```, fill in the details and submit.

## Releasing New Versions

Typically this process is reserved for contributors with push permissions to Recog:

### Release New Gem

1. Get an account on [Rubygems](https://rubygems.org)
2. Contact one of the Recog project contributors and have them add you to the Recog gem
3. Edit [lib/recog/version.rb](https://github.com/rapid7/recog/blob/master/lib/recog/version.rb) and increment ```VERSION```.  Commit and push to origin/upstream master.
4. Run ```rake release```

### Github Release

Some users may prefer to consume recog in a manner other than using git itself.  For that reason, Github offers [Releases](https://github.com/blog/1547-release-your-software).  Whenever a new version of the software is to be released, be kind and also create a new [Release](https://github.com/rapid7/recog/releases), using a versioning scheme identical to that used for the gem


