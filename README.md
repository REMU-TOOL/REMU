# emulator

TODO

## Limitations

Currently this framework has the following limitations on user design:

- Escaped identifiers are not allowed.
- Hierarchical connections are not supported. For example:

```verilog
module top (
    input           clk,
    input   [3:0]   a,
    output  [3:0]   b,
    output  [3:0]   c
);

    sub u_sub (
        .clk    (clk),
        .a      (a),
        .b      (b)
    );

    assign c = u_sub.c; // hierarchical connection

endmodule

module sub (
    input           clk,
    input   [3:0]   a,
    output  [3:0]   b
);

    reg [3:0] c;
    always @(posedge clk) c <= a;
    assign b = ~c;

endmodule
```
