namespace StillLife3x3 {
    import Std.Convert.DoubleAsStringWithPrecision;
    import Std.Diagnostics.DumpMachine;
    import Std.Arrays.IndexRange;

    @EntryPoint()
    operation Main() : Result[] {
        use grid = Qubit[9]; // 3x3 grid in conway's game of life
        use tempWork = Qubit[3]; // ancillia qubits used as a neighbor counter
        use nextGrid = Qubit[9]; 
        use phaseInverter = Qubit();

        use ancillia = Qubit[2];

        // set up phase inverter for later
        X(phaseInverter);
        H(phaseInverter);

        // enter superposition of all possible grid states
        ApplyHAll(grid);

        let neighborDifferences = [-7,-6,-5,-1,1,5,6,7];

        for i in 0..8 {
            let mgd = i % 3 + 2 * 3 * (i/3);

            for dif in neighborDifferences {
                if(ValidDex(mgd + dif)) {
                    // we have found a proper neighbor, let's tick up the neighbor counter                    
                    let properDex = MGDToIndex(mgd + dif);

                    IncrementNeighborCounter(grid[properDex], tempWork, ancillia[0]);
                }
            }

            // use the neighbor count to determine the next state of cell i
            DetermineNextState(grid[i], tempWork, nextGrid[i], ancillia);

            // clear our work done in tempWork
            for dif in neighborDifferences {
                if(ValidDex(mgd + dif)) {
                    // we have found a proper neighbor, let's tick up the neighbor counter                    
                    let properDex = MGDToIndex(mgd + dif);

                    DecrementNeighborCounter(grid[properDex], tempWork, ancillia[0]);
                }
            }
        }

        // now that the next grid has been calculated, compare the grid with the next grid and if they're equal
        for i in 0..8 {
            CNOT(grid[i], nextGrid[i]);
        }
        // if nextGrid is all 0s, the states are equal. note that the zero state is equal, so we'll mark down if at least one cell is alive
        X(ancillia[0]);
        ApplyXAll(grid);
        (Controlled X)(grid, ancillia[0]);
        // phase invert if the grid is alive and equal to next grid
        ApplyXAll(nextGrid);
        (Controlled (Controlled X))([ancillia[0]], (nextGrid, phaseInverter));
        ApplyXAll(nextGrid);
        // now that we have inverted phase, we need to undo all other work. since this is trivial, i'll put it all in the following method.
        UndoPreviousPhaseInversionWork(grid, tempWork, nextGrid, phaseInverter, ancillia, neighborDifferences);
        
        // Now apply the diffusion operator to increase probabilities of still lives
        ApplyHAll(grid);
        ApplyXAll(grid);
        (Controlled X)(grid, phaseInverter);
        ApplyXAll(grid);
        ApplyHAll(grid);
        
        let results = [M(grid[0]),M(grid[1]),M(grid[2]),M(grid[3]),M(grid[4]),M(grid[5]),M(grid[6]),M(grid[7]),M(grid[8])];

        DumpMachine();

        ResetAll(grid);
        ResetAll(tempWork);
        Reset(phaseInverter);
        ResetAll(ancillia);
        ResetAll(nextGrid);

        return results;
    }

    operation UndoPreviousPhaseInversionWork(grid : Qubit[], tempWork : Qubit[], nextGrid : Qubit[], phaseInverter : Qubit, ancillia : Qubit[], neighborDifferences : Int[]) : Unit{
        (Controlled X)(grid, ancillia[0]);
        ApplyXAll(grid);
        X(ancillia[0]);

        for i in 0..8 {
            CNOT(grid[i], nextGrid[i]);
        }

        for i in 0..8 {
            let mgd = i % 3 + 2 * 3 * (i/3);

            for dif in neighborDifferences {
                if(ValidDex(mgd + dif)) {
                    // we have found a proper neighbor, let's tick up the neighbor counter                    
                    let properDex = MGDToIndex(mgd + dif);

                    IncrementNeighborCounter(grid[properDex], tempWork, ancillia[0]);
                }
            }

            // use the neighbor count to determine the next state of cell i
            DetermineNextState(grid[i], tempWork, nextGrid[i], ancillia);

            // clear our work done in tempWork
            for dif in neighborDifferences {
                if(ValidDex(mgd + dif)) {
                    // we have found a proper neighbor, let's tick up the neighbor counter                    
                    let properDex = MGDToIndex(mgd + dif);

                    DecrementNeighborCounter(grid[properDex], tempWork, ancillia[0]);
                }
            }
        }
    }

    // needs two qubits of ancillia
    operation DetermineNextState(cell : Qubit, neighborCount : Qubit[], nextCell : Qubit, ancillia : Qubit[]) : Unit {
        // if a cell is alive with 2 neighbors, it stays alive
        X(neighborCount[0]);
        CCNOT(cell, neighborCount[0],ancillia[0]);
        X(neighborCount[2]);
        CCNOT(neighborCount[1], neighborCount[2], ancillia[1]);
        CCNOT(ancillia[0],ancillia[1], nextCell);
        CCNOT(neighborCount[1], neighborCount[2], ancillia[1]);
        X(neighborCount[2]);
        CCNOT(cell, neighborCount[0],ancillia[0]);
        // X(neighborCount[0]);

        // if a cell (dead or alive) has 3 neighbors, it will be alive next step
        CCNOT(neighborCount[0], neighborCount[1], ancillia[0]);
        CCNOT(neighborCount[2], ancillia[0], nextCell);
        CCNOT(neighborCount[0], neighborCount[1], ancillia[0]);
        X(neighborCount[0]);
    }
    
    // notes on inputs: counter is a 3-qubit integer, ancillia is a qubit used for control gates
    // additional side note - this operation will not take longer on a 4x4 grid, as only 3 bits are needed to store total number of neighbors (cannot exceed 8)
    // note - changed from 4 qubits to 3 qubits as overflow actually causes 0 problems 
    operation IncrementNeighborCounter(control : Qubit, counter : Qubit[], ancillia : Qubit) : Unit {
        // // assign top qubit
        // CCNOT(control, counter[3], ancillia[0]);
        // CCNOT(counter[1], counter[2], ancillia[1]);
        // CCNOT(ancillia[0], ancillia[1], counter[0]);
        // CCNOT(counter[1], counter[2], ancillia[1]); // clear data on ancillia[1]

        // // assign second-down qubit
        // CCNOT(ancillia[0], counter[2], counter[1]);
        // CCNOT(control, counter[3], ancillia[0]); // clear data on ancillia[0] - no ancillia needed past this point

        // // last two qubits are easier (2 or less controls needed)
        // CCNOT(control, counter[3], counter[2]);
        // CNOT(control, counter[3]);

        CCNOT(control, counter[2], ancillia);

        CCNOT(counter[1], ancillia, counter[0]);
        CNOT(ancillia, counter[1]);

        CCNOT(control, counter[2], ancillia);

        CNOT(control, counter[2]);
    }
    // reverses the process of incrementing a counter
    operation DecrementNeighborCounter(control : Qubit, counter : Qubit[], ancillia : Qubit) : Unit {
        CNOT(control, counter[2]);

        CCNOT(control, counter[2], ancillia);

        CNOT(ancillia, counter[1]);
        CCNOT(counter[1], ancillia, counter[0]);

        CCNOT(control, counter[2], ancillia);
    }

    // mgd stands for modified grid index, process explained in notes
    // change index values of grid to find neighbors more generally
    function ValidDex(mgd : Int) : Bool {
        return (mgd < 3 and mgd > -1) or (mgd < 9 and mgd > 5) or (mgd < 15 and mgd > 11);
    }
    function MGDToIndex(mgd : Int) : Int {
        if (mgd < 4) {
            return mgd;
        }elif (mgd < 9) {
            return mgd - 3;
        }else {
            return mgd - 6;
        }
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
}

// Here's some interesting testing code for reference

// let neighborDifferences = [-7,-6,-5,-1,1,5,6,7];

//         for i in 0..8 {
//             let mgd = i % 3 + 2 * 3 * (i/3);

//             mutable neighbors = 0;
//             for dif in neighborDifferences {
//                 if(ValidDex(mgd + dif)) {
//                     neighbors += 1;
//                     Message($"{MGDToIndex(mgd+dif)}");
//                 }
//             }

//             Message($"Total Number of Neighbors: {neighbors}");