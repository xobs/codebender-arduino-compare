#!/bin/sh

ip_address=$(docker inspect --format '{{ .NetworkSettings.Networks.codebuildernet.IPAddress }}' cb-compiler)
compiler_url=http://${ip_address}/app.php/mycoolkey/v2
