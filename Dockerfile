FROM applariat/mapr-edge:6.0.0_4.0.0
#Starting from mapr edge image

ARG artifact_root="."
#Additional build args from AppLariat component configuration will be inserted dynamically

RUN yum install -y unzip && yum -q clean all

#Copy files into place
COPY $artifact_root/build.sh /build.sh
COPY $artifact_root/entrypoint.sh /entrypoint.sh
COPY $artifact_root/code/ /code/
RUN chmod +x /build.sh /entrypoint.sh

#Run the build script
RUN /build.sh 

EXPOSE 22

WORKDIR /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/bin/supervisord","-n","-c","/etc/supervisor/supervisord.conf"]
