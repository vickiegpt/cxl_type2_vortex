#!/usr/bin/env quartus_sh
# Compile script for cxltyp2_ed - run full synthesis to assembly flow
project_open cxltyp2_ed
execute_module -tool syn
execute_module -tool fit
execute_module -tool asm
execute_module -tool sta
project_close
exit
