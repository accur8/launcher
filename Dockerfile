FROM eclipse-temurin:11

ENV REPO_URL=https://locus.accur8.io/repos/all
ENV REPO_REALM="Accur8 Repo"
ENV REPO_USER=
ENV REPO_PASSWORD=

ENV KIND=jvm_cli
ENV ORGANIZATION=
ENV ARTIFACT=
ENV BRANCH=
ENV MAIN_CLASS=

WORKDIR /opt/launcher

RUN apt-get update
RUN apt-get install -y python3

COPY target/a8-launcher.py ./a8-launcher
COPY target/a8-launcher.sh ./

ADD https://github.com/coursier/launchers/raw/master/coursier ./
RUN chmod +x coursier

CMD [ "./a8-launcher.sh" ]
