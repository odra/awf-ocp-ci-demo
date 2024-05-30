FROM ubuntu:jammy

ARG ROS_DISTRO=humble
ARG ROS_VARIANT=desktop
ARG AWF_GIT_URL=https://github.com/autowarefoundation/autoware.git
ARG AWF_GIT_REFS=2024.05
ARG AWF_BUILD_TYPE=Release

ENV LANG=en_US.UTF-8
ENV ROS_DISTRO=${ROS_DISTRO}
ENV ROS_VARIANT=${ROS_VARIANT}

RUN apt update && \
apt install locales && \
locale-gen en_US en_US.UTF-8 && \
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

RUN locale

run apt install -y software-properties-common && \
add-apt-repository universe

RUN apt update && apt install -y git curl && \
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt update && apt install -y \
  python3-flake8-docstrings \
  python3-pip \
  python3-pytest-cov \
  ros-dev-tools \
  python3-flake8-blind-except \
  python3-flake8-builtins \
  python3-flake8-class-newline \
  python3-flake8-comprehensions \
  python3-flake8-deprecated \
  python3-flake8-import-order \
  python3-flake8-quotes \
  python3-pytest-repeat \
  python3-pytest-rerunfailures

RUN apt install -y ros-${ROS_DISTRO}-${ROS_VARIANT}

RUN git clone -b ${AWF_GIT_REFS} ${AWF_GIT_URL} /opt/autoware

WORKDIR /opt/autoware

RUN mkdir -p src
RUN vcs import src < autoware.repos

RUN . /opt/ros/${ROS_DISTRO}/setup.sh
RUN rosdep init
RUN rosdep update

RUN wget -O /tmp/amd64.env https://raw.githubusercontent.com/autowarefoundation/autoware/main/amd64.env && \
. /tmp/amd64.env
RUN apt install -y apt-transport-https
RUN sh -c 'echo "deb [trusted=yes] https://s3.amazonaws.com/autonomoustuff-repo/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/autonomoustuff-public.list'
RUN apt update
RUN apt install -y ros-${ROS_DISTRO}-pacmod3
 
RUN . /opt/ros/${ROS_DISTRO}/setup.sh && rosdep install -y --from-paths src --ignore-src --rosdistro ${ROS_DISTRO}
 
RUN . /opt/ros/${ROS_DISTRO}/setup.sh && colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=${AWF_BUILD_TYPE}
