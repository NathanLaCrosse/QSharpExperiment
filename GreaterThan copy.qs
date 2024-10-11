namespace GreaterThan {
    import Microsoft.Quantum.Convert.IntAsBoolArray;
    operation Main() : Result {
        //let ar = [3, 1];

        use ancillia = Qubit();
        use val1 = Qubit[2];
        use val2 = Qubit[2];

        // set the values
        //X(val1[0]);
        X(val1[1]);

        X(val2[0]);
        X(val2[1]);

        // computer greater than part
        use greater = Qubit();
        X(val2[0]);
        CCNOT(val1[0], val2[0], greater);
        X(val2[0]);

        // compute equal part
        use equal = Qubit[3];
        X(equal[0]);
        X(equal[1]);

        CNOT(val1[0],val2[0]);
        CNOT(val2[0], equal[0]);
        CNOT(val1[0],val2[0]);

        X(val1[1]);
        CCCNOT(val1[1], val2[1], equal[0], equal[1], ancillia);
        X(val1[1]);

        CCNOT(equal[0], equal[1], equal[2]);

        // or both greater and equal to get >=
        use result = Qubit();
        X(result);

        X(greater);
        X(equal[2]);
        CCNOT(greater, equal[2], result);
        X(equal[2]);
        X(greater);

        let res = M(result);

        ResetAll(val1);
        ResetAll(val2);
        Reset(greater);
        ResetAll(equal);
        Reset(result);
        Reset(ancillia);
        return res;
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
}