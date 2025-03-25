## R CMD check results

0 errors | 0 warnings | 1 note

* From initial review: "Ideally, add small executable examples in your Rd-files
  to illustrate the use of the exported function but also enable automatic
  testing."
    * Due to 'MedDRA' licensing restrictions, I cannot include any actual data
      in the package or read it from a remote source. I have added "dontrun"
      examples which I know are not preferred.
    * For clarity, there are example files intended to test some of the oddities
      of loading 'MedDRA' data, but they are not real data. And, I would prefer
      not to point users to those files so that they are not confusing to the
      user.
