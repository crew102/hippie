## Notes

This is a resubmission. See below for responses to the last round(s) of comments.

> \dontrun{} should only be used if the example really cannot be executed (e.g. because of missing additional software, missing API keys, ...) by the user. That's why wrapping examples in \dontrun{} adds the comment ("# Not run:") as a warning for the user. Does not seem necessary. Please replace \dontrun with \donttest. Please unwrap the examples if they are executable in < 5 sec, or replace \dontrun{} with \donttest{}.

All examples require RStudio being installed, so it is probably not safe to assume that they're executable by all users.

> You could also create additional test so that we can check the functionality of your code or try to create examples which are not in \dontrun / \donttest.

If RStudio is installed, you can test the functionality of the package using tests/testthat/test-interactive.R.

> Please always write package names, software names and API (application programming interface) names in single quotes in title and description. e.g: --> 'Hippie'. Please note that package names are case sensitive.

I've made some updates to the DESCRIPTION regarding this requirement, but is it OK if I don't single quote Hippie when I'm referring to the actual completion method, as opposed to the package? Uwe mentioned that this would be acceptable. 

> Please add \value to .Rd files regarding exported methods and explain the functions results in the documentation. Please write about thestructure of the output (class) and also what the output means. (If a function does not return a value, please document that too, e.g. \value{No return value, called for side effects} or similar).

Done

> Please add small executable examples in your Rd-files to illustrate the use of the exported function but also enable automatic testing.

Done

> Please ensure that your functions do not write by default or in your examples/vignettes/tests in the user's home filespace (including the package directory and getwd()). This is not allowed by CRAN policies. Please omit any default path in writing functions. In your examples/vignettes/tests you can write to tempdir().

I don't think any of my functions (including those in my tests directory) are writing to the user's home filespace. Can you clarify which function is problematic? Also I have one test helper function that has as default path (`fixture_file = "r-source.R"`), but that path is a fixture file that's read in, not a location that's being written to. Is that OK?

## Test environments

* macOS 11.6.8 (64-bit) on Github, R 4.2.1
* Microsoft Windows Server 2022 10.0.20348 (64-bit) on Github, R 4.2.1
* Ubuntu 20.04.4 (64-bit) on Github, R 4.2.1
* Ubuntu 20.04.4 (64-bit) on Github, R-devel (2022-08-23 r82743)
* Ubuntu 20.04.4 (64-bit) on Github, R 4.1.3

## R CMD check results

There were no ERRORs, WARNINGs, or NOTEs.
