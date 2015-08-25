# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jrevote8/minimal

MAINTAINER Jerico Revote <jerico.revote@monash.edu>

USER root

# Compilers
RUN apt-get update && apt-get install -y gcc g++ gfortran && apt-get clean

# Utilities
RUN apt-get install -y vim screen wget curl aptitude mercurial git pandoc pandoc-data texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended && apt-get clean

# Development Libraries
RUN apt-get install -y libpng12-dev libxml2-dev libhdf5-dev libgeos-dev libgeos++-dev libproj-dev libxslt1-dev libglu1-mesa-dev libgl1-mesa-dev libosmesa6-dev libosmesa6 libpetsc3.4.2-dev libcurl3-dev freeglut3-dev libgl2ps-dev python-dev python-pip libudunits2-dev libgrib-api-dev libfreetype6-dev libncurses-dev libgrib-api-tools && apt-get clean

# GDAL
RUN cd /tmp && \
    wget ftp://ftp.remotesensing.org/gdal/1.11.2/gdal-1.11.2.tar.gz && \
    tar xvzf gdal-1.11.2.tar.gz && \
    cd gdal-1.11.2 && \
    ./configure --with-python && \
    make && \
    make install

# PIL Dependency
RUN ln -s /usr/include/freetype2 /usr/local/include/freetype

USER cerberus

# Python packages
RUN conda install --yes numpy pandas scikit-learn scikit-image matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle dill numba bokeh rasterio shapely fiona PIL && conda clean -yt

# More Python packages
RUN pip install --user obspy geopandas && \
    pip install --user basemap --allow-external basemap --allow-unverified basemap && \
    pip install --user pyke --allow-external pyke --allow-unverified pyke

# Underworld
USER cerberus
RUN hg clone -b newInterface https://bitbucket.org/underworldproject/underworld2 /home/cerberus/underworld2 && \
    cd /home/cerberus/underworld2/libUnderworld && \
    hg up 305 && \
    ./configure.py && \
    ./scons.py && \
    sed -i -e 's/LavaVu/LavaVuOS/g' /home/cerberus/underworld2/glucifer/pylab/_pylab.py

ENV PYTHONPATH /home/cerberus/underworld2:$PYTHONPATH

EXPOSE 8888

USER cerberus
ENV HOME /home/cerberus
ENV SHELL /bin/bash
ENV USER cerberus
ENV PATH $CONDA_DIR/bin:$CONDA_DIR/envs/python2/bin:$PATH
WORKDIR $HOME/underworld2/InputFiles

# Convert notebooks to the current format
RUN find . -name '*.ipynb' -exec ipython nbconvert --to notebook {} --output {} \;
RUN find . -name '*.ipynb' -exec ipython trust {} \;

CMD ipython notebook
