---
title: I branched off the wrong branch in Git. How do I fix this?
date: 2020-02-27T09:05:46-03:00
draft: false
type: post
tags: ["git"]
---

You created the pull request on Github (or GitLab, or whatever) to just realize you have created your feature branch off the wrong branch.

Now is showing a lot more files than you actually changed, you will have to explain to the person who is going to review, you are worried that you could mess up Git somehow and a lot of other related thoughts are happening in your head.

Basically, (almost) anything can be fixed in Git, and fixing this kind of problem is pretty simple.

For the sake of the examples, let’s say you have 3 branches:

* `master` - This is your main Git branch, the branch you should have branched off
* `feature/XX-1` - The other feature you was working, and the wrong branch you branched off
* `feature/XX-2` - The feature branch you want to create a PR and that you have created from `feature/XX-1` instead of `master`

On either of the options below, we’ll have the same first 2 steps.

*Step 1*: Create a “backup” branch from our feature branch.

{{< highlight shell >}}
# make sure you are in the correct branch
git checkout feature/XX-2

# create the backup branch
git checkout -b feature/XX-2-bkp
{{< /highlight >}}

*Step 2*: Re-create the feature branch from `master`:

{{< highlight shell >}}
git checkout master
git branch -D feature/XX-2
git checkout -b feature/XX-2
{{< /highlight >}}

Then, we have 2 different options on how to fix our branch.

### Option 1 - Use rebase --onto

{{< highlight shell >}}
git rebase --onto feature/XX-2 feature/XX-1 feature/XX-2-bkp
git push origin feature/XX-2 —force
{{< /highlight >}}

And that’s it. If you are not sure how git rebasing works, you can check it [here]([Git - Rebasing](https://git-scm.com/book/en/v2/Git-Branching-Rebasing)).

### Option 2 - Cherry pick your commits

After executing steps 1 & 2, you only need to cherry pick your commits into the branch and force push to the origin:

{{< highlight shell >}}
git cherry-pick commit-hash-2
git cherry-pick commit-hash-2
git push origin feature/XX-2 —force
{{< /highlight >}}

Please note that you do have to `—force` push since you changed the Git history compared to what’s in Github.

If you are not sure how git rebasing works, you can check it [here](https://git-scm.com/docs/git-cherry-pick).
