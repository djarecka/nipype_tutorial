# Generated by Neurodocker v0.3.1-19-g8d02eb4.
#
# Thank you for using Neurodocker. If you discover any issues
# or ways to improve this software, please submit an issue or
# pull request on our GitHub repository:
#     https://github.com/kaczmarj/neurodocker
#
# Timestamp: 2017-11-03 15:20:27

FROM neurodebian:stretch-non-free

ARG DEBIAN_FRONTEND=noninteractive

#----------------------------------------------------------
# Install common dependencies and create default entrypoint
#----------------------------------------------------------
ENV LANG="en_US.UTF-8" \
    LC_ALL="C.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN apt-get update -qq && apt-get install -yq --no-install-recommends  \
    	apt-utils bzip2 ca-certificates curl locales unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && localedef --force --inputfile=en_US --charmap=UTF-8 C.UTF-8 \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> $ND_ENTRYPOINT \
         && echo 'set +x' >> $ND_ENTRYPOINT \
         && echo 'if [ -z "$*" ]; then /usr/bin/env bash; else $*; fi' >> $ND_ENTRYPOINT; \
       fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker
ENTRYPOINT ["/neurodocker/startup.sh"]

#--------------------
# Install AFNI latest
#--------------------
ENV PATH=/opt/afni:$PATH
RUN apt-get update -qq && apt-get install -yq --no-install-recommends ed gsl-bin libglu1-mesa-dev libglib2.0-0 libglw1-mesa \
    libgomp1 libjpeg62 libxm4 netpbm tcsh xfonts-base xvfb python \
    && libs_path=/usr/lib/x86_64-linux-gnu \
    && if [ -f $libs_path/libgsl.so.19 ]; then \
           ln $libs_path/libgsl.so.19 $libs_path/libgsl.so.0; \
       fi \
    && echo "Install libxp (not in all ubuntu/debian repositories)" \
    && apt-get install -yq --no-install-recommends libxp6 \
    || /bin/bash -c " \
       curl --retry 5 -o /tmp/libxp6.deb -sSL http://mirrors.kernel.org/debian/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb \
       && dpkg -i /tmp/libxp6.deb && rm -f /tmp/libxp6.deb" \
    && echo "Install libpng12 (not in all ubuntu/debian repositories" \
    && apt-get install -yq --no-install-recommends libpng12-0 \
    || /bin/bash -c " \
       curl -o /tmp/libpng12.deb -sSL http://mirrors.kernel.org/debian/pool/main/libp/libpng/libpng12-0_1.2.49-1%2Bdeb7u2_amd64.deb \
       && dpkg -i /tmp/libpng12.deb && rm -f /tmp/libpng12.deb" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading AFNI ..." \
    && mkdir -p /opt/afni \
    && curl -sSL --retry 5 https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz \
    | tar zx -C /opt/afni --strip-components=1

#--------------------------
# Install FreeSurfer v6.0.0
#--------------------------
# Install version minimized for recon-all
# See https://github.com/freesurfer/freesurfer/issues/70
RUN apt-get update -qq && apt-get install -yq --no-install-recommends bc libgomp1 libxmu6 libxt6 tcsh perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading minimized FreeSurfer ..." \
    && curl -sSL https://dl.dropbox.com/s/nnzcfttc41qvt31/recon-all-freesurfer6-3.min.tgz | tar xz -C /opt \
    && sed -i '$isource $FREESURFER_HOME/SetUpFreeSurfer.sh' $ND_ENTRYPOINT
ENV FREESURFER_HOME=/opt/freesurfer

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends dcm2niix \
                                                     convert3d \
                                                     ants \
                                                     fsl \
                                                     gcc \
                                                     g++ \
                                                     graphviz \
                                                     tree \
                                                     git-annex-standalone \
                                                     vim \
                                                     emacs-nox \
                                                     nano \
                                                     less \
                                                     ncdu \
                                                     tig \
                                                     git-annex-remote-rclone \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#----------------------
# Install MCR and SPM12
#----------------------
# Install MATLAB Compiler Runtime
RUN apt-get update -qq && apt-get install -yq --no-install-recommends libxext6 libxt6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading MATLAB Compiler Runtime ..." \
    && curl -sSL -o /tmp/mcr.zip https://www.mathworks.com/supportfiles/downloads/R2017a/deployment_files/R2017a/installers/glnxa64/MCR_R2017a_glnxa64_installer.zip \
    && unzip -q /tmp/mcr.zip -d /tmp/mcrtmp \
    && /tmp/mcrtmp/install -destinationFolder /opt/mcr -mode silent -agreeToLicense yes \
    && rm -rf /tmp/*

# Install standalone SPM
RUN echo "Downloading standalone SPM ..." \
    && curl -sSL -o spm.zip http://www.fil.ion.ucl.ac.uk/spm/download/restricted/utopia/dev/spm12_latest_Linux_R2017a.zip \
    && unzip -q spm.zip -d /opt \
    && chmod -R 777 /opt/spm* \
    && rm -rf spm.zip \
    && /opt/spm12/run_spm12.sh /opt/mcr/v92/ quit \
    && sed -i '$iexport SPMMCRCMD=\"/opt/spm12/run_spm12.sh /opt/mcr/v92/ script\"' $ND_ENTRYPOINT
ENV MATLABCMD=/opt/mcr/v92/toolbox/matlab \
    FORCE_SPMMCR=1 \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/opt/mcr/v92/runtime/glnxa64:/opt/mcr/v92/bin/glnxa64:/opt/mcr/v92/sys/os/glnxa64:$LD_LIBRARY_PATH

# Create new user: neuro
RUN useradd --no-user-group --create-home --shell /bin/bash neuro
USER neuro

#------------------
# Install Miniconda
#------------------
ENV CONDA_DIR=/opt/conda \
    PATH=/opt/conda/bin:$PATH
RUN echo "Downloading Miniconda installer ..." \
    && miniconda_installer=/tmp/miniconda.sh \
    && curl -sSL -o $miniconda_installer https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && /bin/bash $miniconda_installer -b -p $CONDA_DIR \
    && rm -f $miniconda_installer \
    && conda config --system --prepend channels conda-forge \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true \
    && conda clean -tipsy && sync

#-------------------------
# Create conda environment
#-------------------------
RUN conda create -y -q --name neuro python=3.6 \
                                    jupyter \
                                    jupyterlab \
                                    traits \
                                    pandas \
                                    matplotlib \
                                    scikit-learn \
                                    seaborn \
                                    swig \
                                    reprozip \
                                    reprounzip \
    && sync && conda clean -tipsy && sync \
    && /bin/bash -c "source activate neuro \
      && pip install -q --no-cache-dir https://github.com/nipy/nipype/tarball/master \
                                       nilearn \
                                       https://github.com/INCF/pybids/tarball/master \
                                       datalad \
                                       dipy \
                                       nipy \
                                       duecredit \
                                       pymvpa2" \
    && sync \
    && sed -i '$isource activate neuro' $ND_ENTRYPOINT

WORKDIR /home/neuro

# User-defined instruction
RUN mkdir ~/.jupyter && echo c.NotebookApp.ip = \"0.0.0.0\" > ~/.jupyter/jupyter_notebook_config.py

#-------------------------
# Update conda environment
#-------------------------
RUN conda install -y -q --name neuro jupyter_contrib_nbextensions \
    && sync && conda clean -tipsy && sync

# User-defined BASH instruction
RUN bash -c "source activate neuro && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main"

#--------------------------------------
# Save container specifications to JSON
#--------------------------------------
RUN echo '{ \
    \n  "pkg_manager": "apt", \
    \n  "check_urls": false, \
    \n  "instructions": [ \
    \n    [ \
    \n      "base", \
    \n      "neurodebian:stretch-non-free" \
    \n    ], \
    \n    [ \
    \n      "afni", \
    \n      { \
    \n        "version": "latest", \
    \n        "install_python2": "true" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "freesurfer", \
    \n      { \
    \n        "version": "6.0.0", \
    \n        "min": true \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "install", \
    \n      [ \
    \n        "dcm2niix", \
    \n        "convert3d", \
    \n        "ants", \
    \n        "fsl", \
    \n        "gcc", \
    \n        "g++", \
    \n        "graphviz", \
    \n        "tree", \
    \n        "git-annex-standalone", \
    \n        "vim", \
    \n        "emacs-nox", \
    \n        "nano", \
    \n        "less", \
    \n        "ncdu", \
    \n        "tig", \
    \n        "git-annex-remote-rclone" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "spm", \
    \n      { \
    \n        "version": "12", \
    \n        "matlab_version": "R2017a" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "user", \
    \n      "neuro" \
    \n    ], \
    \n    [ \
    \n      "miniconda", \
    \n      { \
    \n        "conda_install": "python=3.6 jupyter jupyterlab traits pandas matplotlib scikit-learn seaborn swig reprozip reprounzip", \
    \n        "env_name": "neuro", \
    \n        "activate": "True", \
    \n        "pip_install": "https://github.com/nipy/nipype/tarball/master nilearn https://github.com/INCF/pybids/tarball/master datalad dipy nipy duecredit pymvpa2" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "workdir", \
    \n      "/home/neuro" \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "mkdir ~/.jupyter && echo c.NotebookApp.ip = \\\"0.0.0.0\\\" > ~/.jupyter/jupyter_notebook_config.py" \
    \n    ], \
    \n    [ \
    \n      "miniconda", \
    \n      { \
    \n        "env_name": "neuro", \
    \n        "conda_install": "jupyter_contrib_nbextensions" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "run_bash", \
    \n      "source activate neuro && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main" \
    \n    ] \
    \n  ], \
    \n  "generation_timestamp": "2017-11-03 15:20:27", \
    \n  "neurodocker_version": "0.3.1-19-g8d02eb4" \
    \n}' > /neurodocker/neurodocker_specs.json
