# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
# 2024.1 系 Command-Line Tools。SDK コンポーネント自体は sdkmanager が最新安定版を取得する。
ARG CMDLINE_TOOLS_REV=11076708

ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_AVD_HOME=/home/android/.android/avd \
    DISPLAY=:0 \
    PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/emulator:/opt/android-sdk/platform-tools:${PATH}

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        openbox \
        openjdk-17-jre-headless \
        novnc \
        procps \
        python3-numpy \
        tini \
        unzip \
        websockify \
        x11-utils \
        x11vnc \
        xvfb \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 android \
    && useradd --create-home --uid 1000 --gid android --shell /bin/bash android \
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
    && chown -R android:android /home/android /opt/android-sdk

COPY --chmod=0755 docker/android-emulator/entrypoint.sh /usr/local/bin/start-android

USER android
WORKDIR /home/android
EXPOSE 6080

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/start-android"]
