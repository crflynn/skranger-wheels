#!/usr/bin/env bash
# Define custom utilities
# Test for macOS with [ -n "$IS_OSX" ]

function pre_build {
	# Any stuff that you need to do before you start building the wheels
	# Runs in the root directory of this repository.
	:
}

function run_tests {
    python -c "import skranger; print(skranger.__version__)"
}

function build_wheel {
    local wheelhouse=$(abspath ${WHEEL_SDIR:-wheelhouse})
    cd skranger
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python
    source $HOME/.poetry/env
    poetry run pip install --upgrade pip
    poetry run pip install $BUILD_DEPENDS
    poetry run python buildpre.py
    poetry build
    cp dist/*.whl $wheelhouse
    cd ..
    repair_wheelhouse $wheelhouse
}