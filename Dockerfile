FROM registry.labs.nic.cz/turris/foris-ci/python3:latest

ENV HOME=/root
ENV LD_LIBRARY_PATH=:/usr/local/lib

# Install pip requirements
RUN \
  pip install bottle jsonschema

# Install required components
RUN \
  mkdir -p ~/build && \
  cd ~/build && \
  git clone https://gitlab.nic.cz/turris/turrishw.git && \
  cd turrishw && \
  pip install . && \
  cd .. && \
  cd ~/build && \
  git clone https://gitlab.nic.cz/turris/foris-controller/foris-schema.git && \
  cd foris-schema && \
  pip install . && \
  cd .. && \
  git clone https://gitlab.nic.cz/turris/foris-controller/foris-controller.git && \
  cd foris-controller && \
  pip install . && \
  cd .. && \
  git clone https://gitlab.nic.cz/turris/foris-controller/foris-controller-testtools.git && \
  cd foris-controller-testtools && \
  pip install . && \
  cd .. && \
  git clone https://gitlab.nic.cz/turris/foris-controller/foris-client.git && \
  cd foris-client && \
  pip install . && \
  cd .. && \
  git clone https://github.com/shenek/python-websocket-server.git && \
  cd python-websocket-server && \
  git checkout to_upstream2 && \
  pip install . && \
  cd .. && \
  git clone https://gitlab.nic.cz/turris/foris-controller/foris-ws.git && \
  cd foris-ws && \
  pip install . && \
  cd .. && \
  git clone https://gitlab.nic.cz/turris/foris/foris-plugins-distutils.git && \
  cd foris-plugins-distutils && \
  pip install . && \
  cd ..

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
  git clone https://gitlab.nic.cz/turris/foris/foris.git && \
  cd foris && \
  make && \
  pip install . --upgrade && \
  pip install -r foris/requirements.txt

# Install plugins
RUN \
  mkdir -p ~/build && \
  cd ~/build && \
  for name in diagnostics openvpn netmetr ssbackups data_collect ; do \
  git clone https://gitlab.nic.cz/turris/foris-controller/foris-controller-${name}-module.git && \
  cd foris-controller-${name}-module && \
  pip install . && \
  cd .. && \
  git clone https://gitlab.nic.cz/turris/foris/foris-${name}-plugin.git && \
  cd foris-${name}-plugin/ && \
  pip install . ; \
  done

# Make script
RUN \
  echo "#!/bin/sh" >> /usr/local/bin/start && \
  echo "export LD_LIBRARY_PATH=:/usr/local/lib" >> /usr/local/bin/start && \
  echo "ubusd &" >> /usr/local/bin/start && \
  echo "sleep 1" >> /usr/local/bin/start && \
  echo "rpcd &" >> /usr/local/bin/start && \
  echo "sleep 1" >> /usr/local/bin/start && \
  echo "foris-controller --backend mock ubus &" >> /usr/local/bin/start && \
  echo "sleep 1" >> /usr/local/bin/start && \
  echo "foris-ws -a none --port 9080 --host 0.0.0.0 ubus &" >> /usr/local/bin/start && \
  echo "sleep 1" >> /usr/local/bin/start && \
  echo "python -m foris -H 0.0.0.0 -p 80 -S --ws-port 9080 --ws-path /" >> /usr/local/bin/start && \
  chmod 777 /usr/local/bin/start


CMD [ "/usr/local/bin/start" ]
