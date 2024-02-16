use dep::std;

fn main(move: Field) {
    assert((move == 0) | (move == 1) | (move == 2), "Invalid move!");
}

/// MOVE CIRCUIT TESTS ///

#[test]
fn test_move_0() {
    main(0);
}

#[test]
fn test_move_1() {
    main(1);
}

#[test]
fn test_move_2() {
    main(2);
}

#[test(should_fail_with = "Invalid move!")]
fn test_invalid_army_less() {
    main(3);
}
