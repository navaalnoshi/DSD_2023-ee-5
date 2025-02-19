

module Lab_4(
     input logic a1,                                                             
     input logic a0,                                                             
     input logic b1,                                                             
     input logic b0,                                                             
     output logic r,                                                             
     output logic b,                                                             
     output logic g                                                              
);                                                                              
                                                                            
    assign r= (a1 & a0) | (a1 & ~b1) | (a1 & ~b0) | (~b1 & ~b0) | (~b1 & a0) ;  
    assign g= (~a1 & ~a0 ) |(~a0 & b1)| (~a1 & b1)| (~a1 & b0) | (b1 & b0)  ;   
    assign b= (a0 & ~b0) | (a1 & ~b1) | (~a0 & b0) | (~a1 & b1);      
    
endmodule
