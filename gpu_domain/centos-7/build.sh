#!/bin/bash
BASE="centos:7"
CONTAINERNAME='caffe-build'
BASEIMAGE="gbdx-centos7-cuda-7.0-346.46"
DEVIMAGE="gbdx-centos7-cuda-7.0-346.46-dev"
RUNTIMEIMAGE="gbdx-caffe-centos7"
FINALIMAGE="pdlimp/private:caffetest"

# Build Stages
BUILD_BASEIMAGE=true
BUILD_DEVIMAGE=true
BUILD_RUNTIME=true
BUILD_TESTAPP=false

# check dependencies

if ${BUILD_BASEIMAGE}; then
  echo "-------------------------------------------------- Building base image"
  # clean up previous build
  docker rmi $BASEIMAGE
  # Build the base image with minimum layers
  docker run --name=$CONTAINERNAME \
   --volume=`pwd`/build:/build \
   --workdir=/build \
   $BASE /bin/bash /build/build_baseimage.sh
  echo Status is $(docker wait $CONTAINERNAME)
  docker commit $CONTAINERNAME $BASEIMAGE
  docker rm $CONTAINERNAME
fi

if ${BUILD_DEVIMAGE}; then
  echo "-------------------------------------------------- Building dev image"
  # clean up previous build
  docker rmi $DEVIMAGE
  # Build the base image with minimum layers
  docker run --name=$CONTAINERNAME \
   --volume=`pwd`/build:/build \
   --workdir=/build \
   $BASEIMAGE /bin/bash /build/build_devimage.sh
  echo Status is $(docker wait $CONTAINERNAME)
  docker commit $CONTAINERNAME $DEVIMAGE
  docker rm $CONTAINERNAME
fi

if ${BUILD_RUNTIME}; then
  echo "-------------------------------------------------- Building runtime"
  echo "See build/ build/build_runtime.log for details"
  docker run --name=$CONTAINERNAME \
   --volume=`pwd`/build:/build \
   --workdir=/build \
   $DEVIMAGE /bin/bash /build/build_runtime.sh > build/build_runtime.log 2>&1 
  echo Status is $(docker wait $CONTAINERNAME)
  docker commit $CONTAINERNAME $RUNTIMEIMAGE
  docker rm $CONTAINERNAME
fi

if ${BUILD_TESTAPP}; then
  # Run docker build to construct final image with application
  docker rmi $FINALIMAGE
  docker build -t $FINALIMAGE docker
fi
