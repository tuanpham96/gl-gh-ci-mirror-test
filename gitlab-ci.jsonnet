local template(job) =
  {
    image: "alpine:latest",
    stage: "test",
    needs: [
      # {
      #   # job: "get-gh-log",
      #   job: "trigger-report",
      #   artifacts: true
      # }
      {
        pipeline: "$PARENT_PIPELINE_ID",
        job: "get-gh-log"
      }
    ],
    script: [
      "ls -a",
      "more gh-act/logs/$job/*.txt | cat",
      "[ \"$(cat gh-act/jobs/$job/CONCLUSION)\" = \"success\" ] && exit 0 || exit 1"
    ]
  };

function(jobs) {
  ['gh-act/' + job]: template(job),
  for job in jobs
}

