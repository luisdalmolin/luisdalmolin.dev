---
title: How to log only errors in Nginx access log
date: 2022-08-31T09:05:46-03:00
draft: false
type: post
tags: ["nginx", "devops"]
---

Sometimes, Nginx access logs can become very noisy. But, they can also have valuable informations. If you want to simply log 400 and 500 errors to help you identify issues (internal errors, 404's, authorization errors, etc), you can use the following snippet for it.

{{< highlight nginx >}}
map $status $loggable
{ 
    ~^[2] 0;
    ~^[3] 0;
    default 1; 
}

server {
    access_log /var/log/nginx/access.log combined if=$loggable;
}
{{< /highlight >}}

If you want to start logging other type of errors or more specific status codes, you just need to adjust the regex and return either `0` (to not log in the access log) or `1` (to log in the access log).