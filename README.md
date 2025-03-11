# FEMU for Frame Section Identification in 3D Buildings Using GA-OAPI in SAP2000

**Author:**  
**Mohammad Talebi-Kalaleh**  
<talebika@ualberta.ca>  

**GitHub Repository:**  
[https://github.com/MTalebi/FEMU-for-FrameSection-Identification-in-3DBuilding-using-GA-OAPI-in-SAP2000/tree/main](https://github.com/MTalebi/FEMU-for-FrameSection-Identification-in-3DBuilding-using-GA-OAPI-in-SAP2000/tree/main)

**Publish Date:**  
July 7, 2022

---

## Overview

This documentation describes a MATLAB-based implementation of **Finite Element Model Updating (FEMU)** for **Frame Section Identification** in a 3D building. It relies on the **SAP2000 Open Application Programming Interface (OAPI)** to modify frame properties and run time-history analyses in a closed loop with a **Genetic Algorithm (GA)**. The primary objective is to minimize the error between **measured** and **simulated** accelerations at various sensor locations in the structure.

The workflow is divided into three main parts:

1. **Main Script**  
   - Sets up the MATLAB and SAP2000 OAPI environment.  
   - Retrieves and processes model and measurement files.  
   - Creates optimization parameters and runs the Genetic Algorithm.  

2. **Objective_Fun.m**  
   - Defines the cost function used by the GA.  
   - Computes the discrepancy between measured and simulated accelerations.  

3. **Constraint.m**  
   - Implements non-linear constraints (e.g., preventing abrupt area changes between adjacent frame elements).

---

## Main Script Explanation

**1. Initialization and Input Collection**  
- The workspace is cleared, and the user is prompted to select a `.sdb` file for SAP2000 and a `.txt` file for measured accelerations.  
- The paths to SAP2000 executables and the OAPI DLL are set.

**2. SAP2000 API Setup**  
- The script adds the .NET assembly for SAP2000 OAPI and creates references to the main `SapModel` object.  
- Relevant SAP2000 interface objects (e.g., `FrameObj`, `PointObj`, `Analyze`, `PropFrame`) are extracted for ease of use.

**3. Model Preparation**  
- The model is saved under a new name (prefixed by `Identified_`).  
- The model is unlocked to allow changes to section assignments.  
- The working units (e.g., kgf, cm) are set in SAP2000.

**4. Extracting and Grouping Frame Elements**  
- All frame element names are retrieved via `FrameObj.GetNameList`.  
- For each frame, the assigned autoselect section name is obtained and stored.  
- Frames are grouped according to their autoselect section names.  
- The script detects whether each group corresponds to **Beam**, **Column**, or **Brace** by checking frame orientation.

**5. Optimization Setup**  
- The **number of GA variables (nvars)** is set to the number of distinct autoselect groups.  
- An **initial solution (x0)** is formed from the currently assigned (initial) section indices.  
- **Bounds (lb, ub)** are set to control how many indices above or below the initial assignment are allowed.  
- The script defines integer constraints (`IntCon`) for the GA, since section indices must be integers.  
- The GA is configured using `optimoptions('ga', ...)`, specifying population size, number of generations, constraint tolerances, and plotting options.  

**6. Post-Processing**  
- Upon GA convergence, the final solution is applied to the model.  
- SAP2000 time-history results for each sensor point are retrieved and compared with measured accelerations.  
- Plots are generated to visualize the measured vs. simulated accelerations in both the X and Y directions.

---

## Objective_Fun.m

This function:
- Receives the GA solution vector `x`, which indicates which section index to assign to each autoselect list.
- Updates the frame sections in the SAP2000 model accordingly.
- Runs the SAP2000 time-history analysis.
- Retrieves the simulation’s accelerations and compares them (via norm-based differences) to measured data.
- Returns an averaged cost representing the mismatch between measured and simulated accelerations.

---

## Constraint.m

This function imposes non-linear constraints for the GA:
- Prevents abrupt changes in **beam** cross-sectional area from one level (or group) to the next if `ConsiderConstraintForBeams` is enabled.
- Prevents abrupt changes in **column** cross-sectional area from one story to the next if `ConsiderConstraintForCols` is enabled.
- No equality constraints are specified.
- The returned constraint array is evaluated by the GA, keeping the solution in a feasible design region.

---

## How to Cite

If you use or adapt this methodology or code in your research, please cite it as follows:

> **Talebi-Kalaleh, Mohammad.** (2022). *FEMU for Frame Section Identification in 3D Building using GA and OAPI in SAP2000.* Published July 7, 2022. GitHub repository: [https://github.com/MTalebi/FEMU-for-FrameSection-Identification-in-3DBuilding-using-GA-OAPI-in-SAP2000/tree/main](https://github.com/MTalebi/FEMU-for-FrameSection-Identification-in-3DBuilding-using-GA-OAPI-in-SAP2000/tree/main)

---

## Final Notes

1. **Prerequisites**  
   - SAP2000 v23 (or a compatible version) with OAPI enabled.  
   - MATLAB with the Optimization Toolbox (for GA functionality).  
   - A `.sdb` model file and `.txt` files of measured accelerations.

2. **Usage**  
   - Run the main MATLAB script.  
   - When prompted, select the `.sdb` file and the `.txt` file location.  
   - The script optimizes and saves a new SAP2000 model.  
   - Plots of measured vs. estimated accelerations are displayed.

3. **Possible Extensions**  
   - Adapt the objective function to consider other responses (e.g., displacements, strains).  
   - Introduce additional constraints or multi-objective optimization.  
   - Increase the GA population/generations for more thorough searches.

For any questions or collaboration proposals, contact:
**talebika@ualberta.ca**
