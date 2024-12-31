# yaparc change log

## Unreleased

* Remove `message` attribute from `Yaparc::Base`.
* Rename `Yaparc::Fail` to `Yaparc::FailParser`.
* Move `OK`, `Fail`, `Error` outside of `Result` and removed `Result` module.
* Remove `tree` attribute of `Parsable` module.
* Use newer keyword arguments.  This might cause troubles with Ruby version 2
  or lower.
* Limit `Tokenize`'s `prefix` and `postfix` write only.

## 0.3.0 - 2024-12-31

* Added `Yaparc::VERSION` constant.
* Removed `Yaparc` module's `@@identifier_regex` class variable.
* Added `Yaparc::IDENTIFIER_REGEX` constant.
