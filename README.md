
# Apricot Analysis Integration Demo

![Apricot logo](img/apricot-logo.svg)

A reproducible demo of the two SysML v2 runtime engines integrated in
[Apricot](https://apricot.tools): (1) **[OpenSysML](https://github.com/Open-MBEE/OpenSysML)**
and (2) the **[SysML Toolkit](https://github.com/Open-MBEE/sysml-toolkit)**.

One model, a delivery quadcopter (as example), is checked, evaluated, verified, queried, reported
and drawn by both engines from Apricot's **Analysis** panel. Where the engines
disagree, the demo shows why.

## Contents

| File | What is in |
| --- | --- |
| [drone.sysml](drone.sysml) | The example model: parts, derived values, requirements, a design space for the solvers, an analysis and some behavior. |
| [drone-report.sysml](drone-report.sysml) | A design report over the model, rendered by OpenSysML. |
| [analysis-feature.md](analysis-feature.md) | The step-by-step walkthrough, one section per tab of the Analysis panel. |
| [Apricot-Runtime-Integration.pdf](Apricot-Runtime-Integration.pdf) | The presentation given at the OpenMBEE Dev. Meeting |
| [output/](output/) | The expected output of every step, to compare with your own run. |

## Replay the demo

1. Open [Apricot](https://apricot.tools) and create a model.
2. Paste the content of [drone.sysml](drone.sysml) into the editor.
3. Open the **Analysis** panel and follow [analysis-feature.md](analysis-feature.md).

Each step names the tab, the engine and the input, and links to the expected output
in [output/](output/). The first line of every output file is the equivalent
command-line call, so the demo can also be replayed with the engines' CLIs
(`sysml` for OpenSysML, `sysmlv2` for the SysML Toolkit).

## Versions

The demo and every file in [output/](output/) were produced with the versions
Apricot runs:

| Component | Version |
| --- | --- |
| OpenSysML | [v0.8.1](https://github.com/Open-MBEE/OpenSysML/releases/tag/v0.8.1) |
| SysML Toolkit | [v0.6.0](https://github.com/Open-MBEE/sysml-toolkit/releases/tag/v0.6.0) |
| SysML v2 standard library | [SysML-v2-Release @ de1070a](https://github.com/Systems-Modeling/SysML-v2-Release/tree/de1070ae8e79c21532b8004fc663d47b35d0e9fa/sysml.library) |
| Z3 | 4.8.12 |

## References

- **Apricot**, the SysML v2 web editor by Metadev: <https://apricot.tools>
- **OpenSysML**, SysML v2 / KerML implementation in Go (NASA/JPL):
  <https://github.com/Open-MBEE/OpenSysML> · <https://opensysml.org/>
- **SysML Toolkit**, SysML v2 toolkit in Rust (Planetary Utilities): <https://github.com/Open-MBEE/sysml-toolkit>
- **SysML v2 standard library** (OMG): <https://github.com/Systems-Modeling/SysML-v2-Release>

## License

[Apache 2.0](LICENSE).
