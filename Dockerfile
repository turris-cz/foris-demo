FROM registry.labs.nic.cz/turris/foris-ci:latest

ENV HOME=/root
ENV LD_LIBRARY_PATH=:/usr/local/lib

# Compile iwinfo
RUN \
  mkdir -p ~/build && \
  cd ~/build && \
  rm -rf rpcd && \
  git clone git://git.openwrt.org/project/iwinfo.git && \
  cd iwinfo && \
  ln -s /usr/lib/x86_64-linux-gnu/liblua5.1.so liblua.so && \
  sed -i 's/..CC....IWINFO_LDFLAGS/\$(LD) \$(IWINFO_LDFLAGS/' Makefile && \
  CFLAGS="-I/usr/include/lua5.1/" LD=ld FPIC="-fPIC" LDFLAGS="-lc" make && \
  cp -r include/* /usr/local/include/ && \
  cp libiwinfo.so /usr/local/lib/

# Compile rpcd
RUN \
  mkdir -p ~/build && \
  cd ~/build && \
  rm -rf rpcd && \
  git clone git://git.openwrt.org/project/rpcd.git && \
  cd rpcd && \
  cmake CMakeLists.txt && \
  make install

# Install python reqs
RUN \
  echo "# Installing other packages" && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install --no-install-recommends \
    ruby-compass slimit gettext

# Installs for compass
RUN \
  gem install breakpoint

# Install foris
RUN \
  mkdir -p ~/build && \
  cd ~/build && \
  git clone https://gitlab.labs.nic.cz/turris/foris.git && \
  cd foris && \
  git checkout dream-of-denucification && \
  make && \
  pip install . && \
  pip install -r foris/requirements.txt && \
  true && \
  true

# Install pip requirements
RUN \
  pip install bottle jsonschema

# Install required components
RUN \
  mkdir -p ~/build && \
  cd ~/build && \
  git clone https://gitlab.labs.nic.cz/turris/foris-schema.git && \
  cd foris-schema && \
  pip install . && \
  cd .. && \
  git clone https://gitlab.labs.nic.cz/turris/foris-controller.git && \
  cd foris-controller && \
  pip install . && \
  cd .. && \
  git clone https://gitlab.labs.nic.cz/turris/foris-controller-testtools.git && \
  cd foris-controller-testtools && \
  pip install . && \
  cd .. && \
  git clone https://gitlab.labs.nic.cz/turris/foris-client.git && \
  cd foris-client && \
  pip install . && \
  cd .. && \
  git clone https://github.com/shenek/python-websocket-server.git && \
  cd python-websocket-server && \
  git checkout to_upstream2 && \
  pip install . && \
  cd .. && \
  git clone https://gitlab.labs.nic.cz/turris/foris-ws.git && \
  cd foris-ws && \
  pip install . && \
  cd ..

# Install plugins
RUN \
  mkdir -p /usr/share/foris/plugins && \
  mkdir -p ~/build && \
  cd ~/build && \
  git clone https://gitlab.labs.nic.cz/turris/foris-controller-diagnostics-module.git && \
  cd foris-controller-diagnostics-module && \
  pip install . && \
  cd .. && \
  git clone https://gitlab.labs.nic.cz/turris/foris-diagnostics-plugin.git && \
  cd foris-diagnostics-plugin/src/static/ && \
  compass compile -r breakpoint -s compressed -e production --no-line-comments --css-dir css --sass-dir sass --images-dir img --javascripts-dir js --http-path "/"  && \
  cd ../.. && \
  ~/build/foris/tools/compilemessages.sh src && \
  cd .. && \
  cp -r foris-diagnostics-plugin/src /usr/share/foris/plugins/diagnostics

# Make script
RUN \
  echo "#!/bin/sh" >> /usr/local/bin/start && \
  echo "rm -rf /root/.cache" >> /usr/local/bin/start && \
  echo "LD_LIBRARY_PATH=:/usr/local/lib" >> /usr/local/bin/start && \
  echo "ubusd &" >> /usr/local/bin/start && \
  echo "rpcd &" >> /usr/local/bin/start && \
  echo "sleep 2" >> /usr/local/bin/start && \
  echo "foris-controller --backend mock ubus &" >> /usr/local/bin/start && \
  echo "foris-ws -a none --port 9080 --host 0.0.0.0 ubus &" >> /usr/local/bin/start && \
  echo "sleep 2" >> /usr/local/bin/start && \
  echo "python -m foris -H 0.0.0.0 -p 80 -S --ws-port 9080 --ws-path /" >> /usr/local/bin/start && \
  chmod 777 /usr/local/bin/start


CMD [ "bash", "/usr/local/bin/start" ]
