---
title: "Testing if event listeners are attached to events in Laravel"
date: 2020-09-03T16:31:30-03:00
draft: false
type: post
tags: ["laravel", "events"]
---

I really like the [event system](https://laravel.com/docs/8.x/events) in Laravel. It's a really nice way to perform side-effects in applications by having a completely separated class where I can test in isolation. I usually prefer to write a unit test for event listener than to write a full feature test which touches all parts of the application where I might have to mock half of the services. To me, this kind of separation ends up creating reliable tests which don't break when they shouldn't, and this is really key for having a maintainable test suite.

One thing I always wanted to assert in my listeners unit tests though, and have never found a good way, is a check that verifies if my event listener is attached to the correct event(s). A test like test may seem unnecessary, but your future self and any future developers refactoring this code will thank you.

{{< highlight php >}}
<?php

class SendShipmentNotificationTest extends TestCase
{
    public function test_is_attached_to_event()
    {
        $this->assertListenerIsAttachedToEvent(
            App\Listeners\SendShipmentNotification::class,
            App\Events\OrderShippedEvent::class
        );
    }
}
{{< /highlight >}}

Really simple, right? if it breaks, the message was given to the developer making the refactor. Let's take a look on how the implementation of `assertListenerIsAttachedToEvent` looks like:

{{< highlight php >}}
<?php

use ReflectionFunction;
use Illuminate\Events\Dispatcher;

public function assertListenerIsAttachedToEvent($listener, $event)
{
    $dispatcher = app(Dispatcher::class);

    foreach ($dispatcher->getListeners(is_object($event) ? get_class($event) : $event) as $listenerClosure) {
        $reflection = new ReflectionFunction($listenerClosure);
        $listenerClass = $reflection->getStaticVariables()['listener'];

        if ($listenerClass === $listener) {
            $this->assertTrue(true);

            return;
        }
    }

    $this->assertTrue(false, sprintf('Event %s does not have the %s listener attached to it', $event, $listener));
}
{{< /highlight >}}

This wasn't big enough to make a package and I don't see this fitting anywhere exactly in Laravel for a contribution, so I thought I would at least share this here.

---

That's all. I hope you found this article helpful. Be sure to hit me up on Twitter at [@luisdalmolin](https://twitter.com/luisdalmolin) if you have any feedback.


**UPDATE:** 

I've changed my mind, and I've opened a [PR against Laravel](https://github.com/laravel/framework/pull/36690). So, since Laravel v8.34.0, there's a new `Event::assertListening` assertion you can use. You can check out usage in the [Laravel docs](https://laravel.com/docs/8.x/mocking#event-fake).