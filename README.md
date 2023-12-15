
<!-- README.md is generated from README.Rmd. Please edit that file -->

# inpatient-falls-cox-cpm

<!-- badges: start -->
<!-- badges: end -->

This repository contains the analyses code used to develop and evaluate
a prognostic model for inpatient falls using data from the electronic
medical records of patients admitted to Metro South hospitals.

It uses a [`{targets}`](https://books.ropensci.org/targets/) workflow
that includes all model fitting, evaluation and generation of figures
and tables presented in the (forthcoming) publication.

## `{targets}` workflow

``` mermaid
graph LR
  style Legend fill:#FFFFFF00,stroke:#000000;
  style Graph fill:#FFFFFF00,stroke:#000000;
  subgraph Legend
    direction LR
    x7420bd9270f8d27d([""Up to date""]):::uptodate --- xbf4603d6c2c2ad6b([""Stem""]):::none
  end
  subgraph Graph
    direction LR
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x92c0d301eeea4f95(["d4_troc"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x9ec4baf90535335d(["d2_troc"]):::uptodate
    xbca55599905c9c6c(["d1_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x9ec4baf90535335d(["d2_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    xe26da167b52d4175(["d3_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x92c0d301eeea4f95(["d4_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x1e692c728c4f7b14(["d5_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x9496f548bb7f57d8(["d6_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x25d06eeab21bb9c8(["d7_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> x99094ad9087961f2(["d_short"]):::uptodate
    xb92a39614cb3cce2(["d_encounters"]):::uptodate --> x410f3723151d7c77(["d_model"]):::uptodate
    x369cbdb02280ce64(["d_riskman"]):::uptodate --> x410f3723151d7c77(["d_model"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> x32251c137f2dc541(["final_model"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x25d06eeab21bb9c8(["d7_troc"]):::uptodate
    x84d605f17cfb51f9(["riskman_file"]):::uptodate --> x369cbdb02280ce64(["d_riskman"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x1e692c728c4f7b14(["d5_troc"]):::uptodate
    x8604922d3fc9ec25(["encounters_file"]):::uptodate --> xb92a39614cb3cce2(["d_encounters"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x2239b573fef89b84(["supp_power_by_fold_table"]):::uptodate
    x99094ad9087961f2(["d_short"]):::uptodate --> x2239b573fef89b84(["supp_power_by_fold_table"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> xe26da167b52d4175(["d3_troc"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> xbca55599905c9c6c(["d1_troc"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> xc9b7966fd0144a42(["model_parm_table"]):::uptodate
    x32251c137f2dc541(["final_model"]):::uptodate --> xc9b7966fd0144a42(["model_parm_table"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x9407c770afced25b(["calibration_fig"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> xd2415809dfccb1c9(["model1"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> x5e90f77e4394a7c0(["model2"]):::uptodate
    xd2415809dfccb1c9(["model1"]):::uptodate --> x8dc0e18ff5b3fdf7(["all_models"]):::uptodate
    x5e90f77e4394a7c0(["model2"]):::uptodate --> x8dc0e18ff5b3fdf7(["all_models"]):::uptodate
    x96bfbf9f3568f6a2(["model3"]):::uptodate --> x8dc0e18ff5b3fdf7(["all_models"]):::uptodate
    xa99bffacae279007(["model4"]):::uptodate --> x8dc0e18ff5b3fdf7(["all_models"]):::uptodate
    x1b6f71dbf5bf036e(["model5"]):::uptodate --> x8dc0e18ff5b3fdf7(["all_models"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> x96bfbf9f3568f6a2(["model3"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> xa99bffacae279007(["model4"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x9496f548bb7f57d8(["d6_troc"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> x1b6f71dbf5bf036e(["model5"]):::uptodate
    x99094ad9087961f2(["d_short"]):::uptodate --> x1aa14e4024bffa08(["summary_table"]):::uptodate
  end
  classDef uptodate stroke:#000000,color:#ffffff,fill:#354823;
  classDef none stroke:#000000,color:#000000,fill:#94a4ac;
  linkStyle 0 stroke-width:0px;
```
