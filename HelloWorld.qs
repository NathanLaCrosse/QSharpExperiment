namespace HelloWorld {
    @EntryPoint()
    operation hi() : Result {
        use q1 = Qubit(); // use is a keyword to create an object which has quantum data

        H(q1);

        let result = M(q1); // let is immutable - this is a variable that cannot be changed
                            // use mutable before a variable name to be able to use it

        Reset(q1);

        for i in 0..2 { // i guess this is a valid for loop that loops from i = 0 to i = 2 (inclusive, both ends)
            Message("hi");
        }

        return result;
    }
}