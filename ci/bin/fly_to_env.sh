#!/bin/bash

# Sets up a new sandbox deployment pipeline

set -euo pipefail

: $ENVIRONMENT
: $WORKSPACE
: ${CONFIGURATION:="idbr_minutes"}
: ${AWS_REGION:="eu-west-2"}
: ${GENERATOR_VERSION:="v0.4.0"}
: ${BPM_TOOLS_VERSION:="v0.2.0"}
: ${HTTP_PROXY:="localhost:8118"}
: ${BRANCH:="master"}
: ${TARGET:=gcp}
: ${FLY:=fly -t ${TARGET}}
: ${EXTRA_OPTIONS:=""}

if [[ ${WORKSPACE} =~ - ]]; then
    echo "Terraform workspace '${WORKSPACE}' cannot contain '-' (breaks some resource names)"
    exit 1
fi

pattern="^sandbox|cicd|staging|prod$"
if [[ ! ${ENVIRONMENT} =~ $pattern ]]; then
    echo "Unknown environment target '${ENVIRONMENT}' - must match '${pattern}'"
    exit 1
fi

export HTTP_PROXY=${HTTP_PROXY}

repo_name="bpm-sor-$(echo ${CONFIGURATION} | sed 's/_/-/g')"
echo "Using configuration repo: ${repo_name}"

pipeline="${ENVIRONMENT}-${WORKSPACE}-deploy-${CONFIGURATION}-sor"

${FLY} set-pipeline \
    -p ${pipeline} \
    -c ci/pipeline.yml \
    -v "workspace=${WORKSPACE}" \
    -v "aws-appsync-generator-version=${GENERATOR_VERSION}" \
    -v "bpm-tools-version=${BPM_TOOLS_VERSION}" \
    -v "configuration=${CONFIGURATION}" \
    -v "configuration-repo=${repo_name}" \
    -v "aws_region=${AWS_REGION}" \
    -v "environment=${ENVIRONMENT}" \
    -v "tag_filter=*" \
    -v "branch=${BRANCH}" \
    ${EXTRA_OPTIONS}

${FLY} unpause-pipeline \
    -p ${pipeline}
