/*********** vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4 
 * DebugTrace.bsv
 */
package DebugTrace;

interface IDebugTrace;
    method Action debug(Fmt f);
    method Action trace(Fmt f);
endinterface


module mkDebugTrace#(parameter String ofile, parameter String snode_id)(IDebugTrace);
`ifdef FOR_SYNTHESIS
method Action debug = ?;
method Action trace = ?;

`else 
Reg#(Bool) initialized <- mkReg(False);
    Reg#(File) dlog <- mkReg(InvalidFile);
    Reg#(File) tlog <- mkReg(InvalidFile);
    Reg#(UInt#(32)) cticks <- mkReg(0);
`ifdef IVERILOG_SIM
    rule r0 (initialized == False && cticks == 1); // iverilog doesn't $fopen otherwise
`elsif VIVADO_XSIM
    rule r0 (initialized == False && cticks == 1); // xsim too
`else         
    rule r0 (initialized == False); 
`endif        
        String dof = ofile + "_node."+snode_id +".debug.log";
        String tof = ofile + "_node."+snode_id +".trace.log";
        let fdd <- $fopen(dof, "w");
        let fdt <- $fopen(tof, "w");
        dlog <= fdd;
        tlog <= fdt;
        initialized <= True;
        if ( (fdd==InvalidFile) || (fdt==InvalidFile) ) begin 
            $display("Cannot open debug or trace files at ", ofile, "\nQuitting."); 
            $finish(1);
        end else begin 
            $display("Debug and Trace files created");
        end 
    endrule 
    
    rule ticktock (True);
        cticks <= cticks + 1;
    endrule 

    method Action debug(Fmt f) if ( initialized == True );
        $fdisplay(dlog, $format("%d\t: tid=%s ", cticks, snode_id) + f);
        $display($format("%d\t: tid=%s ", cticks, snode_id) + f);
        $fflush(dlog);
    endmethod 
    method Action trace(Fmt f) if(initialized == True);
        $fdisplay(tlog, $format("tick: %d; tid: %s; ", cticks, snode_id) + f);
        $fflush(tlog);
    endmethod 
endmodule 
`endif    
endpackage
