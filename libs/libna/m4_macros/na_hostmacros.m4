m4_divert(-1)
m4_define(`m4_copy', `m4_define(`$2', m4_defn(`$1'))')m4_dnl
m4_define(`m4_copy_force',
                     `m4_ifdef(`$2', `m4_undefine(`$2')')m4_copy($@)')
m4_dnl----------use the discrete version of recv/send when NA_DISCRETE is mentioned
m4_define(`NA_DISCRETE',`m4_copy_force(`RECV',`RECVL') m4_copy_force(`SEND',`SENDL')  ')
m4_dnl----m4_define(`NA_RAW',`m4_copy_force(`RECV',`RECVRAW') m4_copy_force(`SEND',`SENDRAW')  ')

m4_define(NA_Def,`m4_define($*)#ifndef $1
#define $1 ($2)
#endif')
m4_define(NA_SCEMI,`m4_define(_generate_scemi_,1) m4_define(_generate_mpi_,0)
static NaSceMi scemi_;
')
m4_define(NA_MPI,`m4_define(_generate_mpi_,1)')
m4_define(NA_RAWIO,`m4_define(_generate_scemiraw_,1)')

m4_define(NA_INIT,`m4_ifelse(_generate_scemi_,1,`
  scemi_.init();
  scemi_.port_id = tid_$1; 
  scemi_.typetag_bitwidth = natypetags_bitwidth;
  scemi_.set_n_parameters();
')')
m4_dnl------------------------------------------------------------------------------------------------
m4_dnl argument 6 is optional
m4_define(`SENDcase1',`m4_ifelse(_generate_mpi_,1,`
  //$1_mpi $2_ = myconvert($2$6);
  $1_mpi tmptmp1_ = myconvert($2$6);
  MPI_Send(&tmptmp1_, $4, mpitype_$1, taskid_to_rank[tid_$5], natypetag_$1, MPI_COMM_WORLD);
',`
m4_dnl we know length passed is 1
  $1_scemi tmptmp1_ = myconvert($2$6);
  m4_ifelse(_generate_scemiraw_, 1, `
  scemi_.sendRAW(tid_$5, natypetag_$1, $1::size(), &tmptmp1_.pload);
  ',`
  scemi_.send_(tid_$5, natypetag_$1, $1::size(), &tmptmp1_.pload);
  ')
')
')

m4_dnl------------------------------------------------------------------------------------------------
m4_define(`SENDcase2',`
  unsigned offset=$3, length=$4;
  for(unsigned i=offset; i<offset+length; i++) {
    SENDcase1($1, $2, `unused', `1', $5, `[i]')
  }
')

m4_dnl------------------------------------------------------------------------------------------------
m4_dnl SEND(StructName, arraysymbol, offset, length, destination_taskname)
m4_dnl------------------------------------------------------------------------------------------------
m4_define(`SEND',`
{
m4_ifelse(m4_eval(($4)==1&&($3)==0),1,`SENDcase1($*)',`SENDcase2($*)')
}')

m4_dnl------------------------------------------------------------------------------------------------
m4_dnl argument 6 is optional
m4_define(`RECVcase1',`m4_ifelse(_generate_mpi_,1,`
  $1_mpi $2_;
  MPI_Recv(&$2_, $4, mpitype_$1, taskid_to_rank[tid_$5], natypetag_$1, MPI_COMM_WORLD, &mpistat);
  $2$6 = myconvert($2_);
',`
  $1_scemi $2_;
  m4_ifelse(_generate_scemiraw_, 1, `
  scemi_.recvRAW(tid_$5, natypetag_$1, $1::size(), &$2_.pload);
  ',`
  scemi_.recv_(tid_$5, natypetag_$1, $1::size(), &$2_.pload);
  ')
  $2$6 = myconvert($2_);
')
')

m4_dnl------------------------------------------------------------------------------------------------
m4_define(`RECVcase2',`
  unsigned offset=$3, length=$4;
  for(unsigned i=offset; i<offset+length; i++) {
    RECVcase1($1, $2, `unused', `1', $5, `[i]')
  }
')

m4_dnl------------------------------------------------------------------------------------------------
m4_dnl RECV(StructName, arraysymbol, offset, length, source_taskname)
m4_dnl------------------------------------------------------------------------------------------------
m4_define(`RECV',`
{
m4_ifelse(m4_eval($4==1&&$3==0),1,`RECVcase1($*)',`RECVcase2($*)')
}')


m4_dnl------------------------------------------------------------------------------------------------
m4_dnl 
m4_define(`RECVL',`m4_ifelse(_generate_mpi_,1,`
  {const unsigned offset=$3, length=$4;
  $1_mpi $2_[length];
  MPI_Recv(&$2_[0], length, mpitype_$1, taskid_to_rank[tid_$5], natypetag_$1, MPI_COMM_WORLD, &mpistat);
  for(unsigned i=offset; i<offset+length; i++) {
    $2[i] = myconvert($2_[i-offset]);
  }
  }
',`
  {const unsigned offset=$3, length=$4;
  $1_scemi $2_[length];
  scemi_.recvl(tid_$5, natypetag_$1, $1::size(), length, &$2_[0]);
  for(unsigned i=offset; i<offset+length; i++) {
    $2[i] = myconvert($2_[i-offset]);
  }
  }
')
')
m4_dnl------------------------------------------------------------------------------------------------
m4_dnl 
m4_define(`SENDL',`m4_ifelse(_generate_mpi_,1,`
  {const unsigned offset=$3, length=$4;
  $1_mpi $2_[length];
  for(unsigned i=offset; i<offset+length; i++) {
    $2_[i-offset] = myconvert($2[i]);
  }
  MPI_Send(&$2_[0], length, mpitype_$1, taskid_to_rank[tid_$5], natypetag_$1, MPI_COMM_WORLD);
  }
',`
  {const unsigned offset=$3, length=$4;
  $1_scemi $2_[length];
  for(unsigned i=offset; i<offset+length; i++) {
    $2_[i-offset] = myconvert($2[i]);
  }
  scemi_.sendl(tid_$5, natypetag_$1, $1::size(), length, &$2_[0]);
  }
')
')
m4_divert(0)
