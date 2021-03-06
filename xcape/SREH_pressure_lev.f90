!-----------------------------------------------------------------------
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!-----------------------------------------------------------------------
      SUBROUTINE loop_sreh_pl(u, v, aglh, us, vs, aglhs, &
                          &cu, cv, top, start_3d, &
                          &nk, n2, sreh)
      IMPLICIT NONE

      !f2py threadsafe
      !f2py intent(out) :: sreh

      INTEGER, INTENT(IN) :: nk, n2
      REAL(KIND=8), DIMENSION(nk ,n2), INTENT(IN) :: u, v,aglh
      REAL(KIND=8), INTENT(IN) :: top
      REAL(KIND=8), DIMENSION(n2), INTENT(IN) :: us, vs, aglhs, start_3d
      REAL(KIND=8), DIMENSION(n2), INTENT(IN) :: cu, cv
      REAL(KIND=8), DIMENSION(n2), INTENT(OUT) :: sreh
      INTEGER :: i, nk_all, nk_pl_in, nk_start
      ! at most, the number of levels will be 3d +  surface
      REAL(KIND=8), DIMENSION(nk+1) :: u_all, v_all, aglh_all


      do i = 1, n2
          nk_start = start_3d(i)
          ! compute number of used levels in 3d
          nk_pl_in = nk - nk_start + 1
          ! compute number of used levels in 3d + surface
          nk_all = nk_pl_in+1

          u_all(1) = us(i)
          v_all(1) = vs(i)
          aglh_all(1) = aglhs(i)
          u_all(2:nk_all) = u(nk_start:nk,i)
          v_all(2:nk_all) = v(nk_start:nk,i)
          aglh_all(2:nk_all) = aglh(nk_start:nk,i)

          call DCALRELHL_pl(u_all, v_all, aglh_all, &
          &cu(i), cv(i), top, nk_all, sreh(i) )
      enddo
      return
      end subroutine loop_sreh_pl

      !-----------------------------------------------------------------------
      !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      !-----------------------------------------------------------------------

      SUBROUTINE DCALRELHL_pl(u, v, aglh, cu, cv, top, nk, sreh )

      IMPLICIT NONE

      !f2py threadsafe
      !f2py intent(out) :: sreh

      INTEGER, INTENT(IN) :: nk
      REAL(KIND=8), DIMENSION(nk), INTENT(IN) :: u, v,aglh
      REAL(KIND=8), INTENT(IN) :: top
      REAL(KIND=8), DIMENSION(1), INTENT(IN) :: cu, cv
      REAL(KIND=8), DIMENSION(1), INTENT(OUT) :: sreh
      REAL(KIND=8) :: INTERP1


      ! This helicity code was provided by Dr. Craig Mattocks, and
      ! verified by Cindy Bruyere to produce results equivalent to
      ! those generated by RIP4. (The code came from RIP4?)
      ! The original code has been modified by John T. Allen to a
      ! new version which takes input storm motion and outputs SRH.

      REAL(KIND=8), DIMENSION(1) :: x, sum
      REAL(KIND=8), DIMENSION(nk) :: utop,vtop
      INTEGER :: k, ktop

      utop = u
      vtop = v
      ktop = 0
      DO k = 2 , nk
          IF (((aglh(k)) .GT. top) .AND. &
             (ktop .EQ.0)) THEN
              ktop = k
              ! Remember the arrays are inverted hence ktop+1
              utop(ktop) = INTERP1(u(ktop),u(ktop-1), &
                     aglh(ktop),top,aglh(ktop-1))
              vtop(ktop) = INTERP1(v(ktop),v(ktop-1), &
                     aglh(ktop),top,aglh(ktop-1))

          ENDIF
      END DO
      !u(ktop,j)=utop(ktop,j)
      !v(ktop,j)=vtop(ktop,j)

      sum = 0.D0
      DO k = 2, ktop
          x = ((utop(k) - cu)*(vtop(k) - vtop(k-1))) - &
              ((vtop(k) - cv)*(utop(k) - utop(k-1)))
          sum = sum + x
      END DO
      sreh = -sum

      RETURN

      END SUBROUTINE DCALRELHL_pl

!-------Functions - Interpolation
!-------Given Y1 at X1, Y3 at X3, and X2, Calculate Y2(Interp) at X2

      REAL(KIND=8) FUNCTION INTERP1(Y1,Y3,X1,X2,X3)
      IMPLICIT NONE
      REAL(KIND=8) :: Y1,Y3,X1,X2,X3
      IF (X3.EQ.X1) X1=X1-0.01
      INTERP1 = Y1+((Y3-Y1)*((X2-X1)/(X3-X1)))
      RETURN
      END FUNCTION INTERP1
