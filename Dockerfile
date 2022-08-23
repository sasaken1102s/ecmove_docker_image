# ecmove

FROM ubuntu:22.04

LABEL description="Use this at your own risk"

RUN echo "installing ecmove..."
RUN apt update && apt install -y mysql-client openssh-client rsync zip
RUN cd /root && echo "alias ecmove='bash /root/ecmove/ecmove.sh'" > .bashrc
ADD ./ecmove.sh /root/ecmove/
RUN echo "installed ecmove!!"