# tests

## How to install for Mac
```bash
$ brew install openssl && brew install swig
$ brew --prefix openssl
/usr/local/opt/openssl
$ LDFLAGS="-L$(brew --prefix openssl)/lib" \
CFLAGS="-I$(brew --prefix openssl)/include" \
SWIG_FEATURES="-I$(brew --prefix openssl)/include" \
pip install m2crypto
```