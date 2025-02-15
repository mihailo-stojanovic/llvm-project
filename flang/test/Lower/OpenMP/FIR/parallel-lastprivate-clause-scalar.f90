! This test checks lowering of `LASTPRIVATE` clause for scalar types.

! RUN: bbc -fopenmp -emit-fir %s -o - | FileCheck %s
! RUN: flang-new -fc1 -fopenmp -emit-fir %s -o - | FileCheck %s

!CHECK: func @_QPlastprivate_character(%[[ARG1:.*]]: !fir.boxchar<1>{{.*}}) {
!CHECK-DAG: %[[ARG1_UNBOX:.*]]:2 = fir.unboxchar
!CHECK-DAG: %[[FIVE:.*]] = arith.constant 5 : index
!CHECK-DAG: %[[ARG1_REF:.*]] = fir.convert %[[ARG1_UNBOX]]#0 : (!fir.ref<!fir.char<1,?>>) -> !fir.ref<!fir.char<1,5>>

!CHECK: omp.parallel {
!CHECK-DAG: %[[ARG1_PVT:.*]] = fir.alloca !fir.char<1,5> {bindc_name = "arg1", 

! Check that we are accessing the clone inside the loop
!CHECK-DAG: omp.wsloop for (%[[INDX_WS:.*]]) : {{.*}} {
!CHECK-DAG: %[[NEG_ONE:.*]] = arith.constant -1 : i32
!CHECK-NEXT: %[[ADDR:.*]] = fir.address_of(@_QQclX
!CHECK-NEXT: %[[CVT0:.*]] = fir.convert %[[ADDR]] 
!CHECK-NEXT: %[[CNST:.*]] = arith.constant
!CHECK-NEXT: %[[CALL_BEGIN_IO:.*]] = fir.call @_FortranAioBeginExternalListOutput(%[[NEG_ONE]], %[[CVT0]], %[[CNST]]) {{.*}}: (i32, !fir.ref<i8>, i32) -> !fir.ref<i8>
!CHECK-NEXT: %[[CVT_0_1:.*]] = fir.convert %[[ARG1_PVT]] 
!CHECK-NEXT: %[[CVT_0_2:.*]] = fir.convert %[[FIVE]]
!CHECK-NEXT: %[[CALL_OP_ASCII:.*]] = fir.call @_FortranAioOutputAscii(%[[CALL_BEGIN_IO]], %[[CVT_0_1]], %[[CVT_0_2]])
!CHECK-NEXT: %[[CALL_END_IO:.*]] = fir.call @_FortranAioEndIoStatement(%[[CALL_BEGIN_IO]])

! Testing last iteration check
!CHECK: %[[V:.*]] = arith.addi %[[INDX_WS]], %{{.*}} : i32
!CHECK: %[[C0:.*]] = arith.constant 0 : i32
!CHECK: %[[T1:.*]] = arith.cmpi slt, %{{.*}}, %[[C0]] : i32
!CHECK: %[[T2:.*]] = arith.cmpi slt, %[[V]], %{{.*}} : i32
!CHECK: %[[T3:.*]] = arith.cmpi sgt, %[[V]], %{{.*}} : i32
!CHECK: %[[IV_CMP:.*]] = arith.select %[[T1]], %[[T2]], %[[T3]] : i1
!CHECK: fir.if %[[IV_CMP]] {
!CHECK: fir.store %[[V]] to %{{.*}} : !fir.ref<i32>

! Testing lastprivate val update
!CHECK-DAG: %[[CVT:.*]] = fir.convert %[[ARG1_REF]] : (!fir.ref<!fir.char<1,5>>) -> !fir.ref<i8>
!CHECK-DAG: %[[CVT1:.*]] = fir.convert %[[ARG1_PVT]] : (!fir.ref<!fir.char<1,5>>) -> !fir.ref<i8>
!CHECK-DAG: fir.call @llvm.memmove.p0.p0.i64(%[[CVT]], %[[CVT1]]{{.*}})
!CHECK-DAG: } 
!CHECK-DAG: omp.yield

subroutine lastprivate_character(arg1)
        character(5) :: arg1
!$OMP PARALLEL 
!$OMP DO LASTPRIVATE(arg1)
do n = 1, 5
        arg1(n:n) = 'c'
        print *, arg1
end do
!$OMP END DO
!$OMP END PARALLEL
end subroutine

!CHECK: func @_QPlastprivate_int(%[[ARG1:.*]]: !fir.ref<i32> {fir.bindc_name = "arg1"}) {
!CHECK-DAG: omp.parallel  {
!CHECK-DAG: %[[CLONE:.*]] = fir.alloca i32 {bindc_name = "arg1"
!CHECK: omp.wsloop for (%[[INDX_WS:.*]]) : {{.*}} {

! Testing last iteration check
!CHECK: %[[V:.*]] = arith.addi %[[INDX_WS]], %{{.*}} : i32
!CHECK: %[[C0:.*]] = arith.constant 0 : i32
!CHECK: %[[T1:.*]] = arith.cmpi slt, %{{.*}}, %[[C0]] : i32
!CHECK: %[[T2:.*]] = arith.cmpi slt, %[[V]], %{{.*}} : i32
!CHECK: %[[T3:.*]] = arith.cmpi sgt, %[[V]], %{{.*}} : i32
!CHECK: %[[IV_CMP:.*]] = arith.select %[[T1]], %[[T2]], %[[T3]] : i1
!CHECK: fir.if %[[IV_CMP]] {
!CHECK: fir.store %[[V]] to %{{.*}} : !fir.ref<i32>

! Testing lastprivate val update
!CHECK-NEXT: %[[CLONE_LD:.*]] = fir.load %[[CLONE]] : !fir.ref<i32>
!CHECK-NEXT: fir.store %[[CLONE_LD]] to %[[ARG1]] : !fir.ref<i32>
!CHECK-DAG: }
!CHECK-DAG: omp.yield

subroutine lastprivate_int(arg1)
        integer :: arg1
!$OMP PARALLEL 
!$OMP DO LASTPRIVATE(arg1)
do n = 1, 5
        arg1 = 2
        print *, arg1
end do
!$OMP END DO
!$OMP END PARALLEL
print *, arg1
end subroutine

!CHECK: func.func @_QPmult_lastprivate_int(%[[ARG1:.*]]: !fir.ref<i32> {fir.bindc_name = "arg1"}, %[[ARG2:.*]]: !fir.ref<i32> {fir.bindc_name = "arg2"}) {
!CHECK: omp.parallel  {
!CHECK-DAG: %[[CLONE1:.*]] = fir.alloca i32 {bindc_name = "arg1"
!CHECK-DAG: %[[CLONE2:.*]] = fir.alloca i32 {bindc_name = "arg2"
!CHECK: omp.wsloop for (%[[INDX_WS:.*]]) : {{.*}} {

! Testing last iteration check
!CHECK: %[[V:.*]] = arith.addi %[[INDX_WS]], %{{.*}} : i32
!CHECK: %[[C0:.*]] = arith.constant 0 : i32
!CHECK: %[[T1:.*]] = arith.cmpi slt, %{{.*}}, %[[C0]] : i32
!CHECK: %[[T2:.*]] = arith.cmpi slt, %[[V]], %{{.*}} : i32
!CHECK: %[[T3:.*]] = arith.cmpi sgt, %[[V]], %{{.*}} : i32
!CHECK: %[[IV_CMP:.*]] = arith.select %[[T1]], %[[T2]], %[[T3]] : i1
!CHECK: fir.if %[[IV_CMP]] {
!CHECK: fir.store %[[V]] to %{{.*}} : !fir.ref<i32>
! Testing lastprivate val update
!CHECK-DAG: %[[CLONE_LD1:.*]] = fir.load %[[CLONE1]] : !fir.ref<i32>
!CHECK-DAG: fir.store %[[CLONE_LD1]] to %[[ARG1]] : !fir.ref<i32>
!CHECK-DAG: %[[CLONE_LD2:.*]] = fir.load %[[CLONE2]] : !fir.ref<i32>
!CHECK-DAG: fir.store %[[CLONE_LD2]] to %[[ARG2]] : !fir.ref<i32>
!CHECK: }
!CHECK: omp.yield

subroutine mult_lastprivate_int(arg1, arg2)
        integer :: arg1, arg2
!$OMP PARALLEL 
!$OMP DO LASTPRIVATE(arg1) LASTPRIVATE(arg2)
do n = 1, 5
        arg1 = 2
        arg2 = 3
        print *, arg1, arg2
end do
!$OMP END DO
!$OMP END PARALLEL
print *, arg1, arg2
end subroutine

!CHECK: func.func @_QPmult_lastprivate_int2(%[[ARG1:.*]]: !fir.ref<i32> {fir.bindc_name = "arg1"}, %[[ARG2:.*]]: !fir.ref<i32> {fir.bindc_name = "arg2"}) {
!CHECK: omp.parallel  {
!CHECK-DAG: %[[CLONE1:.*]] = fir.alloca i32 {bindc_name = "arg1"
!CHECK-DAG: %[[CLONE2:.*]] = fir.alloca i32 {bindc_name = "arg2"
!CHECK: omp.wsloop for (%[[INDX_WS:.*]]) : {{.*}} {

!Testing last iteration check
!CHECK: %[[V:.*]] = arith.addi %[[INDX_WS]], %{{.*}} : i32
!CHECK: %[[C0:.*]] = arith.constant 0 : i32
!CHECK: %[[T1:.*]] = arith.cmpi slt, %{{.*}}, %[[C0]] : i32
!CHECK: %[[T2:.*]] = arith.cmpi slt, %[[V]], %{{.*}} : i32
!CHECK: %[[T3:.*]] = arith.cmpi sgt, %[[V]], %{{.*}} : i32
!CHECK: %[[IV_CMP:.*]] = arith.select %[[T1]], %[[T2]], %[[T3]] : i1
!CHECK: fir.if %[[IV_CMP]] {
!CHECK: fir.store %[[V]] to %{{.*}} : !fir.ref<i32>
!Testing lastprivate val update
!CHECK-DAG: %[[CLONE_LD2:.*]] = fir.load %[[CLONE2]] : !fir.ref<i32>
!CHECK-DAG: fir.store %[[CLONE_LD2]] to %[[ARG2]] : !fir.ref<i32>
!CHECK-DAG: %[[CLONE_LD1:.*]] = fir.load %[[CLONE1]] : !fir.ref<i32>
!CHECK-DAG: fir.store %[[CLONE_LD1]] to %[[ARG1]] : !fir.ref<i32>
!CHECK: }
!CHECK: omp.yield

subroutine mult_lastprivate_int2(arg1, arg2)
        integer :: arg1, arg2
!$OMP PARALLEL 
!$OMP DO LASTPRIVATE(arg1, arg2)
do n = 1, 5
        arg1 = 2
        arg2 = 3
        print *, arg1, arg2
end do
!$OMP END DO
!$OMP END PARALLEL
print *, arg1, arg2
end subroutine

!CHECK: func.func @_QPfirstpriv_lastpriv_int(%[[ARG1:.*]]: !fir.ref<i32> {fir.bindc_name = "arg1"}, %[[ARG2:.*]]: !fir.ref<i32> {fir.bindc_name = "arg2"}) {
!CHECK: omp.parallel  {
! Firstprivate update
!CHECK-DAG: %[[CLONE1:.*]] = fir.alloca i32 {bindc_name = "arg1"
!CHECK-DAG: %[[FPV_LD:.*]] = fir.load %[[ARG1]] : !fir.ref<i32>
!CHECK-DAG: fir.store %[[FPV_LD]] to %[[CLONE1]] : !fir.ref<i32>
! Lastprivate Allocation
!CHECK-DAG: %[[CLONE2:.*]] = fir.alloca i32 {bindc_name = "arg2"
!CHECK-NOT: omp.barrier
!CHECK: omp.wsloop for (%[[INDX_WS:.*]]) : {{.*}} {

! Testing last iteration check
!CHECK: %[[V:.*]] = arith.addi %[[INDX_WS]], %{{.*}} : i32
!CHECK: %[[C0:.*]] = arith.constant 0 : i32
!CHECK: %[[T1:.*]] = arith.cmpi slt, %{{.*}}, %[[C0]] : i32
!CHECK: %[[T2:.*]] = arith.cmpi slt, %[[V]], %{{.*}} : i32
!CHECK: %[[T3:.*]] = arith.cmpi sgt, %[[V]], %{{.*}} : i32
!CHECK: %[[IV_CMP:.*]] = arith.select %[[T1]], %[[T2]], %[[T3]] : i1
!CHECK: fir.if %[[IV_CMP]] {
!CHECK: fir.store %[[V]] to %{{.*}} : !fir.ref<i32>
! Testing lastprivate val update
!CHECK-NEXT: %[[CLONE_LD:.*]] = fir.load %[[CLONE2]] : !fir.ref<i32>
!CHECK-NEXT: fir.store %[[CLONE_LD]] to %[[ARG2]] : !fir.ref<i32>
!CHECK-NEXT: }
!CHECK-NEXT: omp.yield

subroutine firstpriv_lastpriv_int(arg1, arg2)
        integer :: arg1, arg2
!$OMP PARALLEL 
!$OMP DO FIRSTPRIVATE(arg1) LASTPRIVATE(arg2)
do n = 1, 5
        arg1 = 2
        arg2 = 3
        print *, arg1, arg2
end do
!$OMP END DO
!$OMP END PARALLEL
print *, arg1, arg2
end subroutine

!CHECK: func.func @_QPfirstpriv_lastpriv_int2(%[[ARG1:.*]]: !fir.ref<i32> {fir.bindc_name = "arg1"}) {
!CHECK: omp.parallel  {
! Firstprivate update
!CHECK: %[[CLONE1:.*]] = fir.alloca i32 {bindc_name = "arg1"
!CHECK-NEXT: %[[FPV_LD:.*]] = fir.load %[[ARG1]] : !fir.ref<i32>
!CHECK-NEXT: fir.store %[[FPV_LD]] to %[[CLONE1]] : !fir.ref<i32>
!CHECK-NEXT: omp.barrier
!CHECK: omp.wsloop for (%[[INDX_WS:.*]]) : {{.*}} {
! Testing last iteration check
!CHECK: %[[V:.*]] = arith.addi %[[INDX_WS]], %{{.*}} : i32
!CHECK: %[[C0:.*]] = arith.constant 0 : i32
!CHECK: %[[T1:.*]] = arith.cmpi slt, %{{.*}}, %[[C0]] : i32
!CHECK: %[[T2:.*]] = arith.cmpi slt, %[[V]], %{{.*}} : i32
!CHECK: %[[T3:.*]] = arith.cmpi sgt, %[[V]], %{{.*}} : i32
!CHECK: %[[IV_CMP:.*]] = arith.select %[[T1]], %[[T2]], %[[T3]] : i1
!CHECK: fir.if %[[IV_CMP]] {
!CHECK: fir.store %[[V]] to %{{.*}} : !fir.ref<i32>
! Testing lastprivate val update
!CHECK-NEXT: %[[CLONE_LD:.*]] = fir.load %[[CLONE1]] : !fir.ref<i32>
!CHECK-NEXT: fir.store %[[CLONE_LD]] to %[[ARG1]] : !fir.ref<i32>
!CHECK-NEXT: }
!CHECK-NEXT: omp.yield

subroutine firstpriv_lastpriv_int2(arg1)
        integer :: arg1
!$OMP PARALLEL 
!$OMP DO FIRSTPRIVATE(arg1) LASTPRIVATE(arg1)
do n = 1, 5
        arg1 = 2
        print *, arg1
end do
!$OMP END DO
!$OMP END PARALLEL
print *, arg1
end subroutine
