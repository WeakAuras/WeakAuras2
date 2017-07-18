## Contributing to WeakAuras 2
* Fork the WeakAuras 2 repository
* Clone your fork to your local disk
* Create a new branch, `Somebug-patch` for example and move into it
  ```
  $ git branch Somebug-patch
  $ git checkout -b Somebug-patch
  ```
* Commit and push your changes to your new branch
  ```
  $ git commit -a -m "New awesome Stuff"
  $ git push
  ```
* When your feature or bug patch is ready simply make a pull request
### Keeping your fork updated
* Specify a new remote upstream repository that will be used to sync your fork (you only need to do this the first time around)
  ```
  git remote add upstream https://github.com/WeakAuras/WeakAuras2.git
  ```
* In order to sync the fork with the original WeakAuras 2 repository you would do
  ```
  $ git fetch upstream
  $ git checkout master
  $ git rebase upstream/master
  ```
* You now are synced with the latest changes in the WeakAuras 2 repository :)
