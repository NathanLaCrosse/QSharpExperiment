namespace GreaterThan {
    import Std.Diagnostics.DumpMachine;
    import Microsoft.Quantum.Convert.IntAsBoolArray;
    open Microsoft.Quantum.Arrays;
    operation Main() : Result {
        //let ar = [3, 1];

        //use ancillia = Qubit();
        use val1 = Qubit[2];
        use val2 = Qubit[2];

        // set the values
        //X(val1[0]);
        //X(val1[1]);

        //X(val2[0]);
        //X(val2[1]);

        ApplyHAll(val1);
        ApplyHAll(val2);

        // // computer greater than part
        // use greater = Qubit();
        // X(val2[0]);
        // CCNOT(val1[0], val2[0], greater);
        // X(val2[0]);

        // // compute equal part
        // use equal = Qubit();
        // X(equal);

        // CNOT(val1[0],val2[0]);
        // X(val2[0]);
        // //CNOT(val2[0], equal[0]);

        // X(val1[1]);
        // CCCNOT(val1[1], val2[0], val2[1], equal, ancillia);

        //CCNOT(equal[0], equal[1], equal[2]);

        // or both greater and equal to get >=
        use result = Qubit();
        
        // this turns result into a phase inversion qubit
        //X(result);
        //H(result);

        // X(result);

        // X(greater);
        // X(equal);
        // CCNOT(greater, equal, result);

        GreaterThan(val1, val2, result);

        DumpMachine();

        let res = M(result);

        ResetAll(val1);
        ResetAll(val2);
        // Reset(greater);
        // Reset(equal);
        Reset(result);
        // Reset(ancillia);
        return res;
    }

    operation GreaterThan(val1 : Qubit[], val2 : Qubit[], result : Qubit) : Unit {
        // determine if val1 is trivially greater - val1's leftmost digit greater than val2's
        use greater = Qubit();
        X(val2[0]);
        CCNOT(val1[0], val2[0], greater);
        X(val2[0]);

        // if val1 and val2 share the leftmost digit, we know compare their second digits with NOT(val[1] < val[2])
        use equal = Qubit[2];
        use equalResult = Qubit();
        X(equal[0]);
        X(equal[1]);

        // check and save parity
        CNOT(val1[0], val2[0]);
        CNOT(val2[0], equal[0]);

        // calc >= by doing NOT(<)
        X(val1[1]);
        CCNOT(val1[1], val2[1], equal[1]);

        // and together both parts of the >= calculation
        CCNOT(equal[0], equal[1], equalResult);

        // calc the result and apply it to result - OR gate
        X(result);
        X(greater);
        X(equalResult);

        CCNOT(greater, equalResult, result);

        // now we have to undo everything to free extra qubits
        X(greater);
        X(equalResult);

        CCNOT(equal[0], equal[1], equalResult);

        CCNOT(val1[1], val2[1], equal[1]);
        X(val1[1]);

        CNOT(val2[0], equal[0]);
        CNOT(val1[0], val2[0]);

        X(equal[0]);
        X(equal[1]);

        X(val2[0]);
        CCNOT(val1[0], val2[0], greater);
        X(val2[0]);

        Reset(greater);
        ResetAll(equal);
        Reset(equalResult);
    }

    // operation CCCNOT(control : Qubit[], target : Qubit) : Unit {
    //     (Controlled X)(control, target);
    // }
    // implementation of CCCNOT with the ancillia qubit already provided so the ancillia can be used multiple time
    operation CCCNOT(control1 : Qubit, control2 : Qubit, control3 : Qubit, target : Qubit, ancillia : Qubit) : Unit{
        CCNOT(control1, control2, ancillia);
        CCNOT(control3, ancillia, target);
        CCNOT(control1, control2, ancillia); // return ancillia back to |0> 
    }

    operation ApplyHAll(qubits : Qubit[]) : Unit {
        for i in IndexRange(qubits) {
            H(qubits[i]);
        }
    }
}