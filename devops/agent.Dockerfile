FROM debian:bullseye

# ARG PACKAGES="curl jq libdigest-sha-perl"
ARG PACKAGES="curl"
ARG RUNNER_VERSION="2.294.0"
ARG RUNNER_GITHUB_URL="https://github.com/org/proj"
ARG RUNNER_TOKEN="" # 1 hour expiry
ARG RUNNER_LABELS="brnln"
ARG RUNNER_WORKDIR="/var/agent-jobs"

RUN apt-get update -y \
    && apt-get install -y -q ${PACKAGES} \
    && useradd -m agent

RUN mkdir -p /actions-runner \
    && cd /actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

RUN cd /actions-runner \
    && ./bin/installdependencies.sh \
    && chown -R agent:agent /actions-runner

USER agent
# ignores failure if already registered
RUN cd /actions-runner \
    && ./config.sh --unattended --url ${RUNNER_GITHUB_URL} --token ${RUNNER_TOKEN} --labels ${RUNNER_LABELS} --replace --work ${RUNNER_WORKDIR} || echo

ENTRYPOINT ["/actions-runner/run.sh"]