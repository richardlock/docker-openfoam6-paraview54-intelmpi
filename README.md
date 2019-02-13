# openfoam6-intelmpi Dockerfile

Docker image to run [OpenFOAM 6](https://openfoam.org) and [ParaView 5.4](https://www.paraview.org) built from source with [Intel MPI 5.1](https://software.intel.com/en-us/mpi-library) for use with [Batch Shipyard](https://github.com/Azure/batch-shipyard) on Azure Batch.

## Usage

### Install

Pull `richardlock/openfoam6-paraview54-intelmpi` image from Docker Hub:

    docker pull richardlock/oopenfoam6-paraview54-intelmpi

Or build image from source:

    git clone https://github.com/richardlock/docker-openfoam6-paraview54-intelmpi.git
    cd docker-openfoam6-paraview54-intelmpi
    docker build -t richardlock/openfoam6-paraview54-intelmpi .

Flatten image to reduce size:

    docker run -it richardlock/openfoam6-paraview54-intelmpi /bin/bash
    exit
    docker ps -a | grep richardlock/openfoam6-paraview54-intelmpi
    docker export <CONTAINER ID> | docker import - richardlock/openfoam6-paraview54-intelmpi:latest
    docker login -u <username>
    docker push richardlock/openfoam6-paraview54-intelmpi:latest

### Run

Run the image with an interactive bash shell:

    docker run -it richardlock/openfoam6-paraview54-intelmpi /bin/bash

Please see the [OpenFOAM User Guide](https://cfd.direct/openfoam/user-guide/) for information on using OpenFOAM.

### Licence

You must agree to the [OpenFOAM licence](http://openfoam.org/licence/) prior to use.