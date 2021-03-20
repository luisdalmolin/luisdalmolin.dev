---
title: Using Laravel with a Redis Cluster
date: 2021-03-19T09:05:46-03:00
type: post
tags: ["laravel", "redis"]
---

> Cannot use 'EVAL' with redis-cluster

I was getting this error after switching over from a single Redis instance to a Redis Cluster with multi-nodes, and it took me a while to figure out what was going on. While this happened in a PHP/Laravel application, most of the tips here can be used with any language/framework.

## Wrap your keys in `{}`

From Redis documentation: 

> Redis Cluster supports multiple key operations as long as all the keys involved into a single command execution (or whole transaction, or Lua script execution) all belong to the same hash slot. The user can force multiple keys to be part of the same hash slot by using a concept called hash tags.

In short, make sure you make your keys `{key}` instead of `key`. In Laravel, this can be in a few different places depending for what you are using Redis. You only need to use this approach where Redis will perform "multiple key operations". Since, you cannot tell without digging into the internals, here's my suggestion:

* Wrap your queue names. e.g. `'queue' => '{default}'` in your `config/queue.php` file.
* Anytime your are [interacting directly with Redis](https://laravel.com/docs/8.x/redis#interacting-with-redis). e.g. `Redis::funnel`, `Redis::throttle`, etc.

## Specific Laravel configurations

If you are using a Redis Cluster, there are a few [specific configurations](https://laravel.com/docs/8.x/redis#clusters) you have to make sure you set in your `config/database.php` in the `redis` section.

### Enable the `cluster` option

This option needs to be enabled so Laravel treats your Redis connection as a cluster.

{{< highlight php >}}
<?php 

'cluster' => env('REDIS_CLUSTER_ENABLED', false),
{{< /highlight >}}

### Configure the `clusters` array

Your connection now needs to be configured inside the `clusters` array, instead of just the `default` array key you get by default.

{{< highlight php >}}
<?php 

'cluster' => env('REDIS_CLUSTER_ENABLED', false),

'clusters' => [
    'default' => [
        [
            'host' => env('REDIS_HOST', 'localhost'),
            'password' => env('REDIS_PASSWORD', null),
            'port' => env('REDIS_PORT', 6379),
            'database' => 0,
        ],
    ],
],
{{< /highlight >}}

### Configure the type of sharding you want

From the docs: 

> If you would like to use native Redis clustering instead of client-side sharding, you may specify this by setting the `options.cluster` configuration value to redis within your application's `config/database.php` configuration file:

{{< highlight php >}}
<?php 

'options' => [
    'cluster' => env('REDIS_CLUSTER', 'redis'),
],
{{< /highlight >}}

Don't forget that if you are running a Cluster in production but a single node in other environments, you will need different configuration definitions for the different environments.

Hopefully this helps, this is the post I wish I found when I was dealing with these issues.