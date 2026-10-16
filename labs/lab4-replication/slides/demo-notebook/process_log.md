# Process log

Python used: C:\Users\joaqu\AppData\Local\Programs\Python\Python312\python.exe (python not on PATH). Shell: Git Bash.

1. Listed the folder and dumped all 34 cells of 02-production-planning-basic.ipynb with nbformat to understand the model.
   The demand cap for U is set in cell 10: `model.y_U = pyo.Var(bounds=(0, 40))`.
2. Executed the original (unmodified) with
   `python -m jupyter nbconvert --to notebook --execute 02-production-planning-basic.ipynb --output 02-executed.ipynb`.
   Succeeded. Only output on stderr was a zmq RuntimeWarning about the Windows Proactor event loop (harmless, no action taken).
   Result: HiGHS status Optimal, profit 2600, y_U=20, y_V=60, x_M=740, x_A=80, x_B=100.
3. Created the what-if copy with a nbformat script: asserted the string `model.y_U = pyo.Var(bounds=(0, 40))` occurs exactly once
   (cell 10), replaced 40 with 60, wrote a temporary file 02-whatif-U60-unexecuted.tmp.ipynb, executed it with nbconvert
   into 02-whatif-U60.ipynb, then deleted the temporary file. Original notebook not modified.
4. Diffed cell sources of original vs copy: exactly one line differs (cell 10), same number of cells (34).
5. Extracted outputs of cells 19, 22, 25, 27, 29, 31 from both executed notebooks. No error outputs in either.
   What-if result: identical to the original (profit 2600, same plan); y_U's upper bound shows 60 in pprint.
6. Because the result was "no change", I ran a separate check script (in my scratchpad, not in this folder, not part of
   the notebooks) that rebuilds the same LP for caps 40 and 60 and imports duals/reduced costs from appsi_highs.
   Both caps: duals raw=10, labor_A=70, labor_B=50; reduced costs x_A=20, x_B=10 (both at upper bounds), y_U=0
   (y_U=20 is strictly inside its bounds, so the cap is not binding).
7. Wrote comparison.txt.

Errors / wrong turns: none that failed. Notes: the zmq RuntimeWarning on every nbconvert run; the temporary unexecuted
copy file was created and then removed. In the what-if notebook the stream output of cell 29 is split into two chunks
("x_A =" and " 80.0 ...") - cosmetic, values identical.
