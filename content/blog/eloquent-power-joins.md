---
title: Eloquent Power Joins
date: 2020-03-31T09:05:46-03:00
type: post
tags: ["laravel", "eloquent"]
---

{{< highlight php >}}
<?php

User::joinRelationship('posts.comments', [
    'posts' => function ($join) {
        $join->postIsPublished();
    },
    'comments' => function ($query) {
        $query->commentIsApproved();
    },
])
{{< /highlight >}}

If you ever had to use Joins in Laravel before, you know the above snippet is not possible. This was something I always wished I could do, so I finally end up writting a package to do this.

You can check the package and the full documentation [on Github](https://github.com/kirschbaum-development/eloquent-power-joins). I also wrote an extensive blog post which you can read at the [KDG Blog](https://kirschbaumdevelopment.com/news-articles/adding-some-laravel-magic-to-your-eloquent-joins).

<a href="https://github.com/kirschbaum-development/eloquent-power-joins" target="_blank" class="btn inline text-sm bg-red-400 text-white px-6 py-3 mr-2">View package on Github</a>
<a href="https://kirschbaumdevelopment.com/news-articles/adding-some-laravel-magic-to-your-eloquent-joins" target="_blank" class="btn inline text-sm bg-red-400 text-white px-6 py-3 mr-2">View blog post</a>
