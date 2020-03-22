---
title: Different ways to mock HTTP requests in your tests
date: 2019-11-17T09:05:46-03:00
draft: true
type: post
tags: ["#php", "#testing"]
---

Testing HTTP requests is something that can be tricky and confusing. Should you mock the HTTP client entirely? Should you use some stubs for responses? Should you mock the HTTP client at all?

IMO, the best approach is to not mock anything at all. But that’s something that is not always possible for a lot of reasons that could be an entirely new blog post.

For now, let’s just say that you need to write a test for a feature that does a HTTP request and you can’t really make the HTTP request on every test. You have a few options.

**PS:** I’m going to use Guzzle as the HTTP client here as it’s the most used across the PHP community.  I’m also going to write the example tests as I would write for an Laravel application, but the concepts can be ported to other frameworks and other languages as long the HTTP client provides the same options.

Take the following code sample:

{{< highlight php >}}
<?php

use GuzzleHttp\Client;

class PaymentGateway
{
    protected $client;

    public function __construct(Client $client)
    {
        $this->client = $client;
    }

    public function pay($token, $amount)
    {
        $response = $this->client->post('https://payment-provider.com/pay', [
            'json' => [
                'token' => $token,
                'amount' => $amount,
            ]
        ]);

        return jsone_decode($response->getBody()->getContents(), true);
    }
}
{{< /highlight >}}

### Option 1 - Mocks

One of the most used approaches when you need to test an HTTP request without actually making the HTTP request is to completely mock the HTTP client. Let’s see one example of how that looks like.

{{< highlight php >}}
<?php
class PaymentGatewayTest extends TestCase
{
    public function test_http_request_with_mock()
    {
        $httpClient = $this->mock(\GuzzleHttp\Client::Class);
        $httpClient->shouldReceive('post')
            ->with(['some', 'args', 'here'])
            ->andReturn(new \GuzzleHttp\Psr7\Response(200, [], json_encode(['id' => 'PAY-XXX']));

        $paymentProvider = $this->app->make(PaymentProvider::class);
        $paymentProvider->handle();
    }
}
{{< /highlight >}}

This option is going to completely mock the HTTP client. That means that you will not be making any HTTP requests, as well that the Guzzle HTTP client is not even going to be instantiated and passed to the payment provider.

If for some reason the parameters passes to the `post` method on the HTTP client are different than expected, the test will fail. That’s good, we are at least catching something.

### Option 2 - Spies

Spies are very similar as the mock. The main difference is that you don’t set any expectation on the spy, and instead you make assertions after the fact. The code for our test would look something like this:

{{< highlight php >}}
<?php

public function test_http_request_with_spies()
{
    $httpClient = $this->spy(\GuzzleHttp\Client::Class);

    $paymentProvider = $this->app->make(PaymentProvider::class);
    $paymentProvider->handle();

    $httpClient->shouldReceive('post')
        ->with(['some', 'args', 'here'])
        ->andReturn(new \GuzzleHttp\Psr7\Response(200, [], json_encode(['id' => 'PAY-XXX']));
}
{{< /highlight >}}

### Option 3 - Mock Handler

Turns out, there’s a more elegant solution for Guzzle that does not involve mocks and will also test your HTTP client library without actually making any HTTP request.

You will also write your tests based on the response they get instead of methods calls that happen internally in your app.

First, let’s talk about the first 2 options. They are fine, they work and they return what in theory would . But using mock or spies can be dangerous sometimes. Let’s write a test using Guzzle MockHandler.

{{< highlight php >}}
<?php

public function test_http_request_with_mock_handlers()
{
    $mock = new \GuzzleHttp\Handler\MockHandler([
        new Response(200, [], ['id' => 'PAY-XXX']),
    ]);

    $handlerStack = \GuzzleHttp\HandlerStack::create($mock);
    $client = new \GuzzleHttp\Client(['handler' => $handlerStack]);

    $paymentProvider = new PaymentProvider($client);
    $paymentProvider->handle();
}
{{< /highlight >}}

Things that could break your application and a mocked guzzle instance would no caught:

1. Update Guzzle version
2. ...

### Final thoughts

Tests are about giving you confidence on your code. Confidence to refactor, to upgrade dependencies. The more deeply you test your code, greater are the chances of catching new bugs before production.

If you can do this with an elegant solution, I don’t know about you, but I’m all for it.
