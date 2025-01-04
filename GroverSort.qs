// Goal: Sort an array by converting the sort problem into a search problem
// we are searching for the ordering of elements such that they are in sorted order

namespace GroverSort {
    import Std.Arrays.IndexRange;
    import Std.Convert.ResultArrayAsInt;
    import Std.Convert.BoolArrayAsInt;
    import Std.Diagnostics.DumpMachine;
    import Microsoft.Quantum.Convert.IntAsBoolArray;
    open Microsoft.Quantum.Arrays;

    @EntryPoint()
    operation Main() : Int[] {
        // NOTE - array values must be 0-3 inclusive
        let ar = [1, 3, 0];

        use ancillia = Qubit[4];

        use order1 = Qubit[2];
        use order2 = Qubit[2];
        use order3 = Qubit[2];

        // define extra qubits need to find the sorted array
        use val1 = Qubit[2];
        use val2 = Qubit[2];
        use val3 = Qubit[2];

        use greaterRes = Qubit[2];

        use phaseInverter = Qubit();
        X(phaseInverter);
        H(phaseInverter);

        let ops = 1; // Note - currently does not work if ops > 1
        EnterQuantumOrder([order1, order2, order3], ancillia[0]);

        // perform amplification of desired state ops times
        for i in 0..(ops-1) {
            InvertPhaseOfSortedArray(ar, ancillia, greaterRes, [order1, order2, order3], [val1, val2, val3], phaseInverter);
            ApplyDiffusionOperator(ancillia, [order1, order2, order3], phaseInverter);
        }

        DumpMachine();

        let answer = [[M(order1[1]), M(order1[0])],[M(order2[1]), M(order2[0])],[M(order3[1]), M(order3[0])]];
        let answerIndices = [ResultArrayAsInt(answer[0]), ResultArrayAsInt(answer[1]), ResultArrayAsInt(answer[2])];

        ResetAll(ancillia);
        ResetAll(order1);
        ResetAll(order2);
        ResetAll(order3);
        ResetAll(val1);
        ResetAll(val2);
        ResetAll(val3);
        ResetAll(greaterRes);
        Reset(phaseInverter);

        mutable output = [];

        for i in IndexRange(answerIndices) {
            if (answerIndices[i] == 3) {
                set output = output + [-1];
            }else {
                set output = output + [ar[answerIndices[i]]]
            }
        }

        return output;
    }

    operation EnterQuantumOrder(qOrdering : Qubit[][], ancillia : Qubit) : Unit {
        // rotate the first qubit into sqrt(2)/sqrt(3)|0> + 1/sqrt(3)|1>
        Ry(2.0*0.61547970867, qOrdering[0][0]);

        // apply a hadamard when the top qubit is in |0>, requiring an X gate
        X(qOrdering[0][0]);
        ControlledH(qOrdering[0][0],qOrdering[0][1]) ;
        X(qOrdering[0][0]);   

        // for the second index:
        H(qOrdering[1][1]);
        X(qOrdering[0][0]);
        CCH(qOrdering[0][0], qOrdering[0][1], qOrdering[1][0]);
        CCH(qOrdering[0][0], qOrdering[0][1], qOrdering[1][1]);
        X(qOrdering[0][0]);

        ApplyXAll(qOrdering[0]);
        CCNOT(qOrdering[0][0], qOrdering[0][1], qOrdering[1][0]);
        CCCNOT(qOrdering[0][0], qOrdering[0][1], qOrdering[1][1], qOrdering[1][0], ancillia);
        ApplyXAll(qOrdering[0]);

        // for the third index:
        CNOT(qOrdering[0][0], qOrdering[1][0]);
        X(qOrdering[1][0]);
        CNOT(qOrdering[1][0], qOrdering[2][0]);
        X(qOrdering[1][0]);
        CNOT(qOrdering[0][0], qOrdering[1][0]);

        CNOT(qOrdering[0][1], qOrdering[1][1]);
        X(qOrdering[1][1]);
        CNOT(qOrdering[1][1], qOrdering[2][1]);
        X(qOrdering[1][1]);
        CNOT(qOrdering[0][1], qOrdering[1][1]);
    }
    operation ExitQuantumOrder(qOrdering : Qubit[][], ancillia : Qubit) : Unit {
        CNOT(qOrdering[0][1], qOrdering[1][1]);
        X(qOrdering[1][1]);
        CNOT(qOrdering[1][1], qOrdering[2][1]);
        X(qOrdering[1][1]);
        CNOT(qOrdering[0][1], qOrdering[1][1]);

        CNOT(qOrdering[0][0], qOrdering[1][0]);
        X(qOrdering[1][0]);
        CNOT(qOrdering[1][0], qOrdering[2][0]);
        X(qOrdering[1][0]);
        CNOT(qOrdering[0][0], qOrdering[1][0]);

        ApplyXAll(qOrdering[0]);
        CCCNOT(qOrdering[0][0], qOrdering[0][1], qOrdering[1][1], qOrdering[1][0], ancillia);
        CCNOT(qOrdering[0][0], qOrdering[0][1], qOrdering[1][0]);
        X(qOrdering[0][0]);
        H(qOrdering[1][1]);

        X(qOrdering[0][0]);
        ControlledH(qOrdering[0][0],qOrdering[0][1]) ;
        X(qOrdering[0][0]);   

        Ry(2.0*0.61547970867, qOrdering[0][0]);
    }

    // perform a Uf phase inversion then apply the adjoint Uf
    // after phase is inverted and extra work is done, the desired value is amplified with the diffusion operator
    // ancillia contains 4 qubits, greaterThanAncillia contains 2 qubits
    operation InvertPhaseOfSortedArray(ar : Int[], ancillia : Qubit[], greaterThanAncillia : Qubit[], ordering : Qubit[][], qValues : Qubit[][], phaseInverter : Qubit) : Unit {
        // load array values
        for i in IndexRange(ordering) {
            ApplyCNOTValuesToValQubits(ar, ordering[i], qValues[i]);
        }

        // look for the state that contains a sorted array - invert that one's phase
        GreaterThan(qValues[1], qValues[0], greaterThanAncillia[0], ancillia);
        GreaterThan(qValues[2], qValues[1], greaterThanAncillia[1], ancillia);
        CCNOT(greaterThanAncillia[0], greaterThanAncillia[1], phaseInverter);

        // we now need to undo past work for the diffusion operator
        GreaterThan(qValues[2], qValues[1], greaterThanAncillia[1], ancillia);
        GreaterThan(qValues[1], qValues[0], greaterThanAncillia[0], ancillia);
        for i in IndexRange(ordering) {
            ApplyCNOTValuesToValQubits(ar, ordering[i], qValues[i]);
        }
    }

    // ancillia is 4 qubits
    operation ApplyDiffusionOperator(ancillia : Qubit[], ordering : Qubit[][], phaseInverter : Qubit) : Unit {
        // diffusion operator time :)
        for i in IndexRange(ordering) {
            ApplyHAll(ordering[i]);
            ApplyXAll(ordering[i]);
        }
        C6NOT(ancillia, ordering[0], ordering[1], ordering[2], phaseInverter);
        for i in IndexRange(ordering) {
            ApplyXAll(ordering[i]);
            ApplyHAll(ordering[i]);
        }
    }

    // note that source is essentially an order qubit which tells
    operation ApplyCNOTValuesToValQubits(values : Int[], source : Qubit[], valQs : Qubit[]) : Unit {
        
        for i in IndexRange(values) {
            let indexAr = IntAsBoolArray(i, 2);
            for k in IndexRange(source) {
                if(indexAr[k] == false) {
                    X(source[1-k]);
                }
            }

            let boolAr = IntAsBoolArray(values[i], 2);
            for k in IndexRange(boolAr) {
                if(boolAr[k]) {
                    CCNOT(source[0], source[1], valQs[1-k]);
                }
            }

            // undo x modification to source
            for k in IndexRange(source) {
                if(indexAr[k] == false) {
                    X(source[1-k]);
                }
            }
        }


    }

    // calcuates if val1 >= val2 and applies the answer as a CNOT gate to result
    // val1, val2 contain 2 qubits
    // 4 ancillia qubits are needed
    // note that variable names in the previous version were overridden with ancillia[i]
    operation GreaterThan(val1 : Qubit[], val2 : Qubit[], result : Qubit, ancillia : Qubit[]) : Unit {
        // determine if val1 is trivially ancillia[0] - val1's leftmost digit ancillia[0] than val2's
        X(val2[0]);
        CCNOT(val1[0], val2[0], ancillia[0]);
        X(val2[0]);

        // if val1 and val2 share the leftmost digit, we know compare their second digits with NOT(val[1] < val[2])
        X(ancillia[1]);
        X(ancillia[2]);

        // check and save parity
        CNOT(val1[0], val2[0]);
        CNOT(val2[0], ancillia[1]);

        // calc >= by doing NOT(<)
        X(val1[1]);
        CCNOT(val1[1], val2[1], ancillia[2]);

        // and together both parts of the >= calculation
        CCNOT(ancillia[1], ancillia[2], ancillia[3]);

        // calc the result and apply it to result - OR gate
        X(result);
        X(ancillia[0]);
        X(ancillia[3]);

        CCNOT(ancillia[0], ancillia[3], result);

        // now we have to undo everything to free extra qubits
        X(ancillia[0]);
        X(ancillia[3]);

        CCNOT(ancillia[1], ancillia[2], ancillia[3]);

        CCNOT(val1[1], val2[1], ancillia[2]);
        X(val1[1]);

        CNOT(val2[0], ancillia[1]);
        CNOT(val1[0], val2[0]);

        X(ancillia[1]);
        X(ancillia[2]);

        X(val2[0]);
        CCNOT(val1[0], val2[0], ancillia[0]);
        X(val2[0]);
    }

    // implementation of CCCNOT with the ancillia qubit already provided so the ancillia can be used multiple time
    operation CCCNOT(control1 : Qubit, control2 : Qubit, control3 : Qubit, target : Qubit, ancillia : Qubit) : Unit {
        CCNOT(control1, control2, ancillia);
        CCNOT(control3, ancillia, target);
        CCNOT(control1, control2, ancillia); // return ancillia back
    }

    operation ApplyHAll(qubits : Qubit[]) : Unit {
        for i in IndexRange(qubits) {
            H(qubits[i]);
        }
    }
    operation ApplyXAll(qubits : Qubit[]) : Unit {
        for i in IndexRange(qubits) {
            X(qubits[i]);
        }
    }

    operation ControlledH(control : Qubit, target : Qubit) : Unit {
        (Controlled H)([control], target);
    }

    operation CCH(control1 : Qubit, control2 : Qubit, target : Qubit) : Unit {
        (Controlled (Controlled H))([control1], ([control2], target));
    }

    // note that ancillia contains 4 qubits
    operation C6NOT(ancillia : Qubit[], control1 : Qubit[], control2 : Qubit[], control3 : Qubit[], target : Qubit) : Unit {
        CCNOT(control1[0], control1[1], ancillia[0]);
        CCNOT(control2[0], control2[1], ancillia[1]);
        CCNOT(control3[0], control3[1], ancillia[2]);

        CCCNOT(ancillia[0], ancillia[1], ancillia[2], target, ancillia[3]);

        CCNOT(control3[0], control3[1], ancillia[2]);
        CCNOT(control2[0], control2[1], ancillia[1]);
        CCNOT(control1[0], control1[1], ancillia[0]);
    }
}
