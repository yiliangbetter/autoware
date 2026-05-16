# hadolint global ignore=DL3006
ARG BASE_IMAGE
FROM $BASE_IMAGE

ENV SHELL /bin/bash

ARG USERNAME=aw
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN if ! getent group $USER_GID >/dev/null; then groupadd --gid $USER_GID $USERNAME; fi \
  && if ! id -u $USERNAME >/dev/null 2>&1; then useradd --uid $USER_UID --gid $USER_GID -m $USERNAME; fi \
  && apt-get update \
  && apt-get install -y sudo \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME
