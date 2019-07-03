FROM alpine:3.6

LABEL maintainer="cavemandaveman <cavemandaveman@protonmail.com>"

ENV SONATYPE_DIR="/opt/sonatype"
ENV NEXUS_VERSION="3.15.2-01" \
    NEXUS_HOME="${SONATYPE_DIR}/nexus" \
    NEXUS_DATA="/nexus-data" \
    SONATYPE_WORK=${SONATYPE_DIR}/sonatype-work \
    JAVA_MIN_MEM="1200M" \
    JAVA_MAX_MEM="1200M" \
    JKS_PASSWORD="changeit"

RUN set -x \
    && apk --no-cache add \
        openjdk8-jre-base \
        libressl \
        su-exec \
        curl \
    && mkdir -p "${SONATYPE_DIR}" \
    && wget -qO - "https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz" \
    | tar -zxC "${SONATYPE_DIR}" \
    && mv "${SONATYPE_DIR}/nexus-${NEXUS_VERSION}" "${NEXUS_HOME}" \
    && adduser -S -h ${NEXUS_DATA} nexus

WORKDIR "${NEXUS_HOME}"

VOLUME "${NEXUS_DATA}"

ADD https://raw.githubusercontent.com/cavemandaveman/nexus/master/docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

ENV NEXUS_PLUGINS ${NEXUS_HOME}/system

# https://github.com/flytreeleft/nexus3-keycloak-plugin
ENV KEYCLOAK_PLUGIN_VERSION 0.3.2-SNAPSHOT
ENV KEYCLOAK_PLUGIN org.github.flytreeleft/nexus3-keycloak-plugin/${KEYCLOAK_PLUGIN_VERSION}

ADD https://github.com/flytreeleft/nexus3-keycloak-plugin/releases/download/${KEYCLOAK_PLUGIN_VERSION}/nexus3-keycloak-plugin-${KEYCLOAK_PLUGIN_VERSION}.jar \
    ${NEXUS_PLUGINS}/org/github/flytreeleft/nexus3-keycloak-plugin/${KEYCLOAK_PLUGIN_VERSION}/nexus3-keycloak-plugin-${KEYCLOAK_PLUGIN_VERSION}.jar

RUN chmod 644 ${NEXUS_PLUGINS}/org/github/flytreeleft/nexus3-keycloak-plugin/${KEYCLOAK_PLUGIN_VERSION}/nexus3-keycloak-plugin-${KEYCLOAK_PLUGIN_VERSION}.jar
RUN echo "mvn\\:${KEYCLOAK_PLUGIN} = 200" >> ${NEXUS_HOME}/etc/karaf/startup.properties

EXPOSE 5000 8081 8443
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bin/nexus", "run"]