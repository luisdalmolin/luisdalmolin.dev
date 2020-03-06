#!/bin/bash

hugo
netlify deploy --prod --dir public
open https://app.netlify.com/sites/luisdalmolindev/deploys
