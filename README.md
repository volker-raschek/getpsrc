# getpsrc

[![Docker Pulls](https://img.shields.io/docker/pulls/volkerraschek/getpsrc)](https://hub.docker.com/r/volkerraschek/getpsrc)

`getpsrc` is a small programme to determine the src routing ip for an external ip.

`getpsrc` serves as an alternative to `ip route get <ip> | awk ...` because `ip
route get` can return different output depending on the environment and therefore the construct is unsafe.

`getpsrc` is also as container image available: `docker.io/volkerraschek/getpsrc`.
