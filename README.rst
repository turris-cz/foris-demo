FORIS DEMO
==========

Build testing image
-------------------

.. code-block:: shell

    git clone git@gitlab.labs.nic.cz:turris/foris-ci.git
    cd foris-ci
    docker build -t registry.labs.nic.cz/turris/foris-ci .
    cd ..

Build demo image
----------------

.. code-block:: shell

    git clone git@gitlab.labs.nic.cz:turris/foris-demo.git
    cd foris-demo
    docker build -t registry.labs.nic.cz/turris/foris-demo .
    cd ..

Run demo image
--------------

.. code-block:: shell

    docker run  -p 8080:80 -p 9080:9080 -i --rm -t registry.labs.nic.cz/turris/foris-demo

Test
----

.. code-block:: shell

    curl http://localhost:8080/

