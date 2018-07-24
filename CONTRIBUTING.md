# Contributing to WeakAuras 2

## Pull Requests

If you want to help, here's what you need to do:

1. Make sure you have a [GitHub account](https://github.com/signup/free).
1. [Fork](https://github.com/WeakAuras/WeakAuras2/fork) our repository.

1. Create a new topic branch (based on the `master` branch) to contain your feature, change, or fix.
    ```bash
    > git checkout -b my-topic-branch
    ```

1. Set `core.autocrlf` to true.
    ```bash
    > git config core.autocrlf true
    ```

1. Take a look at our [Wiki](https://github.com/WeakAuras/WeakAuras2/wiki/Lua-Dev-Environment) page on how to setup a Lua dev environment.

1. Install an [EditorConfig](https://editorconfig.org/) plugin for your text editor to automatically follow our indenting rules.

1. Commit and push your changes to your new branch.
    ```bash
    > git commit -a -m "commit-description"
    > git push
    ```

1. [Open a Pull Request](https://github.com/WeakAuras/WeakAuras2/pulls) with a clear title and description.

### Keeping your fork updated

* Specify a new remote upstream repository that will be used to sync your fork (you only need to do this once).
  ```bash
  > git remote add upstream https://github.com/WeakAuras/WeakAuras2.git
  ```
* In order to sync your fork with the upstream WeakAuras 2 repository you would do
  ```bash
  > git fetch upstream
  > git checkout master
  > git rebase upstream/master
  ```
* You are now all synced up.

### Keeping your pull request updated

* In order to sync your pull request with the upstream WeakAuras 2 repository in case there are any conflicts you would do
  ```bash
  > git fetch upstream
  > git checkout master
  > git rebase upstream/master
  ```
* In case there are any conflicts, you will now have to [fix them manually](https://help.github.com/articles/resolving-merge-conflicts-after-a-git-rebase/).
* After you're done with that, you are ready to force-push your changes.
  ```bash
  > git push --force
  ```
* Note: Force-pushing is a destructive operation, so make sure you don't lose something in the progress.
* Your pull request should now have no conflicts and be ready for review and merging.

## Reporting Issues and Requesting Features

1. Please search our [WowAce](https://www.wowace.com/projects/weakauras-2/issues) and [GitHub](https://github.com/WeakAuras/WeakAuras2/issues) issue trackers for your problem since there's a good
   chance that someone has already reported it.
1. If you find a match, please try to provide as much info as you can,
   so that we have a better picture about what the real problem is and how to fix it ASAP.
1. If you didn't find any tickets with a problem similar to yours then please open a
   [new ticket](https://trac.mpc-hc.org/ticket/newticket).
    * Be descriptive as much as you can.
    * Provide everything the template text asks you for.
