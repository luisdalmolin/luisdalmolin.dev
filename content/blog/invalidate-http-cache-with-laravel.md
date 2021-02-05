---
title: Invalidating HTTP cache with Laravel
date: 2020-11-12T09:05:46-03:00
type: post
tags: ["laravel", "http", "cache"]
---

Do you know when the user of your application logs out, and then hit the back button and he can still see the page? Or you have some analytics events that should only be dispatched once, but when the user hits the back button it dispatches again, even though your code is not setting that up anymore?

This happens because when you hit the back button in the browser, the browser, by default, is not going to make a new request, and instead it is going to use what it has in the cache. This happens because of the Cache-Control (and/or a few others) HTTP headers.

The default value of the **Cache-Control** header is `private`.

> Designates content that may be stored by the user's browser, but may not be cached by any intermediate caches. Often used for user-specific, but not particularly sensitive, data. Mutually exclusive with public.

So, the only thing you have to do to invalidate HTTP cache, is control the HTTP headers to do what you want. To invalidate cache from when you hit the back button, for instance, here's what you can use:

{{< highlight php >}}
<?php

return response($content)
    ->header('Cache-Control', 'nocache, no-store, max-age=0, must-revalidate');
{{< /highlight >}}

Or, with a view response:

{{< highlight php >}}
<?php

return response()
    ->view('dashboard')
    ->header('Cache-Control', 'nocache, no-store, max-age=0, must-revalidate');
{{< /highlight >}}

To make your life and reuse easier, I'd suggest you create a middleware that automatically applies this header, and then you can just use it directly in your routes file.

{{< highlight php >}}
<?php

namespace App\Http\Middleware;

use Closure;

class NoHttpCacheMiddleware
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        return $response
            ->header('Cache-Control', 'nocache, no-store, max-age=0, must-revalidate');
    }
}
{{< /highlight >}}

And then, on your routes file, you can simply attach the middleware:

{{< highlight php >}}
<?php

use App\Http\Middleware\NoHttpCacheMiddleware;

Route::get('dashboard')->middleare(NoHttpCacheMiddleware::class);
{{< /highlight >}}

Another header that can be useful is the [ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag), where you can send the "version" of the content of the page. So, if the "version" did not change since the last time, the browser won't bother downloading the content from your server and it will simply use the cache. A practical example on how you can implement this very simply with Laravel:

{{< highlight php >}}
<?php

namespace App\Http\Middleware;

use Closure;

class ApplyETagHttpHeaderMiddleware
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        return $response
            ->header('ETag', md5($response->content()));
    }
}
{{< /highlight >}}

There's also the [Expires](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expires) header can also be used for controlling HTTP cache, but, and I quote:

> If there is a Cache-Control header with the max-age or s-maxage directive in the response, the Expires header is ignored.

Anyway, caches are hard. You know the saying, right?

Check out some more in depth informations about HTTP Caching [here](https://developer.mozilla.org/pt-BR/docs/Web/HTTP/HTTP).