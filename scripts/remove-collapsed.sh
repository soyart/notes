#!/bin/sh

find pages -name '*.md' -exec sed -i .bak  '/^.*collapsed::/d' {} \;
