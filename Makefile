HAVE_DOCKER := $(shell which docker 2>/dev/null)
HAVE_PODMAN := $(shell which podman 2>/dev/null)


shifter: patch3

cori:
	export NPROC=32
	cctbx/setup_cori.sh

# ......................... basic image ........................................
image:
ifdef HAVE_DOCKER
	docker build -t cctbx-xfel -f docker/Dockerfile --progress=plain .
else
ifdef HAVE_PODMAN
	podman build -t cctbx-xfel -f docker/Dockerfile --format docker .
else
	$(error "No docker or podman in $(PATH). Check if one was installed.")
endif
endif

# ..................... apply patch to python logger ...........................
patch1: image
ifdef HAVE_DOCKER
	docker build -t cctbx-xfel:p1 -f docker/Dockerfile.patch1 --progress=plain .
else
ifdef HAVE_PODMAN
	podman build -t cctbx-xfel:p1 -f docker/Dockerfile.patch1 --format docker .
else
	$(error "No docker or podman in $(PATH). Check if one was installed.")
endif
endif

# .......... add pandas, uc_metrics module, and mpi_experiment branch ..........
patch2: patch1
ifdef HAVE_DOCKER
	docker build -t cctbx-xfel:p2 -f docker/Dockerfile.patch2 --progress=plain .
else
ifdef HAVE_PODMAN
	podman build -t cctbx-xfel:p2 -f docker/Dockerfile.patch2 --format docker .
else
	$(error "No docker or podman in $(PATH). Check if one was installed.")
endif
endif

# ...................... add experiment-specific activate.sh ...................
patch3: patch2
ifdef HAVE_DOCKER
	docker build -t cctbx-xfel:p3 -f docker/Dockerfile.patch3 --progress=plain .
else
ifdef HAVE_PODMAN
	podman build -t cctbx-xfel:p3 -f docker/Dockerfile.patch3 --format docker .
else
	$(error "No docker or podman in $(PATH). Check if one was installed.")
endif
endif

# .................... replace conda mpich with local build ....................
patch4: patch3
ifdef HAVE_DOCKER
	docker build -t cctbx-xfel:p4 -f docker/Dockerfile.patch4 .
else
ifdef HAVE_PODMAN
	podman build -t cctbx-xfel:p4 -f docker/Dockerfile.patch4 --format docker .
else
	$(error "No docker or podman in $(PATH). Check if one was installed.")
endif
endif

# ....................... set branches to mpi_experiment .......................
patch5: patch4
ifdef HAVE_DOCKER
	docker build -t cctbx-xfel:p5 -f docker/Dockerfile.patch5 .
else
ifdef HAVE_PODMAN
	podman build -t cctbx-xfel:p5 -f docker/Dockerfile.patch5 --format docker .
else
	$(error "No docker or podman in $(PATH). Check if one was installed.")
endif
endif

# ............................... add pydrive2 .................................
patch6: patch5
ifdef HAVE_DOCKER
	docker build -t cctbx-xfel:p6 -f docker/Dockerfile.patch6 .
else
ifdef HAVE_PODMAN
	podman build -t cctbx-xfel:p6 -f docker/Dockerfile.patch6 --format docker .
else
	$(error "No docker or podman in $(PATH). Check if one was installed.")
endif
endif

# ............................... add pydrive2 .................................
patch7: patch6
ifdef HAVE_DOCKER
	docker build -t cctbx-xfel:p7 -f docker/Dockerfile.patch7 .
else
ifdef HAVE_PODMAN
	podman build -t cctbx-xfel:p7 -f docker/Dockerfile.patch7 --format docker .
else
	$(error "No docker or podman in $(PATH). Check if one was installed.")
endif
endif
