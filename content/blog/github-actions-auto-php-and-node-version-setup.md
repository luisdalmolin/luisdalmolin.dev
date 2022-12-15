---
title: Setting up your PHP and Node versions on GitHub Actions based on NVM and Composer
date: 2022-12-14T09:05:46-03:00
draft: false
type: post
tags: ["github", "devops", "ci"]
---

When you are using GitHub Actions to run your CI/CD pipelines, setting up (and upgrading) PHP and Node versions can be annoying. If you are using NVM and Composer, you can use the following snippet to setup your PHP and Node versions based on the `.nvmrc` and `composer.json` files.

{{< highlight yaml >}}
- name: Read NVM version from .nvmrc
    run: echo "##[set-output name=NODEVERSION;]$(cat .nvmrc)"
    id: node-version

- name: Read PHP version from composer
    run: echo "##[set-output name=PHPVERSION;]$(cat composer.json | jq '.config.platform.php' | sed 's/^"\(.*\)"$/\1/')"
    id: php-version

- name: Setup PHP (based on composer.json version)
    uses: shivammathur/setup-php@v2
    with:
    php-version: ${{ steps.php-version.outputs.PHPVERSION }}

- name: Setup NodeJS (Based on .nvmrc)
    uses: actions/setup-node@v2
    with:
    node-version: "${{ steps.node-version.outputs.NODEVERSION }}"
    cache: 'npm'
{{< /highlight >}}

This snippet will read the PHP version from the `composer.json`. More specifically the `config->platform->php` configuration (see https://getcomposer.org/doc/06-config.md#platform for more informations).

The Node version will be read from the `.nvmrc` file. If you are not familiar with NVM, you can check it out here: https://github.com/nvm-sh/nvm.

Using this approach, you can have a single source of truth for your PHP and Node versions.