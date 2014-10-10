# Contributing to Recog

Recog uses a model nearly identical to that of Metasploit as outlined in
https://github.com/rapid7/metasploit-framework/wiki/Setting-Up-a-Metasploit-Development-Environment,
at least from a ```git``` perspective.  If you've been through that
process (or, even better, you've been through it many times with many
people), you can do exactly what you did for Metasploit but with Recog and ignore the rest of this document.

On the other hand, if you haven't, read on!

## Fork and Clone

Generally, this should only need to be done once, or if you need to start over.

1. Fork Recog Visit https://github.com/rapid7/recog and click Fork,
   selecting your github account if prompted
2.  Clone ```git@github.com:<your-github-username>/recog.git```, replacing
```<your-github-username>``` with, you guess it, your Github username.
3.  Add the master Recog repository as your upstream:
```
git remote add upstream git://github.com/rapid7/recog.git
git fetch --all
```

## Branch and Improve

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

Now push your changes to your fork:

```
git push origin FOO
```

Finally, submit the PR.  Navigate to https://github.com/<your-github-username>/recog/compare/FOO, fill in the details and submit.
