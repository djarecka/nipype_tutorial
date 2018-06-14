#!/bin/bash

docker run --rm kaczmarj/neurodocker:master generate docker\
           --base neurodebian:stretch-non-free \
           --pkg-manager apt \
           --install fsl-5.0-core fsl-mni152-templates \
                     vim emacs-nox nano less ncdu git-annex-standalone \
           --add-to-entrypoint "source /etc/fsl/5.0/fsl.sh" \
           --user=neuro \
           --miniconda miniconda_version="4.3.31" \
             conda_install="python=3.6 pytest jupyter jupyterlab jupyter_contrib_nbextensions
                            traits pandas matplotlib  scikit-learn scikit-image nbformat nb_conda" \
             pip_install="https://github.com/nipy/nipype/tarball/master
                          nilearn datalad[full]" \
             create_env="neuro" \
             activate=True \
           --run-bash "source activate neuro && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main" \
           --user=root \
           --run 'mkdir /data && chmod 777 /data && chmod a+s /data' \
           --user=neuro \
           --run-bash 'source activate neuro && cd /data && datalad install -r ///workshops/nih-2017/ds000114 && cd ds000114 && datalad update -r && datalad get -r sub-01/ses-test/anat  sub-02/ses-test/anat' \
	   --copy . "/home/neuro/nipype_tutorial" \
           --user=root \
           --run 'chown -R neuro /home/neuro/nipype_tutorial' \
           --run 'rm -rf /opt/conda/pkgs/*' \
           --user=neuro \
           --run 'mkdir -p ~/.jupyter && echo c.NotebookApp.ip = \"0.0.0.0\" > ~/.jupyter/jupyter_notebook_config.py' \
           --workdir /home/neuro/nipype_tutorial \
           --cmd "jupyter-notebook" > Dockerfile
