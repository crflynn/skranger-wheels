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
    python -c "from skranger import ranger"
}

function build_wheel {
    local wheelhouse=$(abspath ${WHEEL_SDIR:-wheelhouse})
    cd skranger

    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python - --version 1.1.4
    source $HOME/.poetry/env
    poetry run echo $HOME
    poetry run python -c 'import sys; print(sys.executable)'
    export PYTHON_EXE=$(poetry run python -c 'import sys; print(sys.executable)' | tr -d '\n')
    export PIP_CMD="poetry run pip"

    poetry run pip install --upgrade pip
    poetry run pip install $BUILD_DEPENDS
    poetry run python buildpre.py
    poetry build
    cp dist/*.whl $wheelhouse
    repair_wheelhouse $wheelhouse
}

if [ -n "$IS_OSX" ]; then
    function repair_wheelhouse {
        local wheelhouse=$1
        source $HOME/.poetry/env
        export PYTHON_EXE=$(poetry run python -c 'import sys; print(sys.executable)' | tr -d '\n')
        export PIP_CMD="$(poetry run which pip | tr -d '\n')"
        export MULTIBUILD_DIR="../multibuild"
        install_delocate
        poetry run delocate-wheel $wheelhouse/*.whl
    }

    function install_wheel {
        # Install test dependencies and built wheel
        #
        # Pass any input flags to pip install steps
        #
        # Depends on:
        #     WHEEL_SDIR  (optional, default "wheelhouse")
        #     TEST_DEPENDS  (optional, default "")
        #     MANYLINUX_URL (optional, default "") (via pip_opts function)
        cd ..
        local wheelhouse=$(abspath ${WHEEL_SDIR:-wheelhouse})
        cd skranger
        check_pip
        if [ -n "$TEST_DEPENDS" ]; then
            while read TEST_DEPENDENCY; do
                $PIP_CMD install $(pip_opts) $@ $TEST_DEPENDENCY
            done <<< "$TEST_DEPENDS"
        fi

        check_python
        check_pip

        $PIP_CMD install packaging
        local supported_wheels=$($PYTHON_EXE $MULTIBUILD_DIR/supported_wheels.py $wheelhouse/*.whl)
        echo $supported_wheels
        if [ -z "$supported_wheels" ]; then
            echo "ERROR: no supported wheels found"
            exit 1
        fi
        # Install compatible wheel
        $PIP_CMD install $(pip_opts) $@ $supported_wheels
    }
fi


function publish_wheel {
    if [ -n "$GITHUB_REF" ] && [ "$GITHUB_REPOSITORY" == "crflynn/skranger-wheels" ]; then
        local wheelhouse=$(abspath ${WHEEL_SDIR:-wheelhouse})
        echo IS_OSX
        echo $IS_OSX
        if [ -n "$IS_OSX" ]; then
            cd skranger
            pip install --upgrade twine
            twine upload $wheelhouse/*.whl
        else
            pip install --upgrade twine
            twine upload $wheelhouse/*.whl
        fi
    fi
}
