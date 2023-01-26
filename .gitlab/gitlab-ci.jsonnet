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
      "echo \"LOG OF JOB [$JOB_NAME]\"",
      "more \"" + std.extVar('LOGS_DIR') + "\"/\"$JOB_NAME\"/*.txt | cat",
      "echo \"STATUS OF JOB [$JOB_NAME]\"",
      "cat \"" + std.extVar('JOBS_DIR') + "\"/\"$JOB_NAME\"/*",
      "[ \"$(cat " + std.extVar('JOBS_DIR') + "/$JOB_NAME/CONCLUSION)\" = \"success\" ] && exit 0 || exit 1"
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
