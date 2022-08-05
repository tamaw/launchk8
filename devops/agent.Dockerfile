FROM debian:bullseye

ARG PACKAGES="curl libc-dev"
ARG RUNNER_VERSION="2.294.0"
ARG RUNNER_GITHUB_URL="https://github.com/org/proj"
ARG RUNNER_TOKEN="" # 1 hour expiry
ARG RUNNER_LABELS="build,test,deploy"
ARG RUNNER_WORKDIR="/var/_work"

RUN apt-get update -y \
    && apt-get install -y -q ${PACKAGES} \
    && useradd -m agent

RUN mkdir -p /opt/actions-runner \
    && cd /opt/actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

RUN cd /opt/actions-runner \
    && ./bin/installdependencies.sh \
    && chown -R agent:agent .

COPY --from=docker:dind /usr/local/bin/docker /usr/local/bin

USER agent
# ignores failure if already registered
RUN cd /opt/actions-runner \
    && ./config.sh --unattended --url ${RUNNER_GITHUB_URL} --token ${RUNNER_TOKEN} --labels ${RUNNER_LABELS} --replace --work ${RUNNER_WORKDIR} || echo

ENTRYPOINT ["/opt/actions-runner/run.sh"]