**Lab 2 - Digital System Design (DSD) 2023**

***Prerequisite***:
-Simulation Software: Vivado.
-Design:DrawIO

***Contents***
-Verilog File: Design implementations for circuits.
-Constraints File: Constraint File: Pin assignments and constraints for FPGA implementation.
-Docs: Design on DrawIO

***Objectives***
-Design and simulate digital circuits using Verilog.
-Use a constraint file for proper pin assignments in FPGA implementation.
-Using FPGA to make truthtable.
-Identifying the LUTs and IOs from report.
-Understanding the use of DrawIo.

***How to use***
**For Simulation:**
-Open the Verilog design file and constraints file also.
-Compile the design.
-Verify that the circuit is according to requirements.
-Click on Run synthesis and then Implementation.
-Under run synthesis, click on report summary then check the datasheet there will be combinational time then identify the path with maximum delay.

***For FPGA Implementation***:
-Go to the folder where you created the project. There you will find different folders with the starting name same as your project name.
-Go to the your_project_name.runs folder, then impl_1 folder.
-In the search bar, you will write .bit and hit enter. 
-It will display your bit file with the name same as your top module. module_name.bit. 
-Copy that into a USB.
-You will be attaching that USB to the FPGA, then hit the program button.
-When it will have loaded, the Done LED will turn on. 

***Learning Outcomes***
-Designing combinational circuits using SystemVerilog.
-Learn to work with constraint files for FPGA synthesis.
-Using DrawIO.
