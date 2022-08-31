---
title: Structuring & testing your Laravel Events & Listeners
date: 2021-03-31T09:05:46-03:00
type: post
tags: ["laravel", "events", "testing"]
original: https://kirschbaumdevelopment.com/insights/structuring-and-testing-your-laravel-events-and-listeners
---

*This post was originally posted in the [Kirschbaum](https://kirschbaumdevelopment.com/insights/structuring-and-testing-your-laravel-events-and-listeners) blog.*

---

Laravel has a great  [eventing system](https://laravel.com/docs/8.x/events#introduction). It allows you to dispatch events and attach a set of event listeners to that specific event which are run automatically. They can run synchronously or asynchronously (by running in the queue).

In this article, we explore one simple, yet powerful and scalable, approach to setting up and testing your events and listeners.

Since everything is better with an example, picture a system that needs to perform a couple of things when a new user signs up.

This is how our controller looks , simple and clean:

{{< highlight php >}}
<?php 

class UsersControllers
{
    public function store(UserCreateRequest $request)
    {
        $user = User::create($request->all());
        
        UserCreated::dispatch($user);
    }
}
{{< /highlight >}}

There are a few actions we need to perform when a new user signs up. Placing them directly in the controller feels a bit weird since they are more like side effects from our main action (user registration). Also, our controller wouldn’t look that good. 

This seems like a perfect case to make use of event listeners, so that’s what we’re going to do. As a bonus here, we’re respecting one of the [SOLID](https://en.wikipedia.org/wiki/SOLID) principles of software development. The *Open/Closed Principle* (OCP) states that “Software entities (classes, modules, functions, etc.) should be open for extension, but closed for modification.”.

{{< highlight php >}}
<?php 

// EventServiceProvider
protected $listen = [
    UserCreated::class => [
        SendUserCreatedNotifications::class,
        CreateSalesAgentCommission::class,
        SyncUserInFancyMarketingSystem::class,
    ],
];
{{< /highlight >}}

## How do we test this?

Besides having good test coverage in our system where we want to be confident when refactoring our code, we want to have tests which are easy to understand and *resilient*. We could spend hours talking about resilient tests, but for now let’s just say that no one likes having to fix a bunch of seemingly unrelated tests because you changed something. A good example might be something like: 

> Why is my user-creation test breaking after I modified the fancy marketing system we integrate with?

So, we’re going to start with our controller. We don’t want our controller test to break when other things change, which leads us to our testing tip number 1.

### Tip 1 - Event::fake() for integration tests

Laravel gives us some **really great** tools for testing. The [mocking](https://laravel.com/docs/8.x/mocking) tools are really great, and in this case we are going to make use of `Event::fake()`.

{{< highlight php >}}
<?php 

class UsersControllerTest extends TestCase
{
    public function test_create_user()
    {
        Event::fake();

        $response = $this->post(route('users.store'), [...imaginary payload here])
            ->assertSuccessful();

        $this->assertDatabaseHas('users', ['name' => 'Luis Dalmolin']);

        Event::assertDispatched(UserCreated::class);
    }
}
{{< /highlight >}}

Our controller test is only making sure the `UserCreated` event was dispatched. It doesn’t assert that email notifications were sent, or if the commission was created. This makes our test more reliable, as it cannot break when any of those things change.

…So, are we done? To have good test coverage in this feature, we’re still missing a couple of things:

* Testing the functionality inside our event listener classes
* Asserting that our listeners are attached to the expected events

### Tip 2 - Unit test your event listeners

In order to keep this article from getting too long, we’re going to choose one of our listeners and use it as an example, but the concepts apply to any event listener. I’m calling this a unit test here because we’ll be manually instantiating the class and performing its actions, even if it touches filesystem, databases, etc. 

{{< highlight php >}}
<?php 

class SendUserCreatedNotificationsTest extends TestCase
{
    public function test_it_send_notifications()
    {
        Notification::fake();
        Mail::fake();

        $user = User::factory()->create();
        $event = new UserCreated($user);
		  $listener = new SendUserCreatedNotifications();
        $listener->handle($event);

        Notification::assertSentTo
($user, WelcomeNotification::class);
        Mail::assertSent(NewUserCreatedAdminNotification::class);
    }
}
{{< /highlight >}}

The most important part of this test is that we’re manually creating (`$listener = new SendUserCreatedNotifications()`) and running `$listener->handle($event)` our listener. We ‘re making sure this job does what it needs to do and  we only care about testing if the notifications are sent. We don’t care how the user gets created (that’s why we’re using the factory) or how the event is dispatched (in this case it’s not being dispatched at all). All of these things are already tested in our controller test.

**…So, can I push my PR? **

We have pretty good test coverage here, but we can still do better.

### Tip 3 - Assert your event listener is attached to the event you expect

{{< highlight php >}}
<?php 

class SendUserCreatedNotificationsTest extends TestCase
{
    public function test_is_attached_to_event()
    {
        Event::fake();
        Event::assertListening(
            SendUserCreatedNotifications::class,
            UserCreated::class
        );
    }
}
{{< /highlight >}}

Simple as that. `Event::assertListening` is a [recent contribution](https://github.com/laravel/framework/pull/36690) I made to the Laravel framework, and it covers this missing gap between asserting the events are dispatched and unit testing your event listeners code.

It’s a simple test, but it can save you from situations like when a giant git rebase results in accidentally removing one listener while fixing the conflicts on the `EventServiceProvider`.

### What about Model Observers?

You may have noticed that instead of dispatching the `UserCreated` event in our controller, we could have simply dispatched the event directly in a [model observer](https://laravel.com/docs/8.x/eloquent#observers). 

Using model observers can be really handy, but since they are global, they will run everywhere. For instance, in our code where we use our user factory, we would have to do something in order to avoid sending notifications, mocking our HTTP integration with our marketing system, and so on.

However, I still think there’s space for model observers. Since deciding when to use model observers vs. event listeners isn’t trivial, I tend to ask this question:

> Is this action something that always needs to happen from the developer OR from the client perspective?

If you ask your client whether every time a user is created, it should go to the marketing system, he is going to answer **yes, 100%**. But from a developer perspective, you don’t want the user going there when you’re testing your code, for instance.

Now, if from the developer perspective you should **always** assign an UUID to the model when it gets created, then yes, model observers are the way to go.

## Final thoughts

This approach may seem simple, but it can grow with your application while also maintaining good test coverage by having tests that don’t break easily. Your test suite will also run faster since you aren’t running unrelated code in your tests.

Good code is code that is easy to move around (or delete). You have total control whether to run your listeners synchronously or asynchronously.

Even if you don’t follow this, hopefully this article was helpful to you in some way.