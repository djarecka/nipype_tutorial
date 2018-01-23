import nipype

def test_nipype():
    ver = nipype.__version__
    print("VER", ver)
    assert "dev" in ver
