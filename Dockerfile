FROM applariat/mapr-edge:5.2.2_3.0.1
#Starting from mapr edge image

ARG artifact_root="."
#Additional build args from AppLariat component configuration will be inserted dynamically

#Copy files into place
COPY $artifact_root/build.sh /build.sh
COPY $artifact_root/entrypoint.sh /entrypoint.sh
COPY $artifact_root/code/ /code/
RUN chmod +x /build.sh /entrypoint.sh

#Run the build script
RUN /build.sh 

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
