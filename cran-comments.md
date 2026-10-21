## Submission

This is a new submission.

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Agustín Nieto <agustin.nieto77@gmail.com>'
  New submission

## Test environments

* local Windows 10 x64, R 4.6.1
  (`devtools::check(remote = TRUE, manual = TRUE, cran = TRUE)`):
  0 errors | 0 warnings | 1 note (New submission).
* win-builder, R-devel 2026-10-20 r90728 ucrt (`devtools::check_win_devel()`):
  1 note (New submission). A second "invalid file URI" item in that note
  (a link to a build-ignored file in README.md) has been fixed.
* R-hub v2 (`rhub::rhub_check()`), R-devel on linux, macos-arm64 and
  windows: Status OK.

## External software (Node.js / Chromium)

The data collection functions run a small 'Node.js' script shipped in
`inst/node` that drives a 'Chromium' browser through 'Playwright'.

* Nothing is downloaded or installed when the package is installed or loaded.
  The user has to call `installPlaywrightEngine()` explicitly, which copies the
  script to `tools::R_user_dir("TweetScraperR", "cache")` and runs
  `npm install` there (this downloads 'Playwright' and 'Chromium').
  `SystemRequirements` states that 'Node.js' (>= 18) with 'npm' is needed.
* All examples that need the network, 'Node.js' or an X account are wrapped in
  `\dontrun{}`. The vignette is not evaluated (`eval = FALSE`).
* No test uses the network. The few tests that start a local stub 'Node.js'
  script (no network) are skipped on CRAN and when 'Node.js' is absent.

## Files written by the package

* Sessions of the user's X accounts and the account pool database (SQLite) are
  stored in `tools::R_user_dir("TweetScraperR", "data")`, only when the user
  imports an account. The location can be changed with
  `options(TweetScraperR.data_dir = ...)`, which the tests set to a temporary
  directory.
* Data collection and analysis functions do not write files by default
  (`save = FALSE`); `HTMLImgReport()` writes only to the `output_file` given by
  the user. `installAgentSkill()` copies files only when called by the user, to
  the location the user chooses.
* Examples, vignette and tests write only to `tempdir()`.

## Derived code

The account pool logic is ported from the MIT-licensed 'Python' library
'twscrape' by vladkens. vladkens is listed in `Authors@R` as contributor and
copyright holder, and the original copyright and license notice is included in
`inst/COPYRIGHTS` (referenced from the `Copyright` field).

## Prior work on CRAN

I also maintain 'twscrapeR' (on CRAN since 2026-06-03, version 0.1.3), an R
interface via 'reticulate' to the same 'twscrape' library, which already
provides multi-account support and rate limiting for the same service.
'TweetScraperR' offers equivalent functionality without a 'Python' dependency.
