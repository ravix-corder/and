# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
# 2024.1 系 Command-Line Tools。SDK コンポーネント自体は sdkmanager が最新安定版を取得する。
ARG CMDLINE_TOOLS_REV=11076708

ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_AVD_HOME=/home/android/.android/avd \
    DISPLAY=:0 \
    PATH=/opt/android-python/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/emulator:/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/35.0.0:${PATH}

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        apache2-utils \
        ca-certificates \
        curl \
        nginx \
        libpulse0 \
        openbox \
        openjdk-17-jre-headless \
        novnc \
        procps \
        python3 \
        python3-pip \
        python3-venv \
        python3-numpy \
        python3-tk \
        libxtst6 \
        tini \
        unzip \
        websockify \
        x11-utils \
        x11vnc \
        xvfb \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system android \
    && useradd --system --create-home --gid android --shell /bin/bash android \
    && mkdir -p /opt/android-sdk/cmdline-tools \
    && curl --fail --location --retry 5 --retry-all-errors \
        "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_REV}_latest.zip" \
        --output /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools \
    && mv /tmp/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest \
    && rm -rf /tmp/cmdline-tools /tmp/cmdline-tools.zip \
    && yes | sdkmanager --licenses > /dev/null \
    && sdkmanager \
        "emulator" \
        "platform-tools" \
        "build-tools;35.0.0" \
        "platforms;android-34" \
        "system-images;android-34;google_apis_playstore;x86_64" \
    && mkdir -p /home/android/.android/avd \
    && echo "no" | avdmanager create avd \
        --force \
        --name remote_android_14 \
        --package "system-images;android-34;google_apis_playstore;x86_64" \
        --device "pixel_7" \
    && printf '%s\n' \
        'hw.keyboard=yes' \
        'hw.ramSize=2048' \
        'vm.heapSize=512' \
        'disk.dataPartition.size=8G' \
        'hw.gpu.enabled=yes' \
        'hw.gpu.mode=swiftshader_indirect' \
        >> /home/android/.android/avd/remote_android_14.avd/config.ini \
    && python3 -m venv /opt/android-python \
    && /opt/android-python/bin/pip install --no-cache-dir \
        mss \
        pyautogui \
        openai \
        huggingface_hub \
        transformers \
    && chown -R android:android /home/android /opt/android-sdk /opt/android-python

COPY docker/android-emulator/nginx.conf /etc/nginx/nginx.conf
COPY docker/android-emulator/viewer.html /usr/share/nginx/html/viewer.html
COPY --chmod=0755 docker/android-emulator/entrypoint.sh /usr/local/bin/start-android
COPY --chmod=0755 docker/android-emulator/verify-python-environment.py /usr/local/bin/verify-python-environment

USER android
WORKDIR /home/android
EXPOSE 6080

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/start-android"]
