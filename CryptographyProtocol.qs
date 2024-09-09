// a simple example to try out a quantum cryptography protocol

namespace CrytographyProtocol {
    @EntryPoint()
    operation Main() : Unit {
        use qubit = Qubit();

        let key = EstablishKey(20);
        Message($"The shared key is: {key}");

        Reset(qubit);
    }

    // attempts - how many qubits to send
    // creates a key based off of times when alice and bob use the same basis
    operation EstablishKey(attempts : Int) : String {
        mutable str = "";

        for i in 0..(attempts-1) {
            let transmission = TransmitQubit();

            // we have successfully teleported information
            if(transmission[0] == One) {
                mutable res = "0";
                if(transmission[1] == One) {
                    set res = "1";
                }

                set str = str + " " + res;
            }
        }

        return str;
    }

    // send a qubit from alice to bob and returns the transmission's result with a bit signifying if it was successful
    operation TransmitQubit() : Result[] {
        use qubit = Qubit();

        if(Rand() == One) {
            X(qubit);
        }

        let aliceMat = ConvertToRandomBasis(qubit);
        let bobMat = ConvertToRandomBasis(qubit);

        let bobMeasure = M(qubit);
        Reset(qubit);

        if(aliceMat == bobMat) {
            return [One, bobMeasure];
        }else {
            return [Zero, bobMeasure];
        }
    }

    // converts a qubit to a random basis (either standard or hadamard)
    // returns 0 if it was the standard basis (does nothing)
    // returns 1 if it was the hadamard basis (applies hadamard gate)
    operation ConvertToRandomBasis(qubit : Qubit) : Result {
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
