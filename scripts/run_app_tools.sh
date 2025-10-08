#!/bin/bash

set -e

# runs backend python pytest and pylint scripts to test the app and analyze its code. first script to run the ci/cd pipeline. after that, run the approval step; after approval step, run terraform prod sh