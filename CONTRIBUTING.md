# Contributing to WeakAuras 2

## Pull Requests

If you want to help, here's what you need to do:

1. Make sure you have a [GitHub account](https://github.com/signup/free).
2. [Fork](https://github.com/WeakAuras/WeakAuras2/fork) our repository.
3. Create a new topic branch (based on the `master` branch) to contain your feature, change, or fix.
    ```
    $ git checkout -b my-topic-branch
    ```
4. Set `core.autocrlf` to true.
    ```
    $ git config core.autocrlf true
    ```
5. Take a look at our [Wiki](https://github.com/WeakAuras/WeakAuras2/wiki/Developing-WeakAuras) page on how to setup a Lua dev environment.
5. Commit and push your changes to your new branch.
    ```
    $ git commit -a -m "commit-description"
    $ git push
    ```
7. [Open a Pull Request](https://github.com/WeakAuras/WeakAuras2/pulls) with a clear title and description.

### Keeping your fork updated
  * Specify a new remote upstream repository that will be used to sync your fork (you only need to do this once).
    ```
    $ git remote add upstream https://github.com/WeakAuras/WeakAuras2.git
    ```
  * In order to sync your fork with the upstream WeakAuras 2 repository you would do
    ```
    $ git fetch upstream
    $ git checkout master
    $ git rebase upstream/master
    ```
  * You now are synced with the latest changes in the WeakAuras 2 repository.

## Reporting Issues and Requesting Features
1. Please search our [WowAce](https://www.wowace.com/projects/weakauras-2/issues) and [GitHub](https://github.com/WeakAuras/WeakAuras2/issues) issue trackers for your problem since there's a good
   chance that someone has already reported it.
2. If you find a match, please try to provide as much info as you can,
   so that we have a better picture about what the real problem is and how to fix it ASAP.
3. If you didn't find any tickets with a problem similar to yours then please open a
   [new ticket](https://trac.mpc-hc.org/ticket/newticket)
   * Be descriptive as much as you can.
   * Provide everything the template text asks you for.