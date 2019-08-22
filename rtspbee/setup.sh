#!/bin/bash

ln -s -f ../../hooks/pre-commit $(git rev-parse --git-dir)/hooks/pre-commit
