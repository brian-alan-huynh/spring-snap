#!/bin/bash

# first, run the other file to load variables from .env file via .sh file, then export to terraform sensitive variabels via export TF_VAR_...

# after that, in this file, run terraform init, plan, and apply -auto-approve
