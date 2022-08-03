##JENKINS
#FROM jenkins/jenkins:lts-jdk17
#USER root
#RUN apt-get update \
# && DEBIAN_FRONTEND=noninteractive \
  #  apt-get install --no-install-recommends --assume-yes \
#      docker.io
#USER jenkins
#-----------------------

#FROM adoptopenjdk/openjdk11:alpine-slim as build
FROM adoptopenjdk/openjdk17:ubuntu as build
WORKDIR /workspace/app

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src

RUN ./mvnw install -DskipTests
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

# Run vulnerability scan on build image
FROM build AS vulnscan
COPY --from=aquasec/trivy:latest /usr/local/bin/trivy /usr/local/bin/trivy
RUN trivy rootfs --no-progress /

FROM adoptopenjdk/openjdk11:alpine-slim
VOLUME /tmp
ARG DEPENDENCY=/workspace/app/target/dependency
COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app
ENTRYPOINT ["java","-Dserver.port=${PORT}","-cp","app:app/lib/*","com.example.demo.DemoApplication"]
