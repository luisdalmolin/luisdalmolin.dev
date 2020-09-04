---
title: "Rebuilding & Reindexing an Elasticsearch index with zero downtime"
date: 2020-08-20T16:31:30-03:00
draft: true
type: post
tags: ["laravel", "elasticsearch"]
---

I recently worked on implementing a script to rebuild & recreate an Elasticsearch index in a project I work on, and one of the requirements was to do it with zero downtime in search, meaning users will still be able to search while the index is being rebuilt. Another requirement was that we could not loose any kind of data. 

{{< highlight php >}}
<?php

public function handle()
{
    $this->info($message = '[Search] Starting the rebuild & reindexing of the search index. This should take a while...');
    Log::channel('notifications')->info($message);

    $this->setDefaultQueueAsSync();
    $this->setIndexRecreationAsInProgress();
    $this->rebuildAndReindexSwapIndex();
    $this->reindexDocumentsInSwapIndex();
    $this->copySwapIndexIntoDefaultIndex();
    $this->setIndexRebuiltAsDone();

    $this->info($message = '[Search] Finished rebuilding & recreating the search index.');
    Log::channel('notifications')->info($message);
}
{{< /highlight >}}

There’s a bunch of different solutions for this type of problems out there, but I think it’s worth sharing this specific one as it considers a few other things.

The end solution is kind of simple: Rebuild & reindex a "swap" index, and then copy the swap index into the default index once is done. There are some interesting problems in the middle of this, though…

One of the problems is that while the index is being recreated, actions are still being performed in the app, so documents can be added, modified and deleted and jobs will be queued to update those documents in the ES index. So, to make sure we don’t lose any of this data, when the recreate command starts, the first thing it does is adding a key in the cache saying the index recreating is in progress. We've also added a new check into the `IndexDocumentJob`.

{{< highlight php >}}
<?php 

class RecreateIndexCommand extends Command
{
    public function handle()
    {
        Cache::put('search.index-recreation.in-progress', true);
    }
}
{{< /highlight >}}

{{< highlight php >}}
<?php 

class IndexDocumentJob implements ShouldQueue
{
    public function handle()
    {
        if (Cache::has('search.index-recreation.in-progress') 
            && $this->index === DefaultIndex::NAME
        ) {
            $this->release(self::MAX_DELAY_IN_SECONDS);
            return;
        }

        // ...
    }
}
{{< /highlight >}}

After the command is fully done, when these jobs get picked up again by the queue, they will be executed against the new fully rebuilt index.

## Running things synchronously

Another important thing we do is to set the default queue as `sync` for the recreation command process. This makes all the jobs run in sync, so we don’t risk finishing running the command while we still have jobs in the queue for the swap index.

{{< highlight php >}}
<?php 

protected function setDefaultQueueAsSync()
{
    // setting the default queue as sync (for this process only),
    // so when the command finishes running, everything is really done and not in the queue
    config()->set('queue.default', 'sync');
}
{{< /highlight >}}

### When the reindex is done

After everything is done, we simply recreate the default index, and then copy the swap index into the default index. The cache is also cleared so the postponed jobs will now be executed against the default index when the queue workers pick them.

{{< highlight php >}}
<?php 

protected function copySwapIndexIntoDefaultIndex()
{
    Artisan::call(sprintf('search:rebuild-index %s --force', DefaultIndex::NAME));
    Artisan::call(sprintf('search:copy-index %s %s --force', DefaultSwapIndex::NAME, DefaultIndex::NAME));
}

protected function setIndexRebuiltAsDone()
{
    Cache::forget('search.index-recreation.in-progress');
}
{{< /highlight >}}

One of the things I like about this solution is that it doesn’t require any changes in the application configuration to change which ES index the app has to point. It also doesn't require creating any kind of ES aliases.

This command could take a while to run depending on how many documents have to be reindexed, but it’s a one time command, completely automated and completely documented so anyone in the team (We have more than 20 developers working on this project) can perform this task. Also, in case it fails in the middle of the process for any reason, it doesn't impact the default index.

Another thing I is worth pointing out is how we are using the Laravel logging system to send notifications to MS teams, so all the members in the team are aware of the progress of things. The Laravel logging system (mostly since version 5.6) is a piece of beauty that usually doesn’t receive the love it deserves. So thanks for this awesome logging system, [@taylorotwell](https://twitter.com/taylorotwell).

## Which APIs are used in Elasticsearch



## Useful logging to keep an eye on things

In long running processes that run in the background, it’s a lot more useful to have log lines like “[Search] Processing batch 4 of 479” than having a progress bar that as cool as it is, it only really helps in your local machine.

{{< highlight php >}}
<?php 

protected function reindexDocumentsInSwapIndex()
{
    Document::query()
        ->chunk(100, function ($documents, $index) {
            $documents->each(function (CesDocument $document) {
                IndexDocumentJob::dispatch($document, DefaultSwapIndex::NAME);
            });

            $this->comment(sprintf('[Search] Processing batch %s of %s', $index, ceil($this->totalDocuments / 100, 0)));
        });
}
{{< /highlight >}}