---
title: "Using Laravel Translations in Javascript"
date: 2018-03-15T16:31:30-03:00
draft: false
type: post
tags: ["#laravel", "#translations"]
---

Have you ever wanted to use the same Laravel translations you use on the back-end in your front-end code, like Vue.js, Angular?

[Laravel Translations Loader](https://github.com/kirschbaum-development/laravel-translations-loader) is a webpack loader that enables you to load your Laravel translations into your javascript bundle.

Instead of doing HTTP requests or anything like that, what the package does is to read and normalize your translations files (including PHP keyed translations files) during the asset compilation process. It normalizes to a javascript object format so you can use how you like.

It works out of the box with packages like [vue-i18n](https://kazupon.github.io/vue-i18n/en/) or with a few configurations with the popular [i18next](https://www.i18next.com/).

# Show me the code

Basically, in your javascript file, you just need to include the following line to import your language bundle.

```javascript
import languageBundle from
'@kirschbaum-development/laravel-translations-loader!@kirschbaum-development/laravel-translations-loader';
```

This will load and parse all your language files, including PHP and JSON translations. The `languageBundle` will look something like this:

```javascript
{
    "en": {
        "auth": {
            "failed": "These credentials do not match our records."
        }
    },
    "es": {
        "auth": {
            "failed": "Estas credenciales no coinciden con nuestros registros."
        }
    }
}
```

Along with all other translations you may have on your translations folder.

There's options for loading either just PHP or JSON translations files, as well to add a namespace between the lang keys and the actual translations that some packages require. You can check the different loading options on the [readme](https://github.com/kirschbaum-development/laravel-translations-loader) of the project. And please fill an [issue](https://github.com/kirschbaum-development/laravel-translations-loader/issues) if you have any troubles or suggestions.

# Example using [vue-18n](https://github.com/kazupon/vue-i18n)

Notice you can directly pass the `languageBundle` object as a parameter into the `VueI18n` constructor.

```javascript
import languageBundle from '@kirschbaum-development/laravel-translations-loader!@kirschbaum-development/laravel-translations-loader';
import VueI18n from 'vue-i18n';
Vue.use(VueI18n);
const i18n = new VueI18n({
    locale: window.Locale,
    messages: languageBundle,
})
```

And on any vue component, you can just use the `$t` function, like the following example:

```javascript
<template>
    <span>{{ $t('auth.failed') }}</span>
    <!-- this will output the same as {{ trans('auth.failed') }} using Laravel -->
</template>
```
