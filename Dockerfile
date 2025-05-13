FROM scratch AS build

COPY getpsrc-* /usr/bin/getpsrc

ENTRYPOINT [ "/usr/bin/getpsrc" ]
