ARG KC_VERSION=26.4.5
FROM quay.io/keycloak/keycloak:${KC_VERSION} as builder

USER root

COPY ./providers/ /opt/keycloak/providers/

USER keycloak

ENV KC_DB=postgres
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

RUN /opt/keycloak/bin/kc.sh build
