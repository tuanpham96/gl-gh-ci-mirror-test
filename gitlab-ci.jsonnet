local template(job) =
  {
    image: "alpine:latest",
    stage: "Test on GH reports",
    variables: {
      JOB_NAME: job
    },
    needs: [
      {
        pipeline: "$PARENT_PIPELINE_ID",
        job: "get-gh-log"
      }
    ],
    script: [
      "echo 'LOG OF JOB [$JOB_NAME]'",
      "more gh-act/logs/$JOB_NAME/*.txt | cat",
      "echo 'PROGRESS OF JOB [$JOB_NAME]'",
      "cat gh-act/jobs/$JOB_NAME/*",
      "[ \"$(cat gh-act/jobs/$JOB_NAME/CONCLUSION)\" = \"success\" ] && exit 0 || exit 1"
    ]
  };

function(jobs) {
  "stages": [
      "Test on GH reports"
   ]
} + {
  ['gh-act/' + job]: template(job),
  for job in jobs
}

