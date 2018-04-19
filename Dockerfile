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

# Install controller components
RUN \
  mkdir -p ~/build && \
  cd ~/build && \
  git clone https://gitlab.labs.nic.cz/turris/foris-schema.git && \
  cd foris-schema && \
  pip install . && \
  mkdir -p ~/build && \
  cd ~/build && \
  git clone https://gitlab.labs.nic.cz/turris/foris-controller.git && \
  cd foris-controller && \
  pip install . && \
  git clone https://gitlab.labs.nic.cz/turris/foris-controller-testtools.git && \
  cd foris-controller-testtools && \
  pip install . && \
  git clone https://gitlab.labs.nic.cz/turris/foris-client.git && \
  cd foris-client && \
  pip install .

# Make script
RUN \
  echo "#!/bin/sh" >> /usr/local/bin/start && \
  echo "LD_LIBRARY_PATH=:/usr/local/lib" >> /usr/local/bin/start && \
  echo "ubusd &" >> /usr/local/bin/start && \
  echo "rpcd &" >> /usr/local/bin/start && \
  echo "sleep 2" >> /usr/local/bin/start && \
  echo "foris-controller --backend mock ubus &" >> /usr/local/bin/start && \
  echo "sleep 2" >> /usr/local/bin/start && \
  echo "python -m foris -H 0.0.0.0 -p 80 -S" >> /usr/local/bin/start && \
  chmod 777 /usr/local/bin/start


CMD [ "bash", "/usr/local/bin/start" ]
