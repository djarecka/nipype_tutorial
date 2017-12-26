from glob import glob
import sys, os, time
import pytest, pdb

import nbformat
from nbconvert.preprocessors import ExecutePreprocessor
from nbconvert.preprocessors.execute import CellExecutionError

def _notebook_run(path):
    """
    Execute a notebook via nbconvert and collect output.
    :returns (parsed nb object, execution errors)
    """
    kernel_name = 'python%d' % sys.version_info[0]
    this_file_directory = os.path.dirname(__file__)
    errors = []
    
    
    with open(path) as f:
        nb = nbformat.read(f, as_version=4)
        nb.metadata.get('kernelspec', {})['name'] = kernel_name
        ep = ExecutePreprocessor(kernel_name=kernel_name, timeout=1000) #, allow_errors=True

        try:
            ep.preprocess(nb, {'metadata': {'path': this_file_directory}})

        except CellExecutionError as e: 
            if "SKIP" in e.traceback:
                print(str(e.traceback).split("\n")[-2])
            else:
                raise e

    return nb, errors

@pytest.mark.parametrize("notebook", glob("notebooks/basic*.ipynb")+
                         ["notebooks/introduction_python.ipynb", "notebooks/introduction_quickstart.ipynb"] )
def test_notebooks(notebook):
    t0 = time.time()
    nb, errors = _notebook_run(notebook)
    print("time", time.time()-t0)
    assert errors == []
