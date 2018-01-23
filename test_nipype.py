import nipype

def test_nipype():
    ver = nipype.__version__
    print("VER", ver)
    assert "dev" in ver

def test_changes():
    nn = nipype.Node
    nn.is_cached
    print(nn.is_cached)
