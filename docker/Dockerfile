
FROM rvm-dev

WORKDIR /opt
COPY PTKcpsdk-5.9.0-RC5.x86_64.rpm .

#RUN apt-get update && apt-get install -y alien && alien -i *.rpm
RUN apt-get install -y alien && cd /opt && alien --scripts -i *.rpm
RUN ln -s /opt/safenet/protecttoolkit5/cpsdk/lib/linux-x86_64/libctsw.so /usr/lib/libcryptoki.so
RUN ln -s /opt/safenet/protecttoolkit5/cpsdk/lib/linux-x86_64/libethsm.so /usr/lib/libethsm.so

ENV PATH="/opt/safenet/protecttoolkit5/cpsdk/bin:/opt/safenet/protecttoolkit5/cpsdk/bin/linux-x86_64:$PATH"

ENTRYPOINT [ "/bin/bash", "--login" ]

