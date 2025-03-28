function HF_ERPA_Export(Params::Vector{Any},Orb::Vector{NOrb},N_nu::Matrix{Int64},E_0_RPA::Float64,E_RPA::Matrix{Vector{ComplexF64}},X_RPA::Matrix{Matrix{ComplexF64}},Y_RPA::Matrix{Matrix{ComplexF64}},s_RPA::Matrix{Vector{Float64}},rB_RPA::ReducedTransition,pRho::Matrix{Float64},nRho::Matrix{Float64})
    
    # Export ERPA summary file ...
    @time HF_ERPA_Summary(Params,N_nu,E_0_RPA)

    # Export of ERPA spectra ...
    @time HF_ERPA_Spectrum_Export(Params,N_nu,E_RPA,s_RPA)

    # Export of ERPA plot-ready spectra ...
    @time HF_ERPA_Plot_Spectrum_Export(Params,N_nu,E_RPA)

    # Export single-particle level occupations ...
    @time HF_ERPA_Occupation_Export(Params,Orb,pRho,nRho)

    # Export ERPA radial densities & radii ...
    @time HF_ERPA_Radial_Density(Params,Orb,pRho,nRho)

    # Export of ERPA |X|^2 & |Y|^2 amplitudes, not plot ready ...
    @time HF_ERPA_Amplitudes_Export(Params,N_nu,E_RPA,X_RPA,Y_RPA)

    # Export of plot ready |Y|^2 ERPA amplitudes ...
    @time HF_ERPA_Y_Export(Params,N_nu,E_RPA,Y_RPA)

    # Export of ERPA electric transitions ...
    @time HF_ERPA_Transition_Export(Params,N_nu,E_RPA,rB_RPA)

    # Export of ERPA electric transitions strength function S_0 ...
    @time HF_ERPA_S0_Export(Params,N_nu,E_RPA,rB_RPA)

    # Export of ERPA eletric photoabsorbtion cross-sections ...
    @time HF_ERPA_Sigma_Export(Params,N_nu,E_RPA,rB_RPA)

    # Export dimensions of phonon subspaces ...
    @time HF_ERPA_Phonon_Space_Export(Params,N_nu)

    # Export sums of |Y|^2 for every J ...
    @time HF_ERPA_Y_Sum_Export(Params,N_nu,Y_RPA)

    return
end

function HF_ERPA_Summary(Params::Vector{Any},N_nu::Matrix{Int64},E_0::Float64)
    # Read calculation parameters ...
    A = Params[1]
    Z = Params[2]
    HbarOmega = Params[3]
    N_max = Params[4]
    N_2max = 2*N_max
    J_max = N_2max + 1
    Orthogon = Params[5]
    Output_File = Params[8]

    # Export name & path ...
    if Orthogon == true
        Output_Path = Output_File * "/ERPA/HF_ERPA_Summary_Ortho.dat"
    else
        Output_Path = Output_File * "/ERPA/HF_ERPA_Summary_Spur.dat"
    end
    
    println("\nPreparing ERPA summary ...")
    Summary_File =  open(Output_Path, "w")
        println(Summary_File, "Spherical Hartree-Fock Extended-Random-Phase Approximation review:")
        println(Summary_File, "\nNuclid data:    A = " * string(A) * ", Z = " * string(Z))
        println(Summary_File, "\nCalculation data:    HbarOmega = " * string(HbarOmega) * " , N_max = " * string(N_max) *
                ", s.p. J-basis size = " * string(div((N_max+1)*(N_max+2),2)) * ", s.p. M-basis size = " * string(div((N_max+1)*(N_max+2)*(N_max+3),6)))
        if Orthogon == true
            println(Summary_File, "\nOrthogonalization of 1- spurious state included ...")
        else
            println(Summary_File, "\nOrthogonalization of 1- spurious state not included ...")
        end
        N_M_tot = 0
        @inbounds for J in 0:J_max
            @inbounds for P in 1:2
                n = N_nu[J+1,P] * (2*J + 1)
                N_M_tot += n
            end
        end
        println(Summary_File, "\nTotal number of 1 phonon states in J-scheme = " * string(sum(N_nu)))
        println(Summary_File, "Total number of 1 phonon states in M-scheme = " * string(N_M_tot))
        println(Summary_File, "\nE_Corr_ERPA = " * string(round(E_0, digits = 8)) * "\t MeV \t...\tERPA ground-state correlation energy")
        println(Summary_File, "\n\tTo get the total correct ground-state energy add the HF-mean field energy ...")
    close(Summary_File)

    println("\nERPA summary exported ...")

    return

end

function HF_ERPA_Spectrum_Export(Params::Vector{Any},N_nu::Matrix{Int64},E_RPA::Matrix{Vector{ComplexF64}},s_RPA::Matrix{Vector{Float64}})
    # Read calculation parameters ...
    N_max = Params[4]
    N_2max = 2*N_max
    J_max = N_2max + 1
    Orthogon = Params[5]
    Output_File = Params[8]

    # Export name & path ...
    if Orthogon == true
        Output_Path_RPA = Output_File * "/ERPA/Spectra/ERPA_Ortho.dat"
    else
        Output_Path_RPA = Output_File * "/ERPA/Spectra/ERPA_Spur.dat"
    end

    println("\nPreparing ERPA spectra export ...")

    # ERPA spectrum export
    open(Output_Path_RPA, "w") do Write_File
        println(Write_File, "s\tJ\tP\tE")
        @inbounds for J in 0:J_max
            @inbounds for P in 1:2
                N_ph = N_nu[J+1,P]
                @inbounds for nu in 1:N_ph
                    if P == 1
                        println(Write_File, string(round(s_RPA[J+1,P][nu],digits=4)) * "\t" * string(J) * "\t" * "+" * "\t" * string(E_RPA[J+1,P][nu]))
                    else
                        println(Write_File, string(round(s_RPA[J+1,P][nu],digits=4)) * "\t" * string(J) * "\t" * "-" * "\t" * string(E_RPA[J+1,P][nu]))
                    end
                end
                println(Write_File,"\n")
            end
        end
    end

    println("\nERPA spectra export finished ...")

    return
end

function HF_ERPA_Plot_Spectrum_Export(Params::Vector{Any},N_nu::Matrix{Int64},E_RPA::Matrix{Vector{ComplexF64}})
    # Read calculation parameters ...
    N_max = Params[4]
    N_2max = 2*N_max
    J_max = N_2max + 1
    Orthogon = Params[5]
    Output_File = Params[8]

    # Export name & path ...
    if Orthogon == true
        Output_Path_RPA = Output_File * "/ERPA/Spectra/ERPA_Plot_Ortho.dat"
    else
        Output_Path_RPA = Output_File * "/ERPA/Spectra/ERPA_Plot_Spur.dat"
    end

    # Spectra label gap parameter ...
    Delta = 1.0

    println("\nPreparing plot-ready export of RPAsolutions ...")

    N_ph = Int64(sum(N_nu))

    RPA_Solution = Matrix{Float64}(undef,4,N_ph+1)

    # 0+ ground state addition ...

    RPA_Solution[1,1] = 0.0
    RPA_Solution[2,1] = 1.0
    RPA_Solution[3,1] = 0.0
    RPA_Solution[4,1] = 0.0

    nu_count = 1
    @inbounds for J in 0:J_max
        @inbounds for P in 1:2
            N_qg = N_nu[J+1,P]
            @inbounds for nu in 1:N_qg
                nu_count += 1
                RPA_Solution[1,nu_count] = Float64(J)
                RPA_Solution[2,nu_count] = Float64(P)
                RPA_Solution[3,nu_count] = real(E_RPA[J+1,P][nu])
                RPA_Solution[4,nu_count] = real(E_RPA[J+1,P][nu])
            end
        end
    end

    E_RPA_full = @views RPA_Solution[3,:]

    Sort_RPA = sortperm(E_RPA_full, by = x -> real(x))

    RPA_Solution .= @views RPA_Solution[:,Sort_RPA]

    # Adjust the JP label positions ...
    @inbounds for nu in 2:(N_ph+1)

        e_RPA_1 = RPA_Solution[4,nu-1]
        e_RPA_2 = RPA_Solution[4,nu]
        if e_RPA_2 < e_RPA_1
            RPA_Solution[4,nu] = e_RPA_1 + 1.0
        elseif abs(e_RPA_2 - e_RPA_1) < Delta
            RPA_Solution[4,nu] = e_RPA_1 + 1.0
        end
    end

    # RPA spectrum plot data export ...
    open(Output_Path_RPA, "w") do Write_File
        println(Write_File, "J\tP\tE\tm")
        @inbounds for nu in 1:N_ph
            J = Int64(round(RPA_Solution[1,nu]))
            P = "P"
            if abs(RPA_Solution[2,nu] - 1.0) < 1e-3
                P = "+"
            else
                P = "-"
            end
            E = RPA_Solution[3,nu]
            E_m = RPA_Solution[4,nu]
            Row = string(string(J) * "\t" * P * "\t" * string(round(E,sigdigits = 5)) * "\t" * string(round(E_m,sigdigits = 5)))
            println(Write_File, Row)
        end
    end

    println("\nRPA & TDA plot-ready solutions exported ...")

    return
end

function HF_ERPA_Occupation_Export(Params::Vector{Any},Orb::Vector{NOrb},pRho::Matrix{Float64},nRho::Matrix{Float64})
    # Read parameters ...
    N_max = Params[4]
    a_max = div((N_max+1)*(N_max+2),2)
    Orthogon = Params[5]
    Output_File = Params[8]

    if Orthogon == true
        Output_Path_RPA = Output_File * "/ERPA/Densities/ERPA_Occupation_Ortho.dat"
    else
        Output_Path_RPA = Output_File * "/ERPA/Densities/ERPA_Occupation_Spur.dat"
    end
    
    # Make HF density matrices ...
    pRho_HF, nRho_HF = zeros(Float64,a_max,a_max), zeros(Float64,a_max,a_max)
    @inbounds for a in 1:a_max
        pRho_HF[a,a] = Orb[a].pO
        nRho_HF[a,a] = Orb[a].nO
    end

    pO_HF = Vector{Float64}(undef,a_max)
    nO_HF = Vector{Float64}(undef,a_max)
    pO_ERPA = Vector{Float64}(undef,a_max)
    nO_ERPA = Vector{Float64}(undef,a_max)
    pa = Vector{Int64}(undef,a_max)
    na = Vector{Int64}(undef,a_max)

    @inbounds for a in 1:a_max
        pO_HF[a] = pRho_HF[a,a]
        nO_HF[a] = nRho_HF[a,a]
        pO_ERPA[a] = round(pRho[a,a], digits = 4)
        nO_ERPA[a] = round(nRho[a,a], digits = 4)
        pa[a] = a
        na[a] = a
    end

    Sort_pInd = sortperm(pO_ERPA, rev = true)
    Sort_nInd = sortperm(nO_ERPA, rev = true)

    pO_HF = pO_HF[Sort_pInd]
    pO_ERPA = pO_ERPA[Sort_pInd]
    pa = pa[Sort_pInd]

    nO_HF = nO_HF[Sort_nInd]
    nO_ERPA = nO_ERPA[Sort_nInd]
    na = na[Sort_nInd]

    # RPA spectrum export
    open(Output_Path_RPA, "w") do Write_File
        println(Write_File, "a\ta_p\tpN_HF\tpN_ERPA\ta_n\tnH_HF\tnN_ERPA")
        @inbounds for a in 1:a_max
            println(Write_File, string(a) * "\t" * string(pa[a]) * "\t" * string(pO_HF[a]) * "\t" * string(pO_ERPA[a]) * "\t" * string(na[a]) * "\t" * string(nO_HF[a]) * "\t" * string(nO_ERPA[a]))
        end
    end

end

function HF_ERPA_Amplitudes_Export(Params::Vector{Any},N_nu::Matrix{Int64},E_RPA::Matrix{Vector{ComplexF64}},X_RPA::Matrix{Matrix{ComplexF64}},Y_RPA::Matrix{Matrix{ComplexF64}})
    # Calculation parameters ...
    N_max = Params[4]
    N_2max = 2*N_max
    J_max = N_2max + 1
    Orthogon = Params[5]
    Output_File = Params[8]

    # Export name & path ...
    if Orthogon == true
        Output_Path = Output_File * "/ERPA/Amplitudes/HF_ERPA_Amplitudes_Ortho.dat"
    else
        Output_Path = Output_File * "/ERPA/Amplitudes/HF_ERPA_Amplitudes_Spur.dat"
    end

    println("\nPreparing export of ERPA amplitudes X & Y ...")


    open(Output_Path, "w") do Write_File
        println(Write_File, "E\t|X|^2\t\t|Y|^2")
        @inbounds for J in 0:J_max
            @inbounds for P in 1:2
                if P == 1
                    println(Write_File, "\nJ = " * string(J) * ",\tP = +")
                else
                    println(Write_File, "\nJ = " * string(J) * ",\tP = -")
                end
                N_ph = N_nu[J+1,P]
                if Orthogon == true
                    if (J == 1 && P == 2)
                        @inbounds for nu in 2:N_ph
                            x = @views norm(X_RPA[J+1,P][:,nu])^2
                            y = @views norm(Y_RPA[J+1,P][:,nu])^2
                            println(Write_File, string(round(real(E_RPA[J+1,P][nu]),digits=4)) * "\t" * string(round(x,digits=7)) * "\t" * string(round(y,digits=7)))
                        end
                    else
                        @inbounds for nu in 1:N_ph
                            x = @views norm(X_RPA[J+1,P][:,nu])^2
                            y = @views norm(Y_RPA[J+1,P][:,nu])^2
                            println(Write_File, string(round(real(E_RPA[J+1,P][nu]),digits=4)) * "\t" * string(round(x,digits=7)) * "\t" * string(round(y,digits=7)))
                        end
                    end
                else
                    @inbounds for nu in 1:N_ph
                        x = @views norm(X_RPA[J+1,P][:,nu])^2
                        y = @views norm(Y_RPA[J+1,P][:,nu])^2
                        println(Write_File, string(round(real(E_RPA[J+1,P][nu]),digits=4)) * "\t" * string(round(x,digits=7)) * "\t" * string(round(y,digits=7)))
                    end
                end
            end
        end
    end

    println("\nExported norms of ERPA amplitudes |X|^2 & |Y|^2 ...")
    return
end

function HF_ERPA_Y_Export(Params::Vector{Any},N_nu::Matrix{Int64},E_RPA::Matrix{Vector{ComplexF64}},Y_RPA::Matrix{Matrix{ComplexF64}})
    N_max = Params[4]
    N_2max = 2*N_max
    J_max = N_2max + 1
    Orthogon = Params[5]
    Output_File = Params[8]

    if Orthogon == true
        Output_Path = Output_File * "/ERPA/Amplitudes/HF_ERPA_Y_Amplitudes_Ortho.dat"
    else
        Output_Path = Output_File * "/ERPA/Amplitudes/HF_ERPA_Y_Amplitudes_Spur.dat"
    end

    println("\nPreparing export of RPA |Y|^2 amplitudes ...")

    N_ph = sum(N_nu)
    E_RPA_ord = Vector{Float64}(undef,N_ph)
    y_RPA = Vector{Float64}(undef,N_ph)

    ph_count = 0
    @inbounds for J in 0:J_max
        @inbounds for P in 1:2
            N_ph = N_nu[J+1,P]
            @inbounds for nu in 1:N_ph
                ph_count += 1
                E_RPA_ord[ph_count] = real(E_RPA[J+1,P][nu])
                ySum = 0.0
                @inbounds for ph in 1:N_ph
                    R = abs2(Y_RPA[J+1,P][ph,nu])
                    ySum += R
                end
                y_RPA[ph_count] = ySum
            end
        end
    end

    Sort_Ind = sortperm(E_RPA_ord)
    E_RPA_ord = E_RPA_ord[Sort_Ind]
    y_RPA = y_RPA[Sort_Ind]

    open(Output_Path, "w") do Write_File
        N_ph = sum(N_nu)
        @inbounds for ph in 1:N_ph
            println(Write_File, string(ph) * "\t" * string(round(y_RPA[ph],digits=6)))
        end
    end

    println("\nExported |Y|^2 ERPA amplitudes ...")

    return
end

function HF_ERPA_Transition_Export(Params::Vector{Any},N_nu::Matrix{Int64},E_RPA::Matrix{Vector{ComplexF64}},rB_RPA::ReducedTransition)
    # Read calculation parameters ...
    Orthogon = Params[5]
    Output_File = Params[8]

    println("\nPreparing export of ERPA transition intensities ...")

    # ERPA E0 export
    open(Output_File * "/ERPA/Transitions/E0/ERPA_E0.dat", "w") do Write_File
        J = 0
        P = 1
        N_ph = N_nu[J+1,P]
        println(Write_File, "E\t\t\tB_ph")
        @inbounds for nu in 1:N_ph
            println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E0.ph[nu],digits = 8)))
        end
        println(Write_File, "\nE\t\t\tB_is")
        @inbounds for nu in 1:N_ph
            println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E0.is[nu],digits = 8)))
        end
        println(Write_File, "\nE\t\t\tB_iv")
        @inbounds for nu in 1:N_ph
            println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E0.iv[nu],digits = 8)))
        end
    end

    if Orthogon == true

        # ERPA E1 export
        open(Output_File * "/ERPA/Transitions/E1/ERPA_E1_Ortho.dat", "w") do Write_File
            J = 1
            P = 2
            N_ph = N_nu[J+1,P]
            println(Write_File, "E\t\t\tB_ph")
            @inbounds for nu in 2:N_ph
                println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E1.ph[nu],digits = 8)))
            end
            println(Write_File, "\nE\t\t\tB_is")
            @inbounds for nu in 2:N_ph
                println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E1.is[nu],digits = 8)))
            end
            println(Write_File, "\nE\t\tB_iv")
            @inbounds for nu in 2:N_ph
                println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E1.iv[nu],digits = 8)))
            end
        end
    else
        # ERPA E1 export
        open(Output_File * "/ERPA/Transitions/E1/ERPA_E1_Spur.dat", "w") do Write_File
            J = 1
            P = 2
            N_ph = N_nu[J+1,P]
            println(Write_File, "E\t\t\tB_ph")
            @inbounds for nu in 2:N_ph
                println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E1.ph[nu],digits = 8)))
            end
            println(Write_File, "\nE\t\t\tB_is")
            @inbounds for nu in 2:N_ph
                println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E1.is[nu],digits = 8)))
            end
            println(Write_File, "\nE\t\t\tB_iv")
            @inbounds for nu in 2:N_ph
                println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E1.iv[nu],digits = 8)))
            end
        end
    end

    # ERPA E2 export
    open(Output_File * "/ERPA/Transitions/E2/ERPA_E2.dat", "w") do Write_File
        J = 2
        P = 1
        N_ph = N_nu[J+1,P]
        println(Write_File, "E\t\t\tB_ph")
        @inbounds for nu in 1:N_ph
            println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E2.ph[nu],digits = 8)))
        end
        println(Write_File, "\nE\t\t\tB_is")
        @inbounds for nu in 1:N_ph
            println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E2.is[nu],digits = 8)))
        end
        println(Write_File, "\nE\t\t\tB_iv")
        @inbounds for nu in 1:N_ph
            println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E2.iv[nu],digits = 8)))
        end
    end
    

    # ERPA E3 export
    open(Output_File * "/ERPA/Transitions/E3/ERPA_E3.dat", "w") do Write_File
        J = 3
        P = 2
        N_ph = N_nu[J+1,P]
        println(Write_File, "E\t\t\tB_ph")
        @inbounds for nu in 1:N_ph
            println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E3.ph[nu],digits = 8)))
        end
        println(Write_File, "\nE\t\t\tB_is")
        @inbounds for nu in 1:N_ph
            println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E3.is[nu],digits = 8)))
        end
        println(Write_File, "\nE\t\t\tB_iv")
        @inbounds for nu in 1:N_ph
            println(Write_File, string(round(E_RPA[J+1,P][nu], sigdigits=8)) * "\t" * string(round(rB_RPA.E3.iv[nu],digits = 8)))
        end
    end

    println("\nERPA transition intensities succesfully exported ...")

    return
end

function HF_ERPA_S0_Export(Params::Vector{Any},N_nu::Matrix{Int64},E_RPA::Matrix{Vector{ComplexF64}},rB_RPA::ReducedTransition)
    # Read calculation parameters ...
    Orthogon = Params[5]
    E_min = Params[6][1]
    E_max = Params[6][2]
    Delta = Params[6][3]
    Output_File = Params[8]

    println("\nPreparing export of ERPA S0 electric strength functions ...")

    # Initialize grid ...
    N_grid = 25000
    E_grid = range(E_min, stop = E_max, length = N_grid)

    E0_RPA_grid = zeros(Float64,N_grid)
    E1_RPA_grid = zeros(Float64,N_grid)
    E2_RPA_grid = zeros(Float64,N_grid)
    E3_RPA_grid = zeros(Float64,N_grid)
    E0is_RPA_grid = zeros(Float64,N_grid)
    E1is_RPA_grid = zeros(Float64,N_grid)
    E2is_RPA_grid = zeros(Float64,N_grid)
    E3is_RPA_grid = zeros(Float64,N_grid)
    E0iv_RPA_grid = zeros(Float64,N_grid)
    E1iv_RPA_grid = zeros(Float64,N_grid)
    E2iv_RPA_grid = zeros(Float64,N_grid)
    E3iv_RPA_grid = zeros(Float64,N_grid)

    @inbounds for (i, E) in enumerate(E_grid)
        physE0Sum_RPA = 0.0
        physE1Sum_RPA = 0.0
        physE2Sum_RPA = 0.0
        physE3Sum_RPA = 0.0
        isE0Sum_RPA = 0.0
        isE1Sum_RPA = 0.0
        isE2Sum_RPA = 0.0
        isE3Sum_RPA = 0.0
        ivE0Sum_RPA = 0.0
        ivE1Sum_RPA = 0.0
        ivE2Sum_RPA = 0.0
        ivE3Sum_RPA = 0.0

        # E0
        J = 0
        P = 1
        N_ph = N_nu[J+1,P]
        @inbounds for nu in 1:N_ph
            E_nu = real(E_RPA[J+1,P][nu])

            physME = rB_RPA.E0.ph[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)
            isME = rB_RPA.E0.is[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)
            ivME = rB_RPA.E0.iv[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)

            physE0Sum_RPA+= physME
            isE0Sum_RPA += isME
            ivE0Sum_RPA += ivME
        end

        # E1
        J = 1
        P = 2
        N_ph = N_nu[J+1,P]
        @inbounds for nu in 1:N_ph
            E_nu = real(E_RPA[J+1,P][nu])

            physME = rB_RPA.E1.ph[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)
            isME = rB_RPA.E1.is[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)
            ivME = rB_RPA.E1.iv[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)

            physE1Sum_RPA+= physME
            isE1Sum_RPA += isME
            ivE1Sum_RPA += ivME
        end

        # E2
        J = 2
        P = 1
        N_ph = N_nu[J+1,P]
        @inbounds for nu in 1:N_ph
            E_nu = real(E_RPA[J+1,P][nu])

            physME = rB_RPA.E2.ph[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)
            isME = rB_RPA.E2.is[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)
            ivME = rB_RPA.E2.iv[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)

            physE2Sum_RPA+= physME
            isE2Sum_RPA += isME
            ivE2Sum_RPA += ivME
        end

        # E3
        J = 3
        P = 2
        N_ph = N_nu[J+1,P]
        @inbounds for nu in 1:N_ph
            E_nu = real(E_RPA[J+1,P][nu])

            physME = rB_RPA.E3.ph[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)
            isME = rB_RPA.E3.is[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)
            ivME = rB_RPA.E3.iv[nu] * lorentzian(E_nu-E,Delta) / Float64(2*J + 1)

            physE3Sum_RPA+= physME
            isE3Sum_RPA += isME
            ivE3Sum_RPA += ivME
        end

        E0_RPA_grid[i] = physE0Sum_RPA
        E1_RPA_grid[i] = physE1Sum_RPA
        E2_RPA_grid[i] = physE2Sum_RPA
        E3_RPA_grid[i] = physE3Sum_RPA
        E0is_RPA_grid[i] = isE0Sum_RPA
        E1is_RPA_grid[i] = isE1Sum_RPA
        E2is_RPA_grid[i] = isE2Sum_RPA
        E3is_RPA_grid[i] = isE3Sum_RPA
        E0iv_RPA_grid[i] = ivE0Sum_RPA
        E1iv_RPA_grid[i] = ivE1Sum_RPA
        E2iv_RPA_grid[i] = ivE2Sum_RPA
        E3iv_RPA_grid[i] = ivE3Sum_RPA

    end

    println("\nExporting ERPA E0, E1, E2 & E3 stregth function S0 ...")

    open(Output_File * "/ERPA/Transitions/E0/ERPA_E0_S0.dat", "w") do Write_File
        @inbounds for (i, E) in enumerate(E_grid)
            Row = string(round(E,digits=6)) * "\t" * string(round(E0_RPA_grid[i],digits=6)) * "\t" *
                    string(round(E0is_RPA_grid[i],digits=6)) * "\t" * string(round(E0iv_RPA_grid[i],digits=6))
            println(Write_File, Row)
        end
    end

    if Orthogon == true
        open(Output_File * "/ERPA/Transitions/E1/ERPA_E1_S0_Ortho.dat", "w") do Write_File
            @inbounds for (i, E) in enumerate(E_grid)
                Row = string(round(E,digits=6)) * "\t" * string(round(E1_RPA_grid[i],digits=6)) * "\t" *
                        string(round(E1is_RPA_grid[i],digits=6)) * "\t" * string(round(E1iv_RPA_grid[i],digits=6))
                println(Write_File, Row)
            end
        end
    else
        open(Output_File * "/ERPA/Transitions/E1/ERPA_E1_S0_Spur.dat", "w") do Write_File
            @inbounds for (i, E) in enumerate(E_grid)
                Row = string(round(E,digits=6)) * "\t" * string(round(E1_RPA_grid[i],digits=6)) * "\t" *
                        string(round(E1is_RPA_grid[i],digits=6)) * "\t" * string(round(E1iv_RPA_grid[i],digits=6))
                println(Write_File, Row)
            end
        end
    end

    open(Output_File * "/ERPA/Transitions/E2/ERPA_E2_S0.dat", "w") do Write_File
        @inbounds for (i, E) in enumerate(E_grid)
            Row = string(round(E,digits=6)) * "\t" * string(round(E2_RPA_grid[i],digits=6)) * "\t" *
                    string(round(E2is_RPA_grid[i],digits=6)) * "\t" * string(round(E2iv_RPA_grid[i],digits=6))
            println(Write_File, Row)
        end
    end

    open(Output_File * "/ERPA/Transitions/E3/ERPA_E3_S0.dat", "w") do Write_File
        @inbounds for (i, E) in enumerate(E_grid)
            Row = string(round(E,digits=6)) * "\t" * string(round(E3_RPA_grid[i],digits=6)) * "\t" *
                    string(round(E3is_RPA_grid[i],digits=6)) * "\t" * string(round(E3iv_RPA_grid[i],digits=6))
            println(Write_File, Row)
        end
    end

    println("\nERPA S0 strength functions of E0, E1, E2 & E3 transitions exported ...")

    return
end

function HF_ERPA_Sigma_Export(Params::Vector{Any},N_nu::Matrix{Int64},E_RPA::Matrix{Vector{ComplexF64}},rB_RPA::ReducedTransition)
    # Read calculation parameters ...
    Orthogon = Params[5]
    E_min = Params[7][1]
    E_max = Params[7][2]
    Delta = Params[7][3]
    Output_File = Params[8]

    # Physical constants ...
    alpha = 1.0 / 137.035999177
    HbarC = 197.326980

    println("\nPreparing export of RPA & TDA photoabsorbtion cross-sections ...")
    
    # Preallocate grid ...
    N_grid = 25000
    E_grid = range(E_min, stop = E_max, length = N_grid)
    SigmaE1RPA_grid = zeros(Float64,N_grid)
    SigmaE2RPA_grid = zeros(Float64,N_grid)
    SigmaE3RPA_grid = zeros(Float64,N_grid)


    @inbounds for (i, E) in enumerate(E_grid)
        SigmaE1RPASum = 0.0
        SigmaE2RPASum = 0.0
        SigmaE3RPASum = 0.0

        # E1
        # Based on formula by Kvasil, eq. (7.388) p. 484 in mega lecture notes ... https://ipnp.cz/~kvasil/valya/NS+NR.pdf
        J = 1
        P = 2
        N_ph = N_nu[J+1,P]
        if Orthogon == true
            @inbounds for nu in 1:N_ph
                E_nu = real(E_RPA[J+1,P][nu])
                Amp = 16.0 * pi^3 * alpha / 9.0 * E_nu * lorentzian(E_nu-E,Delta)
                ME = rB_RPA.E1.ph[nu] * Amp
                SigmaE1RPASum += ME
            end
        else
            @inbounds for nu in 1:N_ph
                E_nu = real(E_RPA[J+1,P][nu])
                Amp = 16.0 * pi^3 * alpha / 9.0 * E_nu * lorentzian(E_nu-E,Delta)
                ME = rB_RPA.E1.iv[nu] * Amp
                SigmaE1RPASum += ME
            end
        end

        # E2
        J = 2
        P = 1
        N_ph = N_nu[J+1,P]
        @inbounds for nu in 1:N_ph
            E_nu = real(E_RPA[J+1,P][nu])
            Amp = 4.0 * pi^3 * alpha / (75.0 * HbarC^2) * E_nu^3 * lorentzian(E_nu-E,Delta)
            ME = rB_RPA.E2.ph[nu] * Amp
            SigmaE2RPASum += ME
        end

        # E3
        J = 3
        P = 2
        N_ph = N_nu[J+1,P]

        @inbounds for nu in 1:N_ph
            E_nu = real(E_RPA[J+1,P][nu])
            Amp = 16.0 * pi^3 * alpha / (11025.0 * HbarC^4) * E_nu^5 * lorentzian(E_nu-E,Delta)
            ME = rB_RPA.E3.ph[nu] * Amp
            SigmaE3RPASum += ME
        end

        # In milibarn units ... 1 b = 10^2 fm^2 ...
        SigmaE1RPA_grid[i] = SigmaE1RPASum * 10.0
        SigmaE2RPA_grid[i] = SigmaE2RPASum * 10.0
        SigmaE3RPA_grid[i] = SigmaE3RPASum * 10.0

    end
    if Orthogon == true
        open(Output_File * "/ERPA/Transitions/E1/ERPA_Sigma_E1_Ortho.dat", "w") do Write_File
            @inbounds for (i, E) in enumerate(E_grid)
                Row = string(round(E,digits=6)) * "\t" * string(round(SigmaE1RPA_grid[i],digits=6))
                println(Write_File, Row)
            end
        end
    else
        open(Output_File * "/ERPA/Transitions/E1/ERPA_Sigma_E1_Spur.dat", "w") do Write_File
            @inbounds for (i, E) in enumerate(E_grid)
                Row = string(round(E,digits=6)) * "\t" * string(round(SigmaE1RPA_grid[i],digits=6))
                println(Write_File, Row)
            end
        end
    end

    open(Output_File * "/ERPA/Transitions/E2/ERPA_Sigma_E2.dat", "w") do Write_File
        @inbounds for (i, E) in enumerate(E_grid)
            Row = string(round(E,digits=6)) * "\t" * string(round(SigmaE2RPA_grid[i],digits=6))
            println(Write_File, Row)
        end
    end

    open(Output_File * "/ERPA/Transitions/E3/ERPA_Sigma_E3.dat", "w") do Write_File
        @inbounds for (i, E) in enumerate(E_grid)
            Row = string(round(E,digits=6)) * "\t" * string(round(SigmaE3RPA_grid[i],digits=6))
            println(Write_File, Row)
        end
    end

    println("\nERPA photoabsorbtion cross-sections export done ...")

    return
end

function HF_ERPA_Phonon_Space_Export(Params::Vector{Any},N_nu::Matrix{Int64})
    # Read parameters ...
    N_max = Params[4]
    N_2max = 2*N_max
    J_max = N_2max + 1
    Output_File = Params[8]

    println("\nPreparing export of dimensions of ERPA phonon subspaces ...")

    # Output file name & path ...
    Output_Path = Output_File * "/ERPA/HF_ERPA_Phonon_Subspace_Size.dat"

    # Export of 1-phonon subspace dimensions ...
    open(Output_Path, "w") do Write_File
        @inbounds for J in 0:J_max
            Row = string(string(J) * "\t" * string(N_nu[J+1,1] + N_nu[J+1,2]))
            println(Write_File, Row)
        end
        println(Write_File, "\nSubspace\tP = +")
        @inbounds for J in 0:J_max
            Row = string(string(J) * "\t" *string(N_nu[J+1,1]))
            println(Write_File, Row)
        end
        println(Write_File, "\nSubspace\tP = -")
        @inbounds for J in 0:J_max
            Row = string(string(J) * "\t" *string(N_nu[J+1,2]))
            println(Write_File, Row)
        end
    end

    println("\nDimensions of ERPA phonon subspaces exported ...")

    return
end

function HF_ERPA_Y_Sum_Export(Params::Vector{Any},N_nu::Matrix{Int64},Y_RPA::Matrix{Matrix{ComplexF64}})
    # Read parameters ...
    N_max = Params[4]
    N_2max = 2*N_max
    J_max = N_2max + 1
    Orthogon = Params[5]
    Output_File = Params[8]

    println("\nPreparing export of |Y|^2 amplitudes sum over J subspaces ...")

    if Orthogon == true
        Output_Path = Output_File * "/ERPA/Amplitudes/HF_ERPA_Y_Sum_Ortho.dat"
    else
        Output_Path = Output_File * "/ERPA/Amplitudes/HF_ERPA_Y_Sum_Spur.dat"
    end

    YSum = Vector{Float64}(undef,J_max+1)
    @inbounds for J in 0:J_max
        ySum = 0.0
        @inbounds for P in 1:2
            N_ph = N_nu[J+1,P]
            @inbounds for nu in 1:N_ph
                @inbounds for ph in 1:N_ph
                    ME = abs2(Y_RPA[J+1,P][ph,nu])
                    ySum += ME
                end
            end
        end
        YSum[J+1] = ySum
    end

    # Export of sum of |Y|^2 RPA amplitudes ...
    open(Output_Path, "w") do Write_File
        @inbounds for J in 0:J_max
            Row = string(string(J) * "\t" * string(round(YSum[J+1],sigdigits = 7)))
            println(Write_File, Row)
        end
    end

    println("\nRunning sum of |Y|^2 amplitudes over J subspaces exported ...")

    return
end