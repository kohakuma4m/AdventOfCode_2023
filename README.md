# AdventOfCode_2023
Advent of Code 2023 solutions (dart 3.2.2-1)

# To run specific day solution, use
  - `dart run app -d XX [-p YY] [inputFilename]`
    - `XX` is the day number from 1 to 25
    - `YY` is the optional part number (1 or 2). If missing, both part will be executed
    - `inputFilename` is the optional input text file to use in `lib/dayXX/` solution folder (default is `input.txt`)

# To run linter, format code, or run static code analysis, use
  - `dart fix [--dry-run|--apply]`
  - `dart format .`
  - `dart analyze`

# To run solutions unit tests for all days or a specific day, use
  - `dart test [-r github] [test/dayXX_test.dart]`
  # Note
  - You can also run test using official `Dart` code extension from `dartcode.org` for VSCode

# WARNING
  - This is my own personal sandbox. All solutions are work in progress...
  - I tend to revisit my previous solutions as I go along to cleanup my code, but I make no promises ^_^