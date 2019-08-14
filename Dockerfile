FROM jenkins2_slave

USER root

ENV ANDROID_SDK_TOOLS_VERSION="4333796" \  
    ANDROID_NDK="/opt/android-ndk" \
    ANDROID_NDK_HOME="/opt/android-ndk" \
    # Get the latest version from https://developer.android.com/ndk/downloads/index.html
    ANDROID_NDK_VERSION="15c" \
    ANT_HOME="/usr/share/ant" \
    MAVEN_HOME="/usr/share/maven" \
    GRADLE_HOME="/usr/share/gradle" \
    ANDROID_HOME="/opt/android" \
    ANDROID_SDK_HOME="$ANDROID_HOME"

ENV PATH $PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/25.0.3:$ANT_HOME/bin:$MAVEN_HOME/bin:$GRADLE_HOME/bin
ENV RUBY_VER ruby-2.4.1
ENV TWINE_VER 1.0.3

WORKDIR /opt

RUN dpkg --add-architecture i386 && \
    mkdir -p /root/.android/ && touch /root/.android/repositories.cfg && \
    apt-get -qq update && \
    apt-get -qq install -y wget curl maven ant gradle libncurses5:i386 libstdc++6:i386 zlib1g:i386 zlib1g-dev

# Install Android SDK
RUN echo "installing sdk tools" && \
    wget --quiet --output-document=sdk-tools.zip \
        "https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip" && \
    mkdir --parents "$ANDROID_HOME" && \
    unzip -q sdk-tools.zip -d "$ANDROID_HOME" && \
    rm --force sdk-tools.zip && \
    echo "installing ndk" && \
    wget --quiet --output-document=android-ndk.zip \
    "http://dl.google.com/android/repository/android-ndk-r${ANDROID_NDK_VERSION}-linux-x86_64.zip" && \
    mkdir --parents "$ANDROID_NDK/android-ndk-r${ANDROID_NDK_VERSION}" && \
    unzip -q android-ndk.zip -d "$ANDROID_NDK" && \
    rm --force android-ndk.zip && \
# Install SDKs
# Please keep these in descending order!
# The `yes` is for accepting all non-standard tool licenses.
    mkdir --parents "$HOME/.android/" && \
    echo '### User Sources for Android SDK Manager' > \
        "$HOME/.android/repositories.cfg" && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager --licenses > /dev/null && \
    echo "installing platforms" && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
        "platforms;android-29" \
        "platforms;android-28" \
        "platforms;android-27" \
        "platforms;android-26" \
        "platforms;android-25" \
        "platforms;android-24" \
        "platforms;android-23" \
        "platforms;android-22" \
        "platforms;android-21" \
        "platforms;android-20" \
        "platforms;android-19" \
        "platforms;android-18" \
        "platforms;android-17" \
        "platforms;android-16" && \
    echo "installing platform tools " && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
        "platform-tools" && \
    echo "installing build tools " && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
        "build-tools;29.0.2" \
        "build-tools;29.0.1" \
        "build-tools;29.0.0" \
        "build-tools;28.0.3" \
        "build-tools;28.0.2" \
        "build-tools;28.0.1" \
        "build-tools;28.0.0" \
        "build-tools;27.0.3" \
        "build-tools;27.0.2" \
        "build-tools;27.0.1" \
        "build-tools;27.0.0" \
        "build-tools;26.0.2" "build-tools;26.0.1" "build-tools;26.0.0" \
        "build-tools;25.0.3" "build-tools;25.0.2" \
        "build-tools;25.0.1" "build-tools;25.0.0" \
        "build-tools;24.0.3" "build-tools;24.0.2" \
        "build-tools;24.0.1" "build-tools;24.0.0" && \
    echo "installing build tools " && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
        "build-tools;23.0.3" "build-tools;23.0.2" "build-tools;23.0.1" \
        "build-tools;22.0.1" \
        "build-tools;21.1.2" \
        "build-tools;20.0.0" \
        "build-tools;19.1.0" \
        "build-tools;18.1.1" \
        "build-tools;17.0.0" && \
    echo "installing extras " && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
        "extras;android;m2repository" \
        "extras;google;m2repository" && \
    echo "installing play services " && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
        "extras;google;google_play_services" \
        "patcher;v4" \
        "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" \
        "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.1" && \
    echo "installing Google APIs" && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
        "add-ons;addon-google_apis-google-24" \
        "add-ons;addon-google_apis-google-23" \
        "add-ons;addon-google_apis-google-22" \
        "add-ons;addon-google_apis-google-21" \
        "add-ons;addon-google_apis-google-19" \
        "add-ons;addon-google_apis-google-18" \
        "add-ons;addon-google_apis-google-17" \
        "add-ons;addon-google_apis-google-16" && \
    echo "installing emulator " && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager "emulator" && \
    echo "installing system image with android 25 and google apis" && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
        "system-images;android-25;google_apis;x86_64"

RUN chmod a+x -R $ANDROID_HOME && \
    chown -R jenkins:jenkins $ANDROID_HOME && \
    mkdir -p /home/jenkins/.android && \
    chown -R jenkins:jenkins /home/jenkins/.android && \
    # Clean up
    apt-get clean && \
    rm -rf \
    /home/jhipster/.cache/ \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

RUN apt-get -qq update && apt-get -qq -y install openssl libssl-dev ruby-full

USER jenkins

# RUBY INSTALLATION START
RUN gpg --keyserver hkp://keys.gnupg.net:80 --recv-keys D39DC0E3 && \
    curl -L https://get.rvm.io | /bin/bash -s stable && \
#    echo 'source /etc/profile.d/rvm.sh' >> /etc/profile && \
    echo 'source /home/jenkins/.rvm/scripts/rvm' >> ~/.bashrc \
    /bin/bash -l -c "rvm requirements;" && \
    /bin/bash -c "source /home/jenkins/.rvm/scripts/rvm"

RUN /bin/bash -l -c "rvm autolibs disable;" && \
    /bin/bash -l -c "rvm install ${RUBY_VER} --debug" && \
    /bin/bash -l -c "rvm use --default ${RUBY_VER} && \
    gem install bundler"

# RUBY INSTALLATION END

#RUN /bin/bash -l -c "source /usr/local/rvm/scripts/rvm && rvm use --default {RUBY_VER} && export > rvm.env"

RUN /bin/bash -l -c "source /home/jenkins/.rvm/scripts/rvm && rvm use --default ${RUBY_VER} && gem install twine -v ${TWINE_VER}"
