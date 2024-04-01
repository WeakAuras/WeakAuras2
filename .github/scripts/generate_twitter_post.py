#!/usr/bin/env python3

import argparse
import re
import subprocess
from pathlib import Path

WEAKAURAS_URL_RELEASE_URL = "https://github.com/WeakAuras/WeakAuras2/releases/tag/{tag}"
MAX_POST_LENGTH = 280

POST_TEMPLATE = """New Release published: {tag}
{highlight_content}
{url}
"""


def get_empty_post_length():
    tag = get_latest_tag()
    release_url = WEAKAURAS_URL_RELEASE_URL.format(tag=tag)
    post = POST_TEMPLATE.format(tag=tag, highlight_content="", url=release_url)
    return len(post)


def run_shell_command(cmd, shell=True, timeout=600, capture_output=False):
    return subprocess.run(
        cmd, shell=shell, timeout=timeout, capture_output=capture_output
    )


def get_changelog_text(changelog_file):
    with open(changelog_file, mode="r") as file:
        content = file.read()

    regex = r"(?<=## Highlights)(.*)(?=## Commits)"
    match = re.search(regex, content, re.DOTALL)

    if not match:
        print("=======================================")
        print('Could not find "Highlights" content.')
        print(content)
        print("=======================================")
        print("Going to provide an empty content.")
        return ""

    return match.group(1).strip()


def shorten_highlight_content(highlight_content):
    base_length = get_empty_post_length()

    # MAX_POST_LENGTH - base_length = max highlight text length
    max_content_length = MAX_POST_LENGTH - base_length

    if len(highlight_content) > max_content_length:
        # We only have 280 characters to play with, so lets reserve {max_content_length} for our own use, then use the rest for the highlight message.
        shortend_content = highlight_content[:max_content_length]
        # this will remove the last 'line', mainly to remove anything that got cut off in the middle and give us more character space.
        shortend_content = shortend_content.split("\n\n")[:-1]
        highlight_content = "\n\n".join(shortend_content)

    return highlight_content


def get_latest_tag():
    return (
        run_shell_command(
            "git describe --tags --always --abbrev=0", capture_output=True
        )
        .stdout.decode()
        .strip()
    )


def generate_twitter_post(content):
    print("generating post")
    tag = get_latest_tag()
    release_url = WEAKAURAS_URL_RELEASE_URL.format(tag=tag)
    post = POST_TEMPLATE.format(tag=tag, highlight_content=content, url=release_url)
    return post


def write_post_to_file(post):
    print("writing post to file")
    with open("twitter_post.txt", mode="w") as twitter_post:
        twitter_post.write(post)


parser = argparse.ArgumentParser(
    prog="generate_twitter_post",
    description="Reads a changelog file and generates a post suitable for social media sites",
)
parser.add_argument(
    "-c",
    "--changelog",
    dest="changelog_path",
    action="store",
    default="./CHANGELOG.md",
    help="specifies where the changelog file is",
    required=False,
    type=str,
)
args = parser.parse_args()
print(args)


changelog = Path(args.changelog_path)
if not changelog.exists():
    print("No Changelog found..")
    exit(1)


highlight_content = get_changelog_text(changelog)
highlight_content = shorten_highlight_content(highlight_content)
latest_tag = get_latest_tag()
post = generate_twitter_post(highlight_content)
write_post_to_file(post)
