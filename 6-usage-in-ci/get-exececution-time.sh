#!/bin/bash

# Retrieve job data from Github API
jobs=$(gh api -X GET /repos/MajorBreakfast/local-kubernetes-comparison/actions/runs/4393894177/jobs --paginate)

echo $jobs | jq '
  .jobs
  | map({ run: (.name | split(" / ") | .[0] ), job: (.name | split(" / ") | .[1] ), duration: ((.completed_at | fromdate) - (.started_at | fromdate)) })
  | group_by(.job)
  | map( [{key: "job", value: .[0].job }] + map({key: .run, value: .duration}) )
' | jq -r '(.[0] | map(.key)), (.[] | map(.value)) | @csv' > 6-usage-in-ci/timings.csv

echo $jobs | jq '
  .jobs
  | map({ run: (.name | split(" / ") | .[0] ), job: (.name | split(" / ") | .[1] ), duration: ((.completed_at | fromdate) - (.started_at | fromdate)) })
  | group_by(.job)
  | map( [{key: "job", value: .[0].job }, {key: "average", value: (map(.duration) | add / length) }])
' | jq -r '(.[0] | map(.key)), (.[] | map(.value)) | @csv' > 6-usage-in-ci/timings-average.csv
