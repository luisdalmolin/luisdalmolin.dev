---
title: "Using Github Actions to setup CI/CD with Laravel (and MySQL)"
date: 2019-11-10T09:05:46-03:00
draft: false
type: post
---

At the time of the writing of this post, Github Actions is out of beta and will be available to everyone in November 13. It is a great option which can automate a lot of things. One of these things is to run your CI/CD pipeline (aka PHPUnit tests).

This blog post will show you how to configure Github actions to run your `phpunit` tests, how to deploy after your tests pass and a few other things. We'll also show you how to connect to a database (MySQL, Postgres or SQLite) to run your test suite.

The first thing we'll need is a docker container with PHP installed that is able to run our Laravel test suite. We, at KDG, put together a [docker container](https://cloud.docker.com/u/kirschbaumdevelopment/repository/docker/kirschbaumdevelopment/laravel-test-runner) specifically for this purpose. The docker container can be found at:

* PHP 7.4: `kirschbaumdevelopment/laravel-test-runner:7.4`
* PHP 7.3: `kirschbaumdevelopment/laravel-test-runner:7.3`
* PHP 7.2: `kirschbaumdevelopment/laravel-test-runner:7.2`

The Github repository can be found at [Laravel Test Runner Container](https://github.com/kirschbaum-development/laravel-test-runner-container). Please open issues or send pull requests if you find any libraries missing for your needs.

We also created this [example repository](https://github.com/luisdalmolin/laravel-ci-test) which is using the setup mentioned below to run the test suite.

Alright, let's get into it!

## Setting up the Github Action

You may need to tweak a few things, but basically you should be able to just copy and paste the following configuration to your Github actions.

`.github/workflows/ci.yml`
{{< highlight yml >}}on: push
name: CI
jobs:
  phpunit:
    runs-on: ubuntu-latest
    container:
      image: kirschbaumdevelopment/laravel-test-runner:7.3

    services:
      mysql:
        image: mysql:5.7
        env:
          MYSQL_ROOT_PASSWORD: password
          MYSQL_DATABASE: test
        ports:
          - 33306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
    - uses: actions/checkout@v1
      with:
        fetch-depth: 1

    - name: Install composer dependencies
      run: |
        composer install --no-scripts

    - name: Prepare Laravel Application
      run: |
        cp .env.ci .env
        php artisan key:generate

    - name: Run Testsuite
      run: vendor/bin/phpunit tests/
{{< /highlight >}}

Continue reading at https://kirschbaumdevelopment.com/news-articles/using-github-actions-to-setup-ci-cd-with-laravel-and-mysql.
