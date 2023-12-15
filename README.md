
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

’’

``` mermaid
graph LR
  style Legend fill:#FFFFFF00,stroke:#000000;
  style Graph fill:#FFFFFF00,stroke:#000000;
  subgraph Legend
    direction LR
    x7420bd9270f8d27d([""Up to date""]):::uptodate --- xbf4603d6c2c2ad6b([""Stem""]):::none
    xbf4603d6c2c2ad6b([""Stem""]):::none --- xf0bce276fe2b9d3e>""Function""]:::none
    xf0bce276fe2b9d3e>""Function""]:::none --- x5bffbffeae195fc9{{""Object""}}:::none
  end
  subgraph Graph
    direction LR
    xa9a3ee3e11185e67>"get_preds"]:::uptodate --> x296cdfc3d1941233>"fit_fold_model"]:::uptodate
    xe853dbcd133510d7>"are_posixct_same_date"]:::uptodate --> x723dadbf985474f2>"read_encounters"]:::uptodate
    xe9ba99dbaa24528e>"convert_to_AEST"]:::uptodate --> x723dadbf985474f2>"read_encounters"]:::uptodate
    xe9ba99dbaa24528e>"convert_to_AEST"]:::uptodate --> x355f5cca566523d6>"read_riskman"]:::uptodate
    x56ec5ac9b4f87731{{"DAYS_TROC"}}:::uptodate --> x1e240d4899a84f4c>"make_model_discrimination_fig"]:::uptodate
    x5af34ad55be2e9ea>"ci.cvAUC"]:::uptodate --> x3ac0f17931558fff>"make_troc"]:::uptodate
    xf27e08346a43f132>"format_count"]:::uptodate --> xa6b015c244aafeed>"f_cat_counts"]:::uptodate
    xf27e08346a43f132>"format_count"]:::uptodate --> x4ccffcd8da785b0b>"get_summary_table"]:::uptodate
    xa6b015c244aafeed>"f_cat_counts"]:::uptodate --> x4ccffcd8da785b0b>"get_summary_table"]:::uptodate
    x71f623d4a19c1436>"format_median_iqr"]:::uptodate --> x4ccffcd8da785b0b>"get_summary_table"]:::uptodate
    x56d4a21aaca65ce7>"glue"]:::uptodate --> xa6b015c244aafeed>"f_cat_counts"]:::uptodate
    x56d4a21aaca65ce7>"glue"]:::uptodate --> x71f623d4a19c1436>"format_median_iqr"]:::uptodate
    x56d4a21aaca65ce7>"glue"]:::uptodate --> x4ccffcd8da785b0b>"get_summary_table"]:::uptodate
    x56d4a21aaca65ce7>"glue"]:::uptodate --> x17e7c779f95d0f59>"make_model_parm_table"]:::uptodate
    x56d4a21aaca65ce7>"glue"]:::uptodate --> xf92c4cd31034b88b>"format_mean_sd"]:::uptodate
    x56d4a21aaca65ce7>"glue"]:::uptodate --> x421dd75e22d8b950>"make_plot_troc_day"]:::uptodate
    x96474a07197d4910{{"HOURS_MAX_STAY"}}:::uptodate --> x4ccffcd8da785b0b>"get_summary_table"]:::uptodate
    x96474a07197d4910{{"HOURS_MAX_STAY"}}:::uptodate --> x22389ea4c076662f>"make_short_data"]:::uptodate
    x96474a07197d4910{{"HOURS_MAX_STAY"}}:::uptodate --> x4c24ff84318b0ad9>"get_supp_power_by_fold_table"]:::uptodate
    xd3fa8fb2bf5a1024{{"OUT_DIR"}}:::uptodate --> x4ccffcd8da785b0b>"get_summary_table"]:::uptodate
    xd3fa8fb2bf5a1024{{"OUT_DIR"}}:::uptodate --> x17e7c779f95d0f59>"make_model_parm_table"]:::uptodate
    xd3fa8fb2bf5a1024{{"OUT_DIR"}}:::uptodate --> x4c24ff84318b0ad9>"get_supp_power_by_fold_table"]:::uptodate
    xd3fa8fb2bf5a1024{{"OUT_DIR"}}:::uptodate --> x1e240d4899a84f4c>"make_model_discrimination_fig"]:::uptodate
    xd3fa8fb2bf5a1024{{"OUT_DIR"}}:::uptodate --> x4998dd746a28d85e>"make_model_calibration_fig"]:::uptodate
    x1a38c3749e90bd5f>"vertically_average"]:::uptodate --> x421dd75e22d8b950>"make_plot_troc_day"]:::uptodate
    x5f4ade556e7fc80f{{"admit_src_cats"}}:::uptodate --> x75fec8118db5f4d8>"create_tdc_data"]:::uptodate
    x7c285ec69664332e{{"FOLD_COLOURS"}}:::uptodate --> xaf5bb1322b7305a2>"add_common_aesthetics"]:::uptodate
    x7c285ec69664332e{{"FOLD_COLOURS"}}:::uptodate --> x421dd75e22d8b950>"make_plot_troc_day"]:::uptodate
    x7c285ec69664332e{{"FOLD_COLOURS"}}:::uptodate --> x8f27808434c75b21>"make_plot_troc_series"]:::uptodate
    x7c285ec69664332e{{"FOLD_COLOURS"}}:::uptodate --> x4998dd746a28d85e>"make_model_calibration_fig"]:::uptodate
    xaf5bb1322b7305a2>"add_common_aesthetics"]:::uptodate --> x4998dd746a28d85e>"make_model_calibration_fig"]:::uptodate
    x14adf92c1336e403>"add_labs"]:::uptodate --> x4998dd746a28d85e>"make_model_calibration_fig"]:::uptodate
    xdd550c49fb62f13b>"get_legend"]:::uptodate --> x4998dd746a28d85e>"make_model_calibration_fig"]:::uptodate
    x372b9bfa29986718>"clean_term"]:::uptodate --> x17e7c779f95d0f59>"make_model_parm_table"]:::uptodate
    x4a3155bdeeea93a6>"fx_med_service"]:::uptodate --> x75fec8118db5f4d8>"create_tdc_data"]:::uptodate
    xaf4efc5e595880e3>"fx_visit_reason"]:::uptodate --> x75fec8118db5f4d8>"create_tdc_data"]:::uptodate
    x85b41015bd495201>".process_input"]:::uptodate --> x5af34ad55be2e9ea>"ci.cvAUC"]:::uptodate
    x421dd75e22d8b950>"make_plot_troc_day"]:::uptodate --> x1e240d4899a84f4c>"make_model_discrimination_fig"]:::uptodate
    x8f27808434c75b21>"make_plot_troc_series"]:::uptodate --> x1e240d4899a84f4c>"make_model_discrimination_fig"]:::uptodate
    x86470561d1ddc979>"plot_grid"]:::uptodate --> x1e240d4899a84f4c>"make_model_discrimination_fig"]:::uptodate
    x86470561d1ddc979>"plot_grid"]:::uptodate --> x4998dd746a28d85e>"make_model_calibration_fig"]:::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x92c0d301eeea4f95(["d4_troc"]):::uptodate
    x3ac0f17931558fff>"make_troc"]:::uptodate --> x92c0d301eeea4f95(["d4_troc"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x9ec4baf90535335d(["d2_troc"]):::uptodate
    x3ac0f17931558fff>"make_troc"]:::uptodate --> x9ec4baf90535335d(["d2_troc"]):::uptodate
    xbca55599905c9c6c(["d1_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x9ec4baf90535335d(["d2_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    xe26da167b52d4175(["d3_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x92c0d301eeea4f95(["d4_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x1e692c728c4f7b14(["d5_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x9496f548bb7f57d8(["d6_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x25d06eeab21bb9c8(["d7_troc"]):::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    x1e240d4899a84f4c>"make_model_discrimination_fig"]:::uptodate --> xbadf59f9a16e23fc(["troc_fig"]):::uptodate
    xef0b60ad56727278{{"TABLES_UNPROCESSED_DIR"}}:::uptodate --> x84d605f17cfb51f9(["riskman_file"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> x99094ad9087961f2(["d_short"]):::uptodate
    x22389ea4c076662f>"make_short_data"]:::uptodate --> x99094ad9087961f2(["d_short"]):::uptodate
    x75fec8118db5f4d8>"create_tdc_data"]:::uptodate --> x410f3723151d7c77(["d_model"]):::uptodate
    xb92a39614cb3cce2(["d_encounters"]):::uptodate --> x410f3723151d7c77(["d_model"]):::uptodate
    x369cbdb02280ce64(["d_riskman"]):::uptodate --> x410f3723151d7c77(["d_model"]):::uptodate
    x96474a07197d4910{{"HOURS_MAX_STAY"}}:::uptodate --> x410f3723151d7c77(["d_model"]):::uptodate
    x264ad50b1a55d55f{{"TIME_HOURS_SPLIT"}}:::uptodate --> x410f3723151d7c77(["d_model"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> x32251c137f2dc541(["final_model"]):::uptodate
    x5bb4981355281955{{"MODEL_FORMULA"}}:::uptodate --> x32251c137f2dc541(["final_model"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x25d06eeab21bb9c8(["d7_troc"]):::uptodate
    x3ac0f17931558fff>"make_troc"]:::uptodate --> x25d06eeab21bb9c8(["d7_troc"]):::uptodate
    x355f5cca566523d6>"read_riskman"]:::uptodate --> x369cbdb02280ce64(["d_riskman"]):::uptodate
    x84d605f17cfb51f9(["riskman_file"]):::uptodate --> x369cbdb02280ce64(["d_riskman"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x1e692c728c4f7b14(["d5_troc"]):::uptodate
    x3ac0f17931558fff>"make_troc"]:::uptodate --> x1e692c728c4f7b14(["d5_troc"]):::uptodate
    x8604922d3fc9ec25(["encounters_file"]):::uptodate --> xb92a39614cb3cce2(["d_encounters"]):::uptodate
    x723dadbf985474f2>"read_encounters"]:::uptodate --> xb92a39614cb3cce2(["d_encounters"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x2239b573fef89b84(["supp_power_by_fold_table"]):::uptodate
    x99094ad9087961f2(["d_short"]):::uptodate --> x2239b573fef89b84(["supp_power_by_fold_table"]):::uptodate
    x4c24ff84318b0ad9>"get_supp_power_by_fold_table"]:::uptodate --> x2239b573fef89b84(["supp_power_by_fold_table"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> xe26da167b52d4175(["d3_troc"]):::uptodate
    x3ac0f17931558fff>"make_troc"]:::uptodate --> xe26da167b52d4175(["d3_troc"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> xbca55599905c9c6c(["d1_troc"]):::uptodate
    x3ac0f17931558fff>"make_troc"]:::uptodate --> xbca55599905c9c6c(["d1_troc"]):::uptodate
    xef0b60ad56727278{{"TABLES_UNPROCESSED_DIR"}}:::uptodate --> x8604922d3fc9ec25(["encounters_file"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> xc9b7966fd0144a42(["model_parm_table"]):::uptodate
    x32251c137f2dc541(["final_model"]):::uptodate --> xc9b7966fd0144a42(["model_parm_table"]):::uptodate
    x17e7c779f95d0f59>"make_model_parm_table"]:::uptodate --> xc9b7966fd0144a42(["model_parm_table"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x9407c770afced25b(["calibration_fig"]):::uptodate
    x4998dd746a28d85e>"make_model_calibration_fig"]:::uptodate --> x9407c770afced25b(["calibration_fig"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> xd2415809dfccb1c9(["model1"]):::uptodate
    x296cdfc3d1941233>"fit_fold_model"]:::uptodate --> xd2415809dfccb1c9(["model1"]):::uptodate
    x5bb4981355281955{{"MODEL_FORMULA"}}:::uptodate --> xd2415809dfccb1c9(["model1"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> x5e90f77e4394a7c0(["model2"]):::uptodate
    x296cdfc3d1941233>"fit_fold_model"]:::uptodate --> x5e90f77e4394a7c0(["model2"]):::uptodate
    x5bb4981355281955{{"MODEL_FORMULA"}}:::uptodate --> x5e90f77e4394a7c0(["model2"]):::uptodate
    xd2415809dfccb1c9(["model1"]):::uptodate --> x8dc0e18ff5b3fdf7(["all_models"]):::uptodate
    x5e90f77e4394a7c0(["model2"]):::uptodate --> x8dc0e18ff5b3fdf7(["all_models"]):::uptodate
    x96bfbf9f3568f6a2(["model3"]):::uptodate --> x8dc0e18ff5b3fdf7(["all_models"]):::uptodate
    xa99bffacae279007(["model4"]):::uptodate --> x8dc0e18ff5b3fdf7(["all_models"]):::uptodate
    x1b6f71dbf5bf036e(["model5"]):::uptodate --> x8dc0e18ff5b3fdf7(["all_models"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> x96bfbf9f3568f6a2(["model3"]):::uptodate
    x296cdfc3d1941233>"fit_fold_model"]:::uptodate --> x96bfbf9f3568f6a2(["model3"]):::uptodate
    x5bb4981355281955{{"MODEL_FORMULA"}}:::uptodate --> x96bfbf9f3568f6a2(["model3"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> xa99bffacae279007(["model4"]):::uptodate
    x296cdfc3d1941233>"fit_fold_model"]:::uptodate --> xa99bffacae279007(["model4"]):::uptodate
    x5bb4981355281955{{"MODEL_FORMULA"}}:::uptodate --> xa99bffacae279007(["model4"]):::uptodate
    x8dc0e18ff5b3fdf7(["all_models"]):::uptodate --> x9496f548bb7f57d8(["d6_troc"]):::uptodate
    x3ac0f17931558fff>"make_troc"]:::uptodate --> x9496f548bb7f57d8(["d6_troc"]):::uptodate
    x410f3723151d7c77(["d_model"]):::uptodate --> x1b6f71dbf5bf036e(["model5"]):::uptodate
    x296cdfc3d1941233>"fit_fold_model"]:::uptodate --> x1b6f71dbf5bf036e(["model5"]):::uptodate
    x5bb4981355281955{{"MODEL_FORMULA"}}:::uptodate --> x1b6f71dbf5bf036e(["model5"]):::uptodate
    x99094ad9087961f2(["d_short"]):::uptodate --> x1aa14e4024bffa08(["summary_table"]):::uptodate
    x4ccffcd8da785b0b>"get_summary_table"]:::uptodate --> x1aa14e4024bffa08(["summary_table"]):::uptodate
  end
  classDef uptodate stroke:#000000,color:#ffffff,fill:#354823;
  classDef none stroke:#000000,color:#000000,fill:#94a4ac;
  linkStyle 0 stroke-width:0px;
  linkStyle 1 stroke-width:0px;
  linkStyle 2 stroke-width:0px;
```
