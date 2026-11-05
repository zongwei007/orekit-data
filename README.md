This project contains some example data files useful that may be used
as an initial setup for the [Orekit library](https://www.orekit.org/).

In order to use these files, simply download the
[latest archive](https://gitlab.orekit.org/orekit/orekit-data/-/archive/main/orekit-data-main.zip)
and unzip it anywhere you want. Rename the `orekit-data-main` folder to
`orekit-data`, note the path of this folder and add the following lines at
the start of your program:

```java
File orekitData = new File("/path/to/the/folder/orekit-data");
DataProvidersManager manager = DataContext.getDefault().getDataProvidersManager();
manager.addProvider(new DirectoryCrawler(orekitData));
```

This zip file contains:

* JPL DE 440 ephemerides from 1990 to 2149 (more accurate than DE441 for current dates),
* IERS Earth orientation parameters from 1973 to October 2026
  with predicted data up to late 2026 (both IAU-1980 and IAU-2000),
* configuration data for ITRF versions used in regular IERS files,
* leap seconds history from 1972 to end	2026,
* Marshall Solar Activity Future Estimation from 1999 to October 2026,
* CSSI Space Weather Data with observed data from 1957 to October 2026
  with predicted data up to 22 years in the future
* Space environment data (for Jacchia-Bowman 2008 model) from 1997 to end 2026
* the Eigen 6S gravity field
* the FES 2004 ocean tides model.

The provided archive is just a convenience, it is intended as a starting
point for Orekit setup. Users are responsible to update the files in
the unzipped folder to suit their needs as new data is published by IERS,
NASA... This is why we suggest to rename `orekit-data-main`
into `orekit-data` to show that the live data folder is decorrelated
from the initial main folder.

The update.sh script is a bash script that allows to update the data
automatically by uploading individual files from the sites of the
laboratories that generate them, regardless of these files being
updated in Orekit git repository. It is in fact the script the Orekit
team uses to update the repository.

There is *NO* guarantee that this convenience archive will be updated
or even provided in the future.

## License

The files authored for this repository (README, `update.sh`, GitHub workflows)
are distributed under the [Apache License, Version 2.0](LICENSE).

The data files themselves are produced by third parties (IERS, USNO, NASA/JPL,
AGI/CelesTrak, GFZ, LEGOS/CLS...) and remain subject to their own terms and
conditions. See [NOTICE](NOTICE) for the list of data sources.

