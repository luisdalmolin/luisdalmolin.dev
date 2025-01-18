---
title: Ignore files in Git without adding them to .gitignore
date: 2020-03-05T09:05:46-03:00
draft: false
type: post
tags: ["git"]
---

Usually, is better to ignore any files you don’t want to track in either the project local `.gitignore` or your global `.gitignore`.

But, sometimes you just with that git *stop showing you that file you had to change* for some reason we are not here to discuss.

Turns out, is quite simple do to this.

### Ignoring untracked files

This first example is on how to ignore untracked files. A file that is not tracked in git basically means a *new file from git’s perspective* (a file that you never `git add {file} && git commit -m "commit”`).

To ignore untracked files, you have a file in your git folder called `.git/info/exclude`. This file is your own gitignore inside your local git folder, which means is not going to be committed or shared with anyone else. You can basically edit this file and stop tracking any (untracked) file. Here’s what the official [Git - gitignore Documentation](https://git-scm.com/docs/gitignore) says about this file.

> Patterns which are specific to a particular repository but which do not need to be shared with other related repositories (e.g., auxiliary files that live inside the repository but are specific to one user’s workflow) should go into the $GIT_DIR/info/exclude file.

So let’s say you want to ignore your own custom `awesome-setup.sh` file that helps you with some stuff. You just need to add the file to `.git/info/exclude` in the same way you would add it to `.gitignore`.

```
# git ls-files --others --exclude-from=.git/info/exclude
# Lines that start with '#' are comments.
# For a project mostly in C, the following would be a good set of
# exclude patterns (uncomment them if you want to use them):
# *.[oa]
# *~

awesome-setup.sh
```

This approach, though, doesn’t work if you want to ignore files that are *already being tracked* by Git.

### Ignoring files that are already tracked

So here’s the use-case that led me to write this blog-post. I was doing some code review in a Laravel 4.2 application and seeing what would be necessary to upgrade the app. Since the Laravel 4.2 had every config hardcoded, I had to change some configs in order to setup in my local environment. But, I definitely didn’t want to push any of these changes to the repo, even by mistake.

In this case, I used the following commands:

```
git update-index --assume-unchanged app/config/local/database.php
git update-index --assume-unchanged app/config/local/app.php
```

With this, any changes in `app/config/local/database.php` or `app/config/local/app.php` will *not* show up in case I run `git status`.
