ARG IMAGE_TAG="latest"
FROM clojure:openjdk-11-lein AS builder

RUN apt-get -y update && apt-get -y install git

RUN mkdir -p /build

WORKDIR /build

RUN git clone -b v1.39.5 https://github.com/metabase/metabase.git \
    && cd metabase \
    && lein install-for-building-drivers \
    && cd /build

RUN echo "{:user {:plugins [[lein-localrepo \"0.5.4\"]]}}" > ~/.lein/profiles.clj

RUN git clone https://github.com/Strongpool/crux-metabase-driver.git \
    && cd crux-metabase-driver \
    && lein localrepo install lib/dremio-jdbc-driver-4.1.7.jar com.dremio/dremio 4.1.7 \
    && DEBUG=1 LEIN_SNAPSHOTS_IN_RELEASE=true lein uberjar

FROM metabase/metabase:${IMAGE_TAG}

COPY --from=builder /build/crux-metabase-driver/target/uberjar/dremio.metabase-driver.jar /plugins

ARG ATHENA_DRIVER_VERSION="1.2.1"
ARG ATHENA_DRIVER_VERSION="1.3.1"
RUN curl -sLO https://github.com/dacort/metabase-athena-driver/releases/download/v${ATHENA_DRIVER_VERSION}/athena.metabase-driver.jar \
    && mv athena.metabase-driver.jar /plugins