module  u40spsram_256x10 (

    input           clka  , 
    input           ena   , 
    input           wea   , 
    input  [7:0]    addra , 
    input  [9:0]    dina  , 
    output [9:0]    douta  
  );

    U40SP_256X10M4 u_MEMB(
              .Q         (douta  ), 
              .CLK       (clka   ), 
              .CEN       (~ena   ), 
              .WEN       (~wea   ), 
              .A         (addra  ), 
              .D         (dina   ), 
              .EMA       (3'b000 ), 
              .EMAW      (2'b00  ), 
              .EMAS      (1'b0   ), 
              .RET1N     (1'b1   )
       );
       
endmodule
