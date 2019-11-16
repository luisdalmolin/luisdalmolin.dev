---
title: "Using Github Actions to setup CI/CD with Laravel (and MySQL)"
date: 2019-11-10T09:05:46-03:00
draft: false
---

At the time of the writing of this post, Github Actions is out of beta and will be available to everyone in November 13. It is a great option which can automate a lot of things. One of these things is to run your CI/CD pipeline (aka PHPUnit tests).

This blog post will show you how to configure Github actions to run your `phpunit` tests, how to deploy after your tests pass and a few other things. We'll also show you how to connect to a database (MySQL, Postgres or SQLite) to run your test suite.

The first thing we'll need is a docker container with PHP installed that is able to run our Laravel test suite. We, at KDG, put together a [docker container](https://cloud.docker.com/u/kirschbaumdevelopment/repository/docker/kirschbaumdevelopment/laravel-test-runner) specifically for this purpose. The docker container can be found at:

* PHP 7.3: `kirschbaumdevelopment/laravel-test-runner:7.3.0`
* PHP 7.2: `kirschbaumdevelopment/laravel-test-runner:7.2.0`

The Github repository can be found at [Laravel Test Runner Container](https://github.com/kirschbaum-development/laravel-test-runner-container). Please open issues or send pull requests if you find any libraries missing for your needs.

We also created this [example repository](https://github.com/luisdalmolin/laravel-ci-test) which is using the setup mentioned below to run the test suite.

Alright, let's get into it!

## Setting up the Github Action

You may need to tweak a few things, but basically you should be able to just copy and paste the following configuration to your Github actions.

`.github/workflows/ci.yml`

```
on: push
name: CI
jobs:
  phpunit:
    runs-on: ubuntu-latest
    container:
      image: kirschbaumdevelopment/laravel-test-runner:7.3.0

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
```

*Don’t forget to configure your env!*

On this example, I created a `.env.ci` file with some of the configurations. Here is what is important for you to configure in this file:

```
# database
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=test
DB_USERNAME=root
DB_PASSWORD=password
```

 You may need a few tweaks for your own configuration but afterwards you should be able to see the build passing.

![Github Actions Build](https://kirschbaumdevelopment.com/storage/articles/18/WSOwe7y0cbViwkNV5WwL5v7dN0Y3guirkDQGgyGr.png)


## Using PostgreSQL or SQLite instead of MySQL

To use PostgreSQL instead of MySQL, you can easily change the `services` section in your CI config with the following:

```
    services:
      postgres:
        image: postgres:10.8
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test
        ports:
        - 5432:5432
        options: --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5
```

And also change your `.env.ci` DB configuration to:

```
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=test
DB_USERNAME=postgres
DB_PASSWORD=postgres
```

And to use *SQLite*, you should be able to just remove the `services` section entirely, and change your environment configuration to:

```
DB_CONNECTION=sqlite
DB_DATABASE=:memory:
```

## Compiling assets is easy too

If you use the `kirschbaumdevelopment/laravel-test-runner` docker container to run your suite then it already has Node/NPM/Yarn installed. You can install dependencies/compile assets by simply adding a new step into your pipeline:

```
    - name: Install front-end dependencies
      run: |
        npm install
        npm run dev
```

And that should be enough!

## Deploying your code after your test suite passes

You can easily automatically deploy your code ONLY if all of your tests are passing. I’m going to assume you already have an automated way to deploy your code here and will not go into how to do this or all the different options available.

Let’s say you want to deploy to Laravel Forge after your build passes.

```
    - name: Deploy to Laravel Forge
      run: curl ${{ secrets.FORGE_DEPLOYMENT_WEBHOOK }}
```

In this case, you need to register `FORGE_DEPLOYMENT_WEBHOOK` in the repository secrets.

Or, if you want to deploy to Vapor:

```
    - name: Deploy to Laravel Forge
      run: |
        export VAPOR_API_TOKEN="${{ secrets.VAPOR_API_TOKEN }}"
        vapor deploy staging
```

And of course, register `VAPOR_API_TOKEN` in your repository secrets.

## Badges

Github recently implemented the ability to include badges with the last status of your actions. You probably saw some of these around open source projects in the past. If you want to include in your project, you can find the documentation [here](https://help.github.com/en/github/automating-your-workflow-with-github-actions/configuring-a-workflow#adding-a-workflow-status-badge-to-your-repository). But in short, the only thing you need is the following markdown:

```
[![Actions Status](https://github.com/{owner}/{repo}/workflows/{workflow_name}/badge.svg)](https://github.com/{owner}/{repo}/actions)
```

Owner is the owner of the repo, repo is obviouslyobviouslly the repo name, and `workflow_name` is the `name` property in your workflow file (usually line 2).

Below you can see the rendered badge from the example repo I created:

[![Actions Status](https://github.com/luisdalmolin/laravel-ci-test/workflows/CI/badge.svg)](https://github.com/luisdalmolin/laravel-ci-test/actions)

The code for this badge looks like this:

```
[![Actions Status](https://github.com/luisdalmolin/laravel-ci-test/workflows/CI/badge.svg)](https://github.com/luisdalmolin/laravel-ci-test/actions)
```

## Extra: Configuring Laravel Nova on your pipeline

If your Laravel project uses Laravel Nova, you will need to authenticate composer before installing dependencies. You can configure Nova authentication by adding the following step:

```
- name: Configure composer for Laravel Nova
  run:|
    composer config "http-basic.nova.laravel.com" "${{ secrets.NOVA_USERNAME }}" "${{ secrets.NOVA_PASSWORD }}"
```

Also, don’t forget to add `NOVA_USERNAME` and `NOVA_PASSWORD` to your Github Actions secrets. This configuration can be found the repository settings > Actions.
