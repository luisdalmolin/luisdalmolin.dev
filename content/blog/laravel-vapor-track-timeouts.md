---
title: "Laravel Vapor: How to track which routes are timing out"
date: 2023-11-23T16:31:30-03:00
draft: false
type: post
tags: ["laravel", "vapor", "lambda"]
---

If you're using Laravel Vapor, you might encounter the `Task timed out after x seconds` error, indicating that the Lambda function running your code exceeded the configured timeout.

This log message is not very helpful, as it doesn't give you any additional information or context, like which route or command are timing out. This happens because the Lambda function itself is not aware of details of Laravel and how it handles requests.

To track this, we can make use of the PHP `pcntl` functions with a simple Laravel middleware. Let's see how this looks like.

First, we need to create a new HTTP middleware. Let's call it `TrackLambdaTimeoutsMiddleware`.

```shell
php artisan make:middleware TrackLambdaTimeoutsMiddleware
```

Do not forget to register the middleware in your `app/Http/Kernel.php` file.

```php
protected $middleware = [
    VaporTimeoutLogger::class,
    // ...
];
```

```php
class TrackLambdaTimeoutsMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        if (! isset($_ENV['AWS_REQUEST_ID'])) {
            return $next($request);
        }

        pcntl_signal(SIGALRM, function () use ($request) {
            logger()->warning('[Timeout] Vapor function timed out', [
                'request' => $request->all(),
                'url' => $request->url(),
                'aws_request_id' => $_ENV['AWS_REQUEST_ID'] ?? null,
            ]);
        });

        pcntl_async_signals(true);
        pcntl_alarm(29); // Make sure to make this value match your Vapor timeout, minus 1 second

        return $next($request);
    }
}
```

This middleware will start its "timer" in the background, and if the function is still running after 29 seconds, it will log a warning message with the request data so you can know what route is failing. You should add more contextual information here as it makes sense to your application.

**Important:** Make sure to update the `pcntl_alarm` value to match your function's timeout, minus 1 second. We need to make sure the function triggers and logs the message before the Lambda function times out and the whole process gets killed. This value should be taken from your `vapor.yml` configuration file, under the `timeout` key.

If you don't specify any value, Vapor's default timeout is 10 seconds.

```yaml
environments:
    staging:
        timeout: 30
```