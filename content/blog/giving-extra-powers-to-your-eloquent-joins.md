---
title: Giving extra powers to your Eloquent Joins
date: 2020-03-21T09:05:46-03:00
draft: true
type: post
tags: ["#laravel", "#eloquent"]
---

If you have some experience using databases, it is very likely you have used `joins` at least once in your career. Joins can be used for a bunch of different reasons, from selecting data from other tables to limiting the matches of your query.

I'm going to give a few examples on this post, so, to contextualize the examples, imagine we have the following database/models structure.

`User` -> `hasMany` -> `Post`<br>
`Post` -> `hasMany` -> `Comment`<br>
`Post` -> `morphMany` -> `Image`

On Laravel, using eloquent, joining the `posts` table would look something like this:

{{< highlight php >}}
<?php

User::join('posts', 'posts.user_id', '=', 'users.id');
{{< /highlight >}}

In case you want to join the posts and the comments table, your query would look something like this:

{{< highlight php >}}
<?php

User::query()
    ->join('posts', 'posts.user_id', '=', 'users.id')
    ->join('comments', 'comments.post_id', '=', 'posts.id');
{{< /highlight >}}

This is fine and we can understand, but we can do better. We already have all these relationships defined in the models, but we are repeating some of the implementation details when we write the join statements. So, instead of doing this, you can now do this:

{{< highlight php >}}
<?php

// example 1
User::joinRelationship('posts');

// example 2
User::joinRelationship('posts.comments');
{{< /highlight >}}

This is less code to read, and more importantly, easier code to read. It also doesn't have implementation details and it uses the definitions which are already defined in the model relationships. So, if your relationship changes, your joins will be automatically updated.

### Introducing the Eloquent Joins with Extra Powers package*

`joinRelationship` is a method introduced by the [Eloquent Joins with Extra Powers](https://github.com/kirschbaum-development/eloquent-joins-with-extra-powers) package. It works with any type of relationship, including nested relationships and polymorphic relationships.

*What about the Image relationship?*

The `joinRelationship` method also works polymorphic relationships. Besides performing the regular join, it also performs the `{morph}_type == Model::class` check, as you can see below.

{{< highlight php >}}
<?php

Post::joinRelationship('images')->toSql();

// select * from posts
// inner join images on images.imageable_id = posts.id AND images.imageable_id = 'App\\Post'
{{< /highlight >}}

And, it also works with nested relationships.

{{< highlight php >}}
<?php

User::joinRelationship('posts.images')->toSql();

// select * from users
// inner join posts on posts.user_id = users.id
// inner join images on images.imageable_id = posts.id AND images.imageable_id = 'App\\Post'
{{< /highlight >}}

## Querying relationship existence

[Querying relationship existence](https://laravel.com/docs/7.x/eloquent-relationships#querying-relationship-existence) is a very powerful and convenient feature of Eloquent. However, it uses the `where exists` syntax which is not always the best and more performant choice, depending on how many records you have or the structure of your table.

This package also implements a few ways of querying relationship existence using `joins` instead of `where exists`.

Below, you can see the methods this package implements and also the Laravel equivalent.

**Laravel Native Methods**

{{< highlight php >}}
<?php

User::has('posts');
User::has('posts.comments');
User::has('posts', '>', 3);
User::whereHas('posts', function ($query) {
    $query->where('posts.published', true);
});
User::doesntHave('posts');
{{< /highlight >}}

**Package implementations using joins**

{{< highlight php >}}
<?php
User::hasUsingJoins('posts');
User::hasUsingJoins('posts.comments');
User::hasUsingJoins('posts.comments', '>', 3);
User::whereHasUsingJoins('posts', function ($query) {
    $query->where('posts.published', true);
});
User::doesntHaveUsingJoins('posts');
{{< /highlight >}}

## How do I install the package?
You simply need to require the package in your project.

{{< highlight bash >}}
composer require kirschbaum-development/eloquent-joins-with-extra-powers
{{< /highlight >}}

And you should have access to all methods mentioned above. See more at [Github](https://github.com/kirschbaum-development/eloquent-joins-with-extra-powers).
