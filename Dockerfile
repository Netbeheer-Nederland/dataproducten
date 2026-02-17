FROM python:3.13-alpine3.23

# Set environment variables
ENV RUNNING_IN_DOCKER=true
ENV PYTHONUNBUFFERED=1
ENV NODE_PATH=/usr/lib/node_modules
ENV SCRIPTS=/opt/dataproducten
ENV SHELL=/bin/bash

# Whether in CI/CD pipeline or not. Overridden by GitHub Actions if running there.
ENV CI=false

# Install required packages
RUN apk add --no-cache \
    vim=9.1.2132-r0 \
    bash=5.3.3-r1 \
    bc=1.08.2-r0 \
    git=2.52.0-r0 \
    nodejs=24.13.0-r1 \
    npm=11.6.3-r0 \
    uv=0.10.2-r0 \
    just==1.43.1-r0 \
    github-cli=2.83.0-r3 \
    openssh=10.2_p1-r0 \
    tar=1.35-r4

SHELL ["/bin/bash", "-c"]

# Install Python project dependencies
RUN uv pip install --system \
    "linkml==1.9.6" \
    "linkml-asciidoc-generator @ git+https://github.com/Netbeheer-Nederland/linkml-asciidoc-generator.git@v0.6.0-alpha2" \
    "gen-linkml-profile @ git+https://github.com/Netbeheer-Nederland/gen-linkml-profile.git@v0.23.0" \
    "check-jsonschema==0.32.0" \
    "jinja-cli==1.2.2"

# Install Antora and its dependencies
RUN npm i -g \
    http-serve@1.0.1 \
    @antora/cli@3.1.9 \
    @antora/lunr-extension@^1.0.0-alpha.8 \
    @antora/site-generator@3.1.9 \
    @antora/collector-extension@^1.0.2 \
    @mermaid-js/mermaid-cli@^11.4.2 \
    asciidoctor-kroki@^0.18.1 \
    @asciidoctor/reveal.js@^5.2.0 \
    js-yaml@^4.1.1

# Install Mike Farah's yq
RUN wget https://github.com/mikefarah/yq/releases/download/v4.52.2/yq_linux_amd64 -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Copy configuration files
RUN mkdir -p $SCRIPTS
COPY src/scripts $SCRIPTS/

# Install shell completions for just
RUN mkdir -p /usr/share/bash-completion/completions
RUN just --completions bash >> /usr/share/bash-completion/completions/just

# Initialize non-root user
ENV USER=developer
ENV GROUPNAME=$USER
ENV UID=1000
ENV GID=$UID
ENV JUST_WORKING_DIRECTORY=.
ENV JUST_JUSTFILE=$SCRIPTS/justfile

RUN addgroup \
    --gid "$GID" \
    "$GROUPNAME" \
&&  adduser \
    --disabled-password \
    --gecos "" \
    --ingroup "$GROUPNAME" \
    --home /home/developer \
    --uid "$UID" \
    $USER

USER $USER

# Initialize just completions
RUN touch ~/.bashrc && echo 'source /usr/share/bash-completion/completions/just' >> ~/.bashrc

# Metadata
LABEL org.opencontainers.image.source=https://github.com/netbeheer-nederland/dataproducten
LABEL org.opencontainers.image.description="Netbeheer Nederland environment for modeling data products and generating documentation and schemas."
LABEL org.opencontainers.image.licenses=Apache-2.0
