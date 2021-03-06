module main_control_unit(inst,clock,reg_rd_control,exec_control,mem_control,wb_control,load_inst);
  
  parameter id_control_width=10;
  parameter exec_control_width=10;
  parameter mem_control_width=7;
  parameter wb_control_width=2;
  
  input wire [11:0] inst;        // inst contains bits 27:20, 7:4
  input wire clock;
  output wire [id_control_width-1:0] reg_rd_control;
  output wire [exec_control_width-1:0] exec_control;
  output wire [mem_control_width-1:0] mem_control;
  output wire [wb_control_width-1:0] wb_control; 
  output wire load_inst; 
  
  reg scr1_add_mux1,dest_add_mux2,rd1,rd2,rd3,rd4,set_write_bit,set_reg_update,rs1_pc_content_mux3,swp_rs2_rs4_mux8;    //ID phase controls
  
  reg load_type;
  
  reg shft_en,imm_reg,update_flags,carry_update;
  reg [3:0] alu_ctrl;             //EXEC phase controls
  reg [1:0] operand2_src_mux4;
  
  reg mem_rd,mem_wr,word_or_byte,mem_address_select_mux5,wb_content_select_mux6,base_reg_update_content_sel_mux7,swp; //MEM Phase control
  
  reg wr,reg_update; //WB Phase controls
  
  assign reg_rd_control={scr1_add_mux1,dest_add_mux2,rd1,rd2,rd3,rd4,
         set_write_bit,set_reg_update,rs1_pc_content_mux3,swp_rs2_rs4_mux8};
  assign exec_control={shft_en,imm_reg,alu_ctrl,update_flags,carry_update,operand2_src_mux4};
  assign mem_control={mem_rd,mem_wr,word_or_byte,mem_address_select_mux5,wb_content_select_mux6,base_reg_update_content_sel_mux7,swp};
  assign wb_control={wr,reg_update};
  assign load_inst=load_type;
  
  initial
  begin
   scr1_add_mux1=0;
   dest_add_mux2=0;
   swp_rs2_rs4_mux8=0;
   rd1=0;
   rd2=0;
   rd3=0;
   rd4=0;
   set_write_bit=0;
   rs1_pc_content_mux3=0;
   set_reg_update=0;
   
   load_type=0;
   
   shft_en=0;
   imm_reg=0;
   alu_ctrl=0;
   update_flags=0;
   carry_update=0;
   operand2_src_mux4=2'b00;
   mem_rd=0;
   mem_wr=0;
   word_or_byte=0;
   mem_address_select_mux5=0;
   wb_content_select_mux6=0;
   base_reg_update_content_sel_mux7=0;
   swp=0;
   
   wr=0;
   reg_update=0;
  end
    
  
  
  always@(posedge clock,inst)
  begin
    if(clock)
    begin
    case(inst[11:10])
      2'b00 :begin                                //DATA PROCESSING instructions
             if(inst[3:0]!=4'b1001)
             begin
               scr1_add_mux1=0;
               dest_add_mux2=0;
               swp_rs2_rs4_mux8=0;
               rd1=1;
               rd2=~inst[9];
               rd3=inst[0]&~inst[9];
               rd4=0;
               set_write_bit=1;
               rs1_pc_content_mux3=0;
               set_reg_update=0;
               
               load_type=0;
               
               shft_en=1;
               imm_reg=inst[9];
               alu_ctrl=inst[8:5];
               update_flags=inst[4];
               carry_update=~inst[9];
               operand2_src_mux4=2'b00;
               mem_rd=0;
               mem_wr=0;
               word_or_byte=0;
               mem_address_select_mux5=0;
               wb_content_select_mux6=1;
               base_reg_update_content_sel_mux7=0;
               swp=0;
               
               if(inst[8] & ~inst[7])   // TST,CMP,.. type instructions
                wr=0;
               else
                wr=1;
               reg_update=0;
             end
            else if(inst[9:7]==3'b010)          //SWAP instruction
               begin
               scr1_add_mux1=0;
               dest_add_mux2=0;
               swp_rs2_rs4_mux8=1;
               rd1=1;
               rd2=1;
               rd3=0;
               rd4=0;
               set_write_bit=1;
               rs1_pc_content_mux3=0;
               set_reg_update=0;
               
               load_type=0;
               
               shft_en=0;
               imm_reg=inst[9];
               alu_ctrl=inst[8:5];
               update_flags=0;
               carry_update=0;
               operand2_src_mux4=2'b00;
               mem_rd=1;
               mem_wr=1;
               word_or_byte=inst[6];
               mem_address_select_mux5=1;
               wb_content_select_mux6=0;
               base_reg_update_content_sel_mux7=1;
               swp=1;
               
               wr=1;
               reg_update=0;
               end
               
             end// end case 2'b00
             
      2'b01 :begin
             if(inst[4])              //LOAD Instruction
             begin
             scr1_add_mux1=0;
             dest_add_mux2=0;
             swp_rs2_rs4_mux8=0;
             rd1=1;
             rd2=inst[9];
             rd3=inst[0];
             rd4=0;
             set_write_bit=1;
             rs1_pc_content_mux3=0;
             set_reg_update=~inst[8]|inst[5];
             
             load_type=1;
             
             shft_en=1;
             imm_reg=~inst[9];
             alu_ctrl=inst[7]? 4'b0100:4'b0010;       //U bit determine up=1, or down=0
             update_flags=0;
             carry_update=inst[9];
             if(inst[9])      // register shifted
             operand2_src_mux4=2'b00;
             else
             operand2_src_mux4=2'b10;
             
             mem_rd=1;
             mem_wr=0;
             word_or_byte=inst[6];
             mem_address_select_mux5=~inst[8];      //P bit determine address for mem using mux
             wb_content_select_mux6=0;
             base_reg_update_content_sel_mux7=1;
             swp=0;
             
             wr=1;
             reg_update=~inst[8]|inst[5];
             end      // ends if load type
             
           else       // STORE instruction
             begin
             scr1_add_mux1=0;
             dest_add_mux2=0;
             swp_rs2_rs4_mux8=0;
             rd1=1;
             rd2=inst[9];
             rd3=inst[0];
             rd4=~inst[4];
             set_write_bit=0;
             rs1_pc_content_mux3=0;
             set_reg_update=~inst[8]|inst[5];
             
             load_type=0;
             
             shft_en=inst[9];
             imm_reg=~inst[9];
             alu_ctrl=inst[7]? 4'b0100:4'b0010;       //U bit determine up=1, or down=0
             update_flags=0;
             carry_update=inst[9];
             if(inst[9])      // register shifted
             operand2_src_mux4=2'b00;
             else
             operand2_src_mux4=2'b10;
             
             mem_rd=0;
             mem_wr=1;
             word_or_byte=inst[6];
             mem_address_select_mux5=~inst[8];      //P bit determine address for mem using mux
             wb_content_select_mux6=0;
             base_reg_update_content_sel_mux7=1;
             swp=0;
             
             wr=0;
             reg_update=~inst[8]|inst[5];
             end          // end else STR instruction
             
           end            // end case 2'b01
           
    2'b10 :begin
           if(inst[9])
           begin
           scr1_add_mux1=inst[8];       // if link high reg 14 selected as RS1
           dest_add_mux2=1;
           swp_rs2_rs4_mux8=0;
           rd1=1;
           rd2=0;
           rd3=0;
           rd4=0;
           set_write_bit=1;
           rs1_pc_content_mux3=1;
           set_reg_update=inst[8];
           
           load_type=0;
           
           shft_en=0;
           imm_reg=~inst[9];
           alu_ctrl=4'b0100;       //ALU operation--> add
           update_flags=0;
           carry_update=0;
           operand2_src_mux4=2'b11;
           
           mem_rd=0;
           mem_wr=0;
           word_or_byte=0;
           mem_address_select_mux5=1;      //P bit determine address for mem using mux
           wb_content_select_mux6=1;
           base_reg_update_content_sel_mux7=0;
           swp=0;
           
           wr=1;
           reg_update=inst[8];
           end            // end if inst[9]=1 if '0' block data transfer instruction
           end            // ends case 2'b10
           
   2'b11 : begin                //NULL instruction
           scr1_add_mux1=0;
           dest_add_mux2=0;
           swp_rs2_rs4_mux8=0;
           rd1=0;
           rd2=0;
           rd3=0;
           rd4=0;
           set_write_bit=0;
           rs1_pc_content_mux3=0;
           set_reg_update=0;
           
           load_type=0;
           
           shft_en=0;
           imm_reg=0;
           alu_ctrl=0;
           update_flags=0;
           carry_update=0;
           operand2_src_mux4=2'b00;
           mem_rd=0;
           mem_wr=0;
           word_or_byte=0;
           mem_address_select_mux5=0;
           wb_content_select_mux6=0;
           base_reg_update_content_sel_mux7=0;
           swp=0;
           
           wr=0;
           reg_update=0;
           end
             
    endcase
  end   //ends if
  end         
               
endmodule
  
  
