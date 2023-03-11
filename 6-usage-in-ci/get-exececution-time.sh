#!/bin/bash

# Retrieve job data from Github API
jobs=$(gh api -X GET /repos/MajorBreakfast/local-kubernetes-comparison/actions/runs/4393373145/jobs)

echo $jobs | jq '.jobs[] | "\(.name) \((.completed_at | fromdate) - (.started_at | fromdate))"'
