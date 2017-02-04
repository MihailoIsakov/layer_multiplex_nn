//define the log2 function
function integer log2;
    input integer num;
    integer i, result;
    begin
        for (i = 0; 2 ** i < num; i = i + 1)
            result = i + 1;
        log2 = result;
    end
endfunction
