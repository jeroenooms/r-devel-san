## Modfied by Jeroen
## Start with r+rstudio image
FROM rocker/rstudio

## Remain current
RUN apt-get update -qq \
	&& apt-get dist-upgrade -y

## From the Build-Depends of the Debian R package, plus subversion
RUN apt-get update -qq \
	&& apt-get install -t unstable -y --no-install-recommends \
		bash-completion \
		bison \
		debhelper \
		default-jdk \
		g++ \
		gcc-6 \
		gfortran \
		groff-base \
		libblas-dev \
		libbz2-dev \
		libcairo2-dev \
		libcurl4-openssl-dev \
		libjpeg-dev \
		liblapack-dev \
		liblzma-dev \
		libncurses5-dev \
		libpango1.0-dev \
		libpcre3-dev \
		libpng-dev \
		libreadline-dev \
		libtiff5-dev \
		libx11-dev \
		libxt-dev \
		mpack \
		subversion \
		tcl8.5-dev \
		texinfo \
		texlive-base \
		texlive-extra-utils \
		texlive-fonts-extra \
		texlive-fonts-recommended \
		texlive-generic-recommended \
		texlive-latex-base \
		texlive-latex-extra \
		texlive-latex-recommended \
		tk8.5-dev \
		valgrind \
		x11proto-core-dev \
		xauth \
		xdg-utils \
		xfonts-base \
		xvfb \
		zlib1g-dev \
		libssl1.0.0

## Check out R-3.3.x
RUN cd /tmp \
	&& svn co http://svn.r-project.org/R/trunk R-3-3-branch

## Build and install according the standard 'recipe' I emailed/posted years ago
RUN cd /tmp/R-3-3-branch \
	&& R_PAPERSIZE=letter \
	   R_BATCHSAVE="--no-save --no-restore" \
	   R_BROWSER=xdg-open \
	   PAGER=/usr/bin/pager \
	   PERL=/usr/bin/perl \
	   R_UNZIPCMD=/usr/bin/unzip \
	   R_ZIPCMD=/usr/bin/zip \
	   R_PRINTCMD=/usr/bin/lpr \
	   LIBnn=lib \
	   AWK=/usr/bin/awk \
	   CFLAGS="-pipe -std=gnu99 -Wall -pedantic -O3" \
	   CXXFLAGS="-pipe -Wall -pedantic -O3" \
	   CC="gcc -fsanitize=address,undefined" \
	   CXX="g++ -fsanitize=address,undefined" \
	   CXX1X="g++ -fsanitize=address,undefined" \
	   FC="gfortran -fsanitize=address,undefined" \
	   F77="gfortran -fsanitize=address,undefined" \
	   ./configure --enable-R-shlib \
               --without-blas \
               --without-lapack \
               --with-readline \
               --without-recommended-packages \
               --program-suffix=dev \
               --disable-openmp \
	&& make \
	&& make install \
	&& make clean

## Set Renviron to get libs from base R install
RUN echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron

## Set default CRAN repo
RUN echo 'options("repos"="http://cran.rstudio.com")' >> /usr/local/lib/R/etc/Rprofile.site

RUN cd /usr/local/bin \
	&& mv R Rdevel \
	&& mv Rscript Rscriptdevel \
	&& ln -s Rdevel RD \
	&& ln -s Rscriptdevel RDscript

RUN \
  useradd -ms /bin/bash san && \
  echo san:san | chpasswd

# Run rstudio server with asan/ubsan R
ENV RSTUDIO_WHICH_R /usr/local/bin/RD
RUN echo 'rsession-which-r=/usr/local/bin/RD' >> /etc/rstudio/rserver.conf

EXPOSE 8787

CMD rstudio-server restart && /bin/bash
