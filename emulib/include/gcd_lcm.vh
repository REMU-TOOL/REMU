function automatic integer f_gcd (
    input integer a,
    input integer b
);
begin
    if (b == 0)
        f_gcd = a;
    else
        f_gcd = f_gcd(b, a % b);
end
endfunction

function integer f_lcm (
    input integer a,
    input integer b
);
begin
    f_lcm = a / f_gcd(a, b) * b;
end
endfunction
