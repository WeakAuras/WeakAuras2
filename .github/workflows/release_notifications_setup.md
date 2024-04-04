# Setting up Release Notification Hooks

## Requirements

This folder contains a [release_notifications.yml](release_notifications.yml) file that contains workflows for GitHub actions to be able to post an automated message to various social media platforms when a released is published.

For the most part, this file can work plug-and-play into any repo, you simply need to set up the various GitHub 'secrets' so that the workflow knows where to push the updates to. This page will highlight the required pieces for it to work as well as where to find the keys/tokens to use for your notifications.

An important part of the yml is the following block:

```yml
on:
  workflow_dispatch:
  release:
    types: [published]
```

where `workflow_dispatch` will tell GitHub Actions that this job can be run manually, allowing you to run it at will, and the `release` portion saying when a GitHub Release is published. This is the part that will automatically run a release is made.

For this workflow to work, you are required to have the [generate_changelog.sh](../../generate_changelog.sh) script to generate a change log based on the tags during the release process, as well as [generate_twitter_post.py](../scripts/generate_twitter_post.py) to generate a smaller version of the produced changelog to fit within a twitter post.

With these scripts and [release_notifications.yml](release_notifications.yml) you can have automated messages sent to the various social media channels.

There is also a [release_notifications_manual_tests.yml](release_notifications_manual_tests.yml) file that is set up in a similar way, but all the 'secrets' are pre-pended with `TEST_`. You can simply omit this file if you don't think you need it, but this allows you to manually run a separate set of tokens/urls to test out the output before you push to your main channels. To use this, follow the below steps, but add `TEST_` to the start of each secret, and that file will push to that instead.

-------

## Where to save your 'secrets'

GitHub has pretty decent [documentation](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions) for how the secrets work, but i will give a short explanation here.

From your repo go to Settings -> Secrets and variables -> Actions:
![secrets and variables](https://i.imgur.com/IR9PDAG.png)

From here you will see 'Repository secrets'. Here is where you will set up all your tokens and URLs to use for the release notifications.

![secret examples](https://i.imgur.com/bGXW1uk.png)

-------

## API Keys / Tokens for the Notifications

Each application needs their own set of tokens and urls to push to.

### Discord

For Discord, you simply need to set up a webhook to a channel.

Pick a channel, and hit 'edit channel'
![edit channel](https://i.imgur.com/Gr9llZy.png)

Integrations -> View Webhooks
![View Webhooks](https://i.imgur.com/hAY1nqt.png)

Create a new webhook and copy the URL.

Go to your GitHub secrets and save the URL as: `RELEASE_WEBHOOK_URL`

### Twitter

First sign into the Twitter developer portal with the account you want to post with: <https://developer.twitter.com/en>

once you have an account set up you can go to the dashboard: <https://developer.twitter.com/en/portal/dashboard>

For a free twitter developer account you can set up a single 'project', create one.
![project](https://i.imgur.com/Jlu4MId.png)

Once you create the project it will ask you to make an 'app', which will give you API Keys afterwards. Don't worry about these, we are going to regenerate them anyway after the next step.
![app](https://i.imgur.com/3IUNUI3.png)

Once you get your first set of keys/tokens, go to the 'App Settings'. You can get to it from the dashboard on the left side and clicking the name of your app. Towards the bottom, you want to click 'set up' for user authentication settings.
![app settings](https://i.imgur.com/z7AXpfj.png)

From here you want to fill out the information the best you can, but the important parts are the two radio buttons at the top:
![radio buttons](https://i.imgur.com/CJPERMY.png)

'Read and write' are required for your bot to post to Twitter. Set both 'Read and Write' as well as 'Bot' as Type of App, and fill out the rest of the form. The website and callback URL requires `https://` or `http://` at the start to be valid. This will give you a client ID and Client Secret, don't worry about this either, we will regenerate all at once to get everything we need.

Now, we have everything set up to regenerate the keys and save them. Go back to the dashboard, click your app name and then 'Keys and Tokens'
![keys and tokens](https://i.imgur.com/UvWl0f9.png)

From here you will see various tokens. You can 'Regenerate' your `API Key and Secret` and save it in a text file for now. You want both `API Key` and `API Key Secret`.

Next, you want the `Access Token and Secret`. Hit 'Regenerate' and save both `Access Token` and `Access Token Secret`.

**IMPORTANT:** After you save this information ENSURE that the you see `Created with Read and Write permissions` below it. If write permissions are not granted you will not be able to send messages.

Finally, go to GitHub Actions Secrets and save the following information:

```sh
TWITTER_ACCESS_TOKEN
TWITTER_ACCESS_TOKEN_SECRET
TWITTER_API_KEY
TWITTER_API_KEY_SECRET
```

### Mastodon

For Mastodon you only need 2 easy to get items. For the URL you simply provide the URL of the network you're on. For example: <https://mastodon.social>

For the access token you need to make a new application. Go to your Preferences -> Development - and create a new application
![app](https://i.imgur.com/3PW6ztz.png)

From here you can customize the information you want to give it.
![info](https://i.imgur.com/XGCzmZB.png)

Simply submit the application and open it up to see your access token
![submit](https://i.imgur.com/GAtF3uo.png)

```sh
MASTODON_ACCESS_TOKEN
MASTODON_URL # https://mastodon.social
```

### Bluesky

Bluesky only needs 2 items, the handle/identifier to post to (user name or email) and the 'app password'.

To get the 'app password' go to your bluesky settings and click 'App Passwords'
![app password](https://i.imgur.com/kG8oywU.png)

Generate a new app password with a unique name and it will generate a key for you to save.
![key](https://i.imgur.com/gn4x2B6.png)

```sh
BLUESKY_IDENTIFIER # user name or email
BLUESKY_PASSWORD # 'app password'
```

-------

## Running the Workflow

If you want to test the notifications you can go to ACTIONS and check your workflows
![workflow](https://i.imgur.com/npbcEJ6.png)

You can use `Send TEST Release Notification` to test it out. Remember, these will use the pre-pended `TEST_` secrets. This will also use a custom changelog found here:[large_changelog_example.md](../scripts/test_files/large_changelog_example.md).

If for some reason something fails, it is set up in a way to be able to re-run specific notifications. As an example, in this image Mastodon failed.
![failed example](https://i.imgur.com/EXUTZCa.png)

You can view the error and see if you can fix it with the secrets, if you did a copy/paste error and re-run only the mastodon job.

When running a test, normally the changelog will not generate a 'highlights' section, which means the tweet will only include a URL to the latest tag. If the tag is the newest commit, it should work normally.

When you publish a new release with a new tag it will also automatically run, and you can re-run failed jobs as well.

-------

## Example Screenshots with TEST Release Info

Discord

![example discord](https://i.imgur.com/wWFurie.png)

Twitter

![example twitter](https://i.imgur.com/EdTWSCo.png)

Mastodon

![example mastodon](https://i.imgur.com/WBPSjye.png)

Bluesky

![example bluesky](https://i.imgur.com/nFgWJ7O.png)
