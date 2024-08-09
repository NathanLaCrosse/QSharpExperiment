// a simple example to try out a quantum cryptography protocol

namespace CrytographyProtocol {
    @EntryPoint()
    operation Main() : Unit {
        use qubit = Qubit();

        TransmitQubit();

        Reset(qubit);
    }

    // send a qubit from alice to bob and print if the basis used match 
    operation TransmitQubit() : Unit {
        use qubit = Qubit();

        let aliceVal = Rand();
        if(aliceVal == One) {
            X(qubit);
        }

        let aliceMat = ConvertToRandomBasis(qubit);
        let bobMat = ConvertToRandomBasis(qubit);

        if (aliceMat == bobMat) {
            Message("Alice and Bob's Bases match!")
        }else {
            Message("Alice and Bob did not choose the same basis...")
        }

        let bobMeasure = M(qubit);

        Message($"Alice sent: {aliceVal}");
        Message($"Bob observed: {bobMeasure}");

        Reset(qubit);
    }

    // converts a qubit to a random basis (either standard or hadamard)
    // returns 0 if it was the standard basis (does nothing)
    // returns 1 if it was the hadamard basis (applies hadamard gate)
    operation ConvertToRandomBasis(qubit : Qubit) : Result {
        let result = Rand();
        if(Rand() == One) {
            H(qubit);
            return One;
        }
        return Zero;
    }

    // Generate random number through observation
    operation Rand() : Result {
        use qubit = Qubit();

        H(qubit);

        let result = M(qubit);
        Reset(qubit);

        return result;
    }
}