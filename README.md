# cuid.el

An implementation of cuid2 in Emacs Lisp. Based on:
  - Reference implementation: https://github.com/paralleldrive/cuid2
  - Python implementation:    https://github.com/gordon-code/cuid2

**NOTE:** The default Emacs SHA512 algorithm is used here, which is NOT the latest SHA-3 version as used in the cuid2 reference implementation. This library follows the logic from the Python implementation which falls back to SHA-2 512 if the SHA-3 version is not available, only in this case always using the SHA-2 version.

## Requirements

- Emacs >=27.1

## Usage

As a library (probably not recommended):

``` emacs-lisp
(require 'cuid)

(cuid/generate)
```

The following interactive functions are defined and can be invoked using `M-x`:

- `cuid/replace-region`: replace region with a newly generated cuid
- `cuid/insert`: insert a newly generated cuid

## License

This project is licensed under the [GPLv2 License](LICENSE) license.
