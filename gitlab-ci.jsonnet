local template(job) =
  {
    image: "alpine:latest",
    stage: "From Github Actions",
    needs: [
      {
        job: "get-gh-log",
        artifacts: true
      }
    ],
    script: [
      "more gh-act/logs/$job/*.txt | cat",
      "[ \"$(cat gh-act/jobs/$job/CONCLUSION)\" = \"success\" ] && exit 0 || exit 1"
    ]
  };

function(jobs)
{
  stage: [
    "Test on GH reports",
  ]
} + {
  ['gh-act/' + job]: template(job),
  for job in jobs
}

