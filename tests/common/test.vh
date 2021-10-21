`include "loader.vh"

`define DUMP_VCD \
    initial begin \
        if ($test$plusargs("DUMP")) begin \
            $dumpfile(`DUMP_FILE); \
            $dumpvars(); \
        end \
    end
