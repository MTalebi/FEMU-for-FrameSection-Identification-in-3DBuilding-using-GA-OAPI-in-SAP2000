# FEMU for Frame Section Identification in 3D Buildings Using GA OAPI in SAP2000

This repository contains a MATLAB workflow that updates a SAP2000 steel frame model by matching simulated accelerations to measured accelerations.

## What this project does

The script:
- opens an existing SAP2000 model
- groups frame members by their assigned auto-select section list
- classifies each group as beam, column, or brace from member direction
- runs a genetic algorithm to choose section indices for each group
- updates sections through SAP2000 OAPI and runs time history analysis
- compares simulated and measured accelerations at sensor points
- applies optional area-change constraints between adjacent beam and column groups
- plots measured versus simulated acceleration in X and Y for each sensor point

## Repository contents

- `Main_SteelBuildingIDTH_Model_Updating.m`
  Main script. Handles SAP2000 connection, model and data loading, group setup, optimization settings, and final plots.

- `Objective_Fun.m`
  Objective function for the genetic algorithm. Assigns sections, runs analysis, and computes mismatch cost.

- `Constraint.m`
  Nonlinear constraint function. Limits section area jumps between neighboring beam and column groups.

- `3D Building Example in SAP2000/`
  Example SAP2000 model files and measured acceleration text files.

## Requirements

- Windows with SAP2000 installed (script path currently points to SAP2000 v23)
- MATLAB with Optimization Toolbox (`ga`)
- SAP2000 OAPI DLL available on your machine
- A SAP2000 `.sdb` model prepared for this workflow
- Measured acceleration files named like `Point8.txt`, `Point9.txt`, etc.

## Model and data assumptions

The current code expects:
- a SAP2000 group named `Sensor_Points` that contains output joints
- a direct history load case named `RHA_Earthquacke`
- a load case named `MODAL`
- frame elements assigned to auto-select steel lists
- each measured file to include three columns: time, X acceleration, Y acceleration
- measured files to be in the folder you pick in the second file dialog

## How to run

1. Open SAP2000 and open the target model.
2. In MATLAB, open and run `Main_SteelBuildingIDTH_Model_Updating.m`.
3. Select a `.sdb` file when prompted.
4. Select any measured `.txt` file from the measured data folder when prompted.
5. Wait for the optimization to finish.
6. Review the output model and comparison plots.

The script saves a new model with prefix `Identified_` in the same folder as the input model.

## Main settings in the script

You can adjust these values near the top of `Main_SteelBuildingIDTH_Model_Updating.m`:
- `UseAllSectionsInAutoListMembers`
- `InitialSectionsChangeRangeLB`
- `InitialSectionsChangeRangeUB`
- `ConsiderConstraintForBeams`
- `ConsiderConstraintForCols`
- `Output_Sensor_Joints`
- `TH_LoadCase_Name`
- `ProgramPath`
- `APIDLLPath`

Default GA options in the script:
- population size: 10
- max generations: 10
- integer decision variables for section indices

## Output

- optimized section index set for each auto-select group
- objective value shown as `ResponseEstimationError`
- runtime shown as `RunTime`
- measured vs simulated acceleration plots for each sensor point

## Notes

- This workflow uses live SAP2000 OAPI calls. It does not run without SAP2000.
- The script uses `interp1` to map measured data onto analysis time steps before error calculation.
- The cost is based on norm differences of X and Y acceleration histories, averaged by sensor count and sample count.

## Contact

Mohammad Talebi Kalaleh
talebika@ualberta.ca
