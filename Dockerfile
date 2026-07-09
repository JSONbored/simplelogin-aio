# syntax=docker/dockerfile:1@sha256:2780b5c3bab67f1f76c781860de469442999ed1a0d7992a5efdf2cffc0e3d769
# checkov:skip=CKV_DOCKER_3: s6-overlay requires root init for bundled services before daemons drop privileges
ARG UPSTREAM_VERSION=v4.81.5
ARG UPSTREAM_IMAGE_DIGEST=sha256:669efa24250e8f93d0e5163bc904862970bbb096865a8f788bd909e86e9d1b0a
FROM jsonbored/aio-base:s6-3.2.1.0@sha256:07db479a01a95ba28480b4605f5d1cc8bedb574b77cf167ee46e29b9558fee90 AS aio-base

FROM simplelogin/app-ci:${UPSTREAM_VERSION}@${UPSTREAM_IMAGE_DIGEST}


LABEL org.opencontainers.image.source="https://github.com/JSONbored/simplelogin-aio" \
      org.opencontainers.image.title="simplelogin-aio" \
      org.opencontainers.image.description="SimpleLogin packaged as a single-container Unraid AIO image"

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/code/.venv/bin:${PATH}"
ENV PYTHONWARNINGS="ignore::SyntaxWarning"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Shared, pinned s6-overlay from the fleet aio-base overlay.
COPY --from=aio-base /aio-overlay/ /

# trunk-ignore(hadolint/DL3008)
RUN aio-harden pre && \
    apt-get update && apt-get -y dist-upgrade && apt-get install -y --no-install-recommends \
    curl \
    xz-utils \
    ca-certificates \
    netcat-openbsd \
    postgresql \
    postgresql-contrib \
    redis-server \
    postfix \
    postfix-pgsql && \
    python3 -c "from pathlib import Path; env_py = Path('/code/migrations/env.py'); old = \"config.set_main_option('sqlalchemy.url', DB_URI)\\n\"; new = \"config.set_main_option('sqlalchemy.url', DB_URI.replace('%', '%%'))\\n\"; contents = env_py.read_text(); old in contents or (_ for _ in ()).throw(SystemExit('Unable to patch /code/migrations/env.py for escaped DB_URI handling')); env_py.write_text(contents.replace(old, new, 1))" && \
    python3 -c "from pathlib import Path; config_py = Path('/code/app/config.py'); old = \"ADMIN_FIDO_REQUIRED = os.environ.get(\\\"ADMIN_FIDO_REQUIRED\\\", \\\"none\\\")\\nif ADMIN_FIDO_REQUIRED not in (\\\"none\\\", \\\"any\\\", \\\"hardware\\\"):\\n    raise ValueError(\\\"ADMIN_FIDO_REQUIRED is not a valid value\\\")\\n\"; new = \"ADMIN_FIDO_REQUIRED = (os.environ.get(\\\"ADMIN_FIDO_REQUIRED\\\") or \\\"none\\\").strip()\\nif \\\"|\\\" in ADMIN_FIDO_REQUIRED:\\n    ADMIN_FIDO_REQUIRED = next((option for option in ADMIN_FIDO_REQUIRED.split(\\\"|\\\") if option in (\\\"none\\\", \\\"any\\\", \\\"hardware\\\")), \\\"none\\\")\\nif ADMIN_FIDO_REQUIRED not in (\\\"none\\\", \\\"any\\\", \\\"hardware\\\"):\\n    raise ValueError(\\\"ADMIN_FIDO_REQUIRED is not a valid value\\\")\\n\"; contents = config_py.read_text(); old in contents or (_ for _ in ()).throw(SystemExit('Unable to patch /code/app/config.py for ADMIN_FIDO_REQUIRED compatibility')); config_py.write_text(contents.replace(old, new, 1))" && \
    python3 -c "import logging; logging.getLogger().setLevel(logging.ERROR); import flanker.addresslib._parser.parser" && \
    useradd --system --create-home --home-dir /home/simplelogin --shell /usr/sbin/nologin simplelogin && \
    chmod 711 /root && \
    mkdir -p /appdata/postgres /appdata/redis /appdata/dkim /appdata/sl/upload /pgp /custom-assets /run/postgresql && \
    chown -R postgres:postgres /appdata/postgres /run/postgresql && \
    chown -R redis:redis /appdata/redis && \
    chown -R simplelogin:simplelogin /appdata/sl /pgp /custom-assets && \
    rm -f /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/certs/ssl-cert-snakeoil.pem && \
    rm -rf /tmp/* /var/lib/apt/lists/*

COPY rootfs/ /

RUN find /etc/cont-init.d -type f -exec chmod +x {} \; && \
    find /etc/services.d -type f -name "run" -exec chmod +x {} \;

EXPOSE 7777 25
VOLUME ["/appdata", "/pgp"]

ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=300000
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -fsS http://127.0.0.1:7777/health >/dev/null || exit 1

ENTRYPOINT ["/init"]
