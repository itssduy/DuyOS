FROM quay.io/fedora/fedora-bootc:44

RUN dnf install -y \
  vim \
  tmux \
  && dnf clean all

