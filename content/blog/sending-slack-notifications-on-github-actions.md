---
title: Sending Slack notifications after running Github Actions
date: 2020-02-01T09:05:46-03:00
draft: false
type: post
tags: ["ci"]
---

This is simply a short tip post on how to send messages to a slack channel after your github action runs. [This package](https://github.com/marketplace/actions/action-slack) make this very simple. You only need to implement the following markup in your existing Github Action:

{{< highlight yml >}}
    - name: Send Slack notification
      uses: 8398a7/action-slack@v2
      if: failure()
      with:
          status: ${{ job.status }}
          author_name: ${{ github.actor }}
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
{{< /highlight >}}

Make sure you don't forget to add the **SLACK_WEBHOOK_URL** secret on your repo secret settings page.

In the above snippet, the slack action will only be sent if the action fails. But, you can send on a few different conditions:

**Always send the message**

{{< highlight yml >}}
    if: always()
{{< /highlight >}}

**Only if the build succeeds**

{{< highlight yml >}}
    if: success()
{{< /highlight >}}

**Only if the build was cancelled**

{{< highlight yml >}}
    if: cancelled()
{{< /highlight >}}

You can check more about the different bob status check functions [here](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/contexts-and-expression-syntax-for-github-actions).
