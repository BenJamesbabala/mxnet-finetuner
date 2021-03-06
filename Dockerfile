FROM nvidia/cuda:8.0-cudnn6-devel

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
    build-essential \
    cmake \
    font-manager \
    fonts-ipaexfont \
    git \
    language-pack-ja \
    libatlas-base-dev \
    libcurl4-openssl-dev \
    libgtest-dev \
    libopencv-dev \
    python-opencv \
    python-dev \
    python-numpy \
    python-tk \
    python3-dev \
    unzip \
    wget \
  && rm -rf /var/lib/apt/lists/*

RUN cd /usr/src/gtest && cmake CMakeLists.txt && make && cp *.a /usr/lib && \
    cd /tmp && wget https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py && python2 get-pip.py

RUN git clone --recursive https://github.com/dmlc/mxnet && cd mxnet \
  && cp make/config.mk . \
  && echo "USE_CUDA=1" >> config.mk \
  && echo "USE_CUDA_PATH=/usr/local/cuda" >> config.mk \
  && echo "USE_CUDNN=1" >> config.mk \
  && echo "USE_BLAS=atlas" >> config.mk \
  && echo "USE_DIST_KVSTORE=1" >> config.mk \
  && make -j$(nproc) \
  && rm -r build

RUN pip2 install nose pylint numpy nose-timer requests
RUN pip3 install nose pylint numpy nose-timer requests

RUN wget --quiet https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
  && chmod +x jq-linux64 \
  && mv jq-linux64 /usr/bin/jq

RUN pip3 install \
  attrdict \
  awscli \
  jupyter \
  matplotlib \
  opencv-python \
  pandas \
  pandas_ml \
  pyyaml \
  seaborn \
  sklearn-pandas \
  slackclient

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV MXNET_CUDNN_AUTOTUNE_DEFAULT=1

WORKDIR /mxnet/example/image-classification

COPY common /mxnet/example/image-classification/common/
COPY util /mxnet/example/image-classification/util/
COPY docker-entrypoint.sh .

ENTRYPOINT ["./docker-entrypoint.sh"]
