# nosemgrep:github.workflows.config.dockerfile-source-not-pinned
FROM ubuntu:22.04 as installer
ENV DEBIAN_FRONTEND noninteractive
ENV PATH="${PATH}:/root/.local/bin"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# TODO: https://github.com/python-poetry/poetry/issues/3591
# Install pandas via pip to get wheel. Disabling the new installer/configuring a wheel source does not work.
RUN apt-get update && apt-get install --no-install-recommends -y -q \
    ca-certificates \
    curl \
    gcc \
    git \
    libcairo2-dev \
    libev-dev \
    python3 \
    python3-dev \
    python3-pip \
    python3-pyqt5 \
    python3-pyqt5.sip && \
    curl -sSL https://install.python-poetry.org | python3 - --version 1.7.1 && \
    poetry config virtualenvs.create false && \
    python3 -m pip install --no-cache-dir --upgrade pip
COPY --from=iqtlabs/gamutrf-base:latest /usr/local /usr/local
COPY gamutrflib /gamutrflib/
WORKDIR /gamutrflib
RUN poetry install --no-interaction --no-ansi --no-dev
WORKDIR /gamutrf
RUN python3 -c "from gamutrflib.zmqbucket import *"
COPY poetry.lock pyproject.toml README.md /gamutrf/
RUN poetry run pip install --no-cache-dir pandas=="$(grep pandas pyproject.toml | grep -Eo '[0-9\.]+')"
# dependency install is cached for faster rebuild, if only gamutrf source changed.
RUN poetry install --no-interaction --no-ansi --no-dev --no-root
COPY gamutrf gamutrf/
COPY bin bin/
COPY templates templates/
RUN poetry install --no-interaction --no-ansi --no-dev

# nosemgrep:github.workflows.config.dockerfile-source-not-pinned
FROM ubuntu:22.04
LABEL maintainer="Charlie Lewis <clewis@iqt.org>"
ENV DEBIAN_FRONTEND noninteractive
ENV UHD_IMAGES_DIR /usr/share/uhd/images
ENV PATH="${PATH}:/root/.local/bin"
RUN mkdir -p /data/gamutrf
# install nvidia's vulkan support if x86.
# hadolint ignore=DL3008
RUN if [ "$(arch)" = "x86_64" ] ; then \
        apt-get update && \
        apt-get install -y --no-install-recommends ca-certificates dirmngr gpg-agent gpg wget && \
        apt-key adv --fetch-keys "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/$(arch)/3bf863cc.pub" && \
        echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/$(arch)/ /" | tee /etc/apt/sources.list.d/nvidia.list && \
        apt-get update && \
        apt-get install -y --no-install-recommends libnvidia-gl-545 ; \
    fi && \
    apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        libblas3 \
        libboost-iostreams1.74.0 \
        libboost-program-options1.74.0 \
        libboost-thread1.74.0 \
        libcairo2 \
        libev4 \
        libfftw3-3 \
        libgl1 \
        libglib2.0-0 \
        liblapack3 \
        libopencv-core4.5d \
        libopencv-imgcodecs4.5d \
        libopencv-imgproc4.5d \
        python3-pyqt5 \
        python3-pyqt5.sip \
        librtlsdr0 \
        libspdlog1 \
        libuhd4.1.0 \
        libunwind8 \
        libvulkan1 \
        libzmq5 \
        mesa-vulkan-drivers \
        python3 \
        python3-zmq \
        uhd-host \
        wget \
        zstd && \
    apt-get -y -q clean && rm -rf /var/lib/apt/lists/*
COPY --from=iqtlabs/gnuradio:3.10.9.2 /usr/share/uhd/images /usr/share/uhd/images
COPY --from=installer /usr/local /usr/local
COPY --from=installer /gamutrf /gamutrf
COPY --from=installer /gamutrflib /gamutrflib
COPY --from=installer /root/.local /root/.local
RUN ldconfig -v
WORKDIR /gamutrflib
RUN poetry install --no-interaction --no-ansi --no-dev
WORKDIR /gamutrf
RUN python3 -c "from gamutrflib.zmqbucket import *"
RUN echo "$(find /gamutrf/gamutrf -type f -name \*py -print)"|xargs grep -Eh "^(import|from)\s"|grep -Ev "gamutrf"|sort|uniq|python3
RUN ldd /usr/local/bin/uhd_sample_recorder
# nosemgrep:github.workflows.config.missing-user
CMD ["gamutrf-scan", "--help"]
