#!/bin/bash

echo "Obtaining Github Actions workflow logs"

# Paths
QUERY_FILE="$GITHUB_ACTIONS_DATA_DIR/query.json"
LOGS_DIR="$GITHUB_ACTIONS_DATA_DIR/logs"
LOG_FILE="$GITHUB_ACTIONS_DATA_DIR/logs.zip"
JOBS_DIR="$GITHUB_ACTIONS_DATA_DIR/jobs"
JOB_FILE="$GITHUB_ACTIONS_DATA_DIR/jobs.json"

# Make directories to store data
if [[ ! -d "$GITHUB_ACTIONS_DATA_DIR" ]]; then
    mkdir "$GITHUB_ACTIONS_DATA_DIR"
fi
mkdir -p "$LOGS_DIR"
mkdir -p "$JOBS_DIR"

# Create curl arguments
_curl_args=(
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
)

# Donwload query, jobs and logs

echo "Downloading query file of workflow"

curl "${_curl_args[@]}" \
    "$GITHUB_ACTIONS_URL"?head_sha=$CI_COMMIT_SHA \
    -o "$QUERY_FILE"

echo "Downloading query job status file"

curl "${_curl_args[@]}" \
    $(jq --raw-output '.workflow_runs[].jobs_url' "$QUERY_FILE") \
    -o "$JOB_FILE"

echo "Downloading query compressed log file"

curl "${_curl_args[@]}" \
    $(jq --raw-output '.workflow_runs[].logs_url' "$QUERY_FILE") \
    -L -o "$LOG_FILE"

unset _curl_args

# Unzip logs
echo "Unzipping log file"

unzip "$LOG_FILE" -d "$LOGS_DIR"
rm "$LOG_FILE"

# Get job statuses
echo "Creating job status files"
find "$LOGS_DIR"  -maxdepth 1 -mindepth 1 -type d -print0 | \
    while read -d $'\0' job_logdir
        do
        job_name="$(basename "$job_logdir")"
        job_dir="$JOBS_DIR/$job_name"
        mkdir -p "$job_dir"
        jq -r ".jobs[] | select(.name==\"$job_name\") | .conclusion" "$JOB_FILE" > "$job_dir"/CONCLUSION
        jq -r ".jobs[] | select(.name==\"$job_name\") | .status" "$JOB_FILE" > "$job_dir"/STATUS
    done

# Create child pipeline config
echo "Generating child pipeline CI file"

jobs_str="$(jq '.jobs[].name' "$JOB_FILE" | tr '\n' ',')"
jsonnet \
    --ext-str LOGS_DIR="$LOGS_DIR" \
    --ext-str JOBS_DIR="$JOBS_DIR" \
    -e \
        "local jobs=[$jobs_str];\
        local ci = import '$CHILD_TEMPLATE'; \
        ci(jobs)" \
    > "$CHILD_CI_FILE"

echo "Content of the generated CI file for child pipeline"

cat "$CHILD_CI_FILE"

# List file
echo "Content in $GITHUB_ACTIONS_DATA_DIR"

ls "$GITHUB_ACTIONS_DATA_DIR"
