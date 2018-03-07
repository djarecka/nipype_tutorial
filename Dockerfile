# Generated by Neurodocker v0.3.2.
#
# Thank you for using Neurodocker. If you discover any issues
# or ways to improve this software, please submit an issue or
# pull request on our GitHub repository:
#     https://github.com/kaczmarj/neurodocker
#
# Timestamp: 2018-03-07 14:26:08

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

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends convert3d \
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

# Add command(s) to entrypoint
RUN sed -i '$isource /etc/fsl/fsl.sh' $ND_ENTRYPOINT

#----------------------
# Install MCR and SPM12
#----------------------
# Install MATLAB Compiler Runtime
RUN apt-get update -qq && apt-get install -yq --no-install-recommends libxext6 libxt6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading MATLAB Compiler Runtime ..." \
    && curl -sSL --retry 5 -o /tmp/mcr.zip https://www.mathworks.com/supportfiles/downloads/R2017a/deployment_files/R2017a/installers/glnxa64/MCR_R2017a_glnxa64_installer.zip \
    && unzip -q /tmp/mcr.zip -d /tmp/mcrtmp \
    && /tmp/mcrtmp/install -destinationFolder /opt/mcr -mode silent -agreeToLicense yes \
    && rm -rf /tmp/*

# Install standalone SPM
RUN echo "Downloading standalone SPM ..." \
    && curl -sSL --retry 5 -o spm.zip http://www.fil.ion.ucl.ac.uk/spm/download/restricted/utopia/dev/spm12_latest_Linux_R2017a.zip \
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
    && curl -sSL --retry 5 -o $miniconda_installer https://repo.continuum.io/miniconda/Miniconda3-4.3.31-Linux-x86_64.sh \
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
                                    pytest \
                                    jupyter \
                                    jupyterlab \
                                    jupyter_contrib_nbextensions \
                                    traits \
                                    pandas \
                                    matplotlib=2.1.2 \
                                    scikit-learn \
                                    seaborn \
                                    nbformat \
    && sync && conda clean -tipsy && sync \
    && /bin/bash -c "source activate neuro \
      && pip install -q --no-cache-dir https://github.com/nipy/nipype/tarball/master \
                                       https://github.com/INCF/pybids/tarball/master \
                                       nilearn \
                                       datalad[full]==0.9.1 \
                                       nipy \
                                       duecredit" \
    && sync \
    && sed -i '$isource activate neuro' $ND_ENTRYPOINT

# User-defined BASH instruction
RUN bash -c "source activate neuro && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main"

# User-defined instruction
RUN mkdir -p ~/.jupyter && echo c.NotebookApp.ip = \"0.0.0.0\" > ~/.jupyter/jupyter_notebook_config.py

USER root

# User-defined instruction
RUN mkdir /data && chmod 777 /data && chmod a+s /data

# User-defined instruction
RUN mkdir /output && chmod 777 /output && chmod a+s /output

USER neuro

# User-defined BASH instruction
RUN bash -c "source activate neuro && cd	/data && datalad install -r ///workshops/nih-2017/ds000114 && cd ds000114 && paths=\"///workshops/nih-2017/ds000114 && cd ds000114 && datalad get -r -J4 sub-*/ses-test/anat  sub-*/ses-test/func/*fingerfootlips* derivatives/fmriprep/sub-*/anat/*space-mni152nlin2009casym_preproc.nii.gz  derivatives/fmriprep/sub-*/anat/*t1w_preproc.nii.gz  derivatives/fmriprep/sub-*/anat/*h5  derivatives/freesurfer/sub-01\" && datalad --report-status=failure get -r -J4 \"$paths\"  || datalad --report-status=failure get -r \"$paths\""

# User-defined BASH instruction
RUN bash -c "curl -L https://files.osf.io/v1/resources/fvuh8/providers/osfstorage/580705089ad5a101f17944a9 -o /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz && tar xf /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz -C /data/ds000114/derivatives/fmriprep/. && rm /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz"

COPY [".", "/home/neuro/nipype_tutorial"]

USER root

# User-defined instruction
RUN chown -R neuro /home/neuro/nipype_tutorial

USER neuro

WORKDIR /home/neuro

CMD ["jupyter-notebook"]

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
    \n      "install", \
    \n      [ \
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
    \n      "add_to_entrypoint", \
    \n      [ \
    \n        "source /etc/fsl/fsl.sh" \
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
    \n        "miniconda_version": "4.3.31", \
    \n        "conda_install": "python=3.6 pytest jupyter jupyterlab jupyter_contrib_nbextensions traits pandas matplotlib=2.1.2 scikit-learn seaborn nbformat", \
    \n        "pip_install": "https://github.com/nipy/nipype/tarball/master https://github.com/INCF/pybids/tarball/master nilearn datalad[full]==0.9.1 nipy duecredit", \
    \n        "env_name": "neuro", \
    \n        "activate": true \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "run_bash", \
    \n      "source activate neuro && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main" \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "mkdir -p ~/.jupyter && echo c.NotebookApp.ip = \\\"0.0.0.0\\\" > ~/.jupyter/jupyter_notebook_config.py" \
    \n    ], \
    \n    [ \
    \n      "user", \
    \n      "root" \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "mkdir /data && chmod 777 /data && chmod a+s /data" \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "mkdir /output && chmod 777 /output && chmod a+s /output" \
    \n    ], \
    \n    [ \
    \n      "user", \
    \n      "neuro" \
    \n    ], \
    \n    [ \
    \n      "run_bash", \
    \n      "source activate neuro && cd\t/data && datalad install -r ///workshops/nih-2017/ds000114 && cd ds000114 && paths=\"///workshops/nih-2017/ds000114 && cd ds000114 && datalad get -r -J4 sub-*/ses-test/anat  sub-*/ses-test/func/*fingerfootlips* derivatives/fmriprep/sub-*/anat/*space-mni152nlin2009casym_preproc.nii.gz  derivatives/fmriprep/sub-*/anat/*t1w_preproc.nii.gz  derivatives/fmriprep/sub-*/anat/*h5  derivatives/freesurfer/sub-01\" && datalad --report-status=failure get -r -J4 \"$paths\"  || datalad --report-status=failure get -r \"$paths\"" \
    \n    ], \
    \n    [ \
    \n      "run_bash", \
    \n      "curl -L https://files.osf.io/v1/resources/fvuh8/providers/osfstorage/580705089ad5a101f17944a9 -o /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz && tar xf /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz -C /data/ds000114/derivatives/fmriprep/. && rm /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz" \
    \n    ], \
    \n    [ \
    \n      "copy", \
    \n      [ \
    \n        ".", \
    \n        "/home/neuro/nipype_tutorial" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "user", \
    \n      "root" \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "chown -R neuro /home/neuro/nipype_tutorial" \
    \n    ], \
    \n    [ \
    \n      "user", \
    \n      "neuro" \
    \n    ], \
    \n    [ \
    \n      "workdir", \
    \n      "/home/neuro" \
    \n    ], \
    \n    [ \
    \n      "cmd", \
    \n      [ \
    \n        "jupyter-notebook" \
    \n      ] \
    \n    ] \
    \n  ], \
    \n  "generation_timestamp": "2018-03-07 14:26:08", \
    \n  "neurodocker_version": "0.3.2" \
    \n}' > /neurodocker/neurodocker_specs.json
