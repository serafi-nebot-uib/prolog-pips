% no_constraint(+Values)
% True for any list of values. Represents an empty region restriction.
no_constraint(_).

% all_equal_values(+Values)
% True when all values in Values are equal.
all_equal_values([]).
all_equal_values([_]).
all_equal_values([X, X | L]) :- all_equal_values([X | L]).

% list_contains(?Element, +List)
% True when Element appears in List.
list_contains(X, [X | _]).
list_contains(X, [_ | L]) :- list_contains(X, L).

% all_distinct_values(+Values)
% True when all values in Values are pairwise different.
all_distinct_values([]).
all_distinct_values([_]).
all_distinct_values([X | L]) :- not(list_contains(X, L)), all_distinct_values(L).

% sum_values(+Values, ?Total)
% True when Total is the arithmetic sum of all values in Values.
sum_values([], 0).
sum_values([X | L], Y) :- sum_values(L, Y2), Y is X + Y2.

% values_sum_less_than(+Values, +Target)
% True when the sum of Values is strictly less than Target.
values_sum_less_than(L, Y) :- sum_values(L, S), S < Y.

% values_sum_greater_than(+Values, +Target)
% True when the sum of Values is strictly greater than Target.
values_sum_greater_than(L, Y) :- sum_values(L, S), S > Y.

% cell_coord(+Cell, -Coord)
% Coord is the coordinate stored in Cell.
cell_coord(cell(Coord, _), Coord).

% cell_value(+Cell, -Value)
% Value is the value stored in Cell.
cell_value(cell(_, Value), Value).

% cell_at(+Coord, +Cells, -Cell)
% Cell is the cell in Cells located at Coord.
cell_at(Coord, [cell(Coord, Value) | _], cell(Coord, Value)).
cell_at(Coord, [_ | L], Cell) :- cell_at(Coord, L, Cell).

% coordinate_in_cells(+Coord, +Cells)
% True when there is a cell in Cells located at Coord.
coordinate_in_cells(Coord, [cell(Coord, _) | _]).
coordinate_in_cells(Coord, [_ | L]) :- coordinate_in_cells(Coord, L).

% cells_overlap(+Cells)
% True when at least two cells in Cells have the same coordinate.
cells_overlap([cell(Coord, _) | L]) :- coordinate_in_cells(Coord, L).
cells_overlap([_ | L]) :- cells_overlap(L).

% adjacent_coords(+Coord1, +Coord2)
% True when Coord1 and Coord2 are horizontally or vertically adjacent.
adjacent_coords([X1, Y1], [X2, Y2]) :- 1 is abs(X1 - X2) + abs(Y1 - Y2).

% cells_from_piece_placement(+Piece, +Position, -Cells)
% Cells contains the two cells produced by placing Piece at Position.
cells_from_piece_placement([V1, V2], [[X1, Y1], [X2, Y2]], [cell([X1, Y1], V1), cell([X2, Y2], V2)]) :-
    adjacent_coords([X1, Y1], [X2, Y2]).

% values_at_coords(+Coords, +Cells, -Values)
% Values are the values found in Cells at the coordinates in Coords.
values_at_coords([], _, []).
values_at_coords([Coord | CoordRest], Cells, [Value | ValueRest]) :-
    cell_at(Coord, Cells, Cell),
    cell_value(Cell, Value),
    values_at_coords(CoordRest, Cells, ValueRest).

/*******************************************************/

% region_contains_coord(+Coord, +Region)
% True when Coord is one of the coordinates in Region.
region_contains_coord(Coord, region(_, _, [Coord | _])).
region_contains_coord(Coord, region(_, _, [_ | CoordRest])) :- region_contains_coord(Coord, region(_, _, CoordRest)).

% cells_for_region(+Region, +Cells, -RegionCells)
% RegionCells are the cells from Cells whose coordinates belong to Region.
cells_for_region(region(_, _, []), _, []).
cells_for_region(region(Type, Target, [Coord | CoordRest]), Cells, [C | CRest]) :-
    cell_at(Coord, Cells, C),
    cells_for_region(region(Type, Target, CoordRest), Cells, CRest).

% values_from_cells(+Cells, -Values)
% Values contains only the values stored in Cells, preserving order.
values_from_cells([], []).
values_from_cells([cell(_, Value) | Cells], [Value | Values]) :-
    values_from_cells(Cells, Values).

% cells_satisfy_constraint(+Cells, +Type, +Target)
% True when the values in Cells satisfy the region constraint Type/Target.
cells_satisfy_constraint(Cells, Type, Target) :-
    values_from_cells(Cells, Values),
    values_satisfy_constraint(Values, Type, Target).

% values_satisfy_constraint(+Values, +Type, +Target)
% Dispatches a region condition to the matching values predicate.
values_satisfy_constraint(Values, empty, nil) :- no_constraint(Values).
values_satisfy_constraint(Values, equals, nil) :- all_equal_values(Values).
values_satisfy_constraint(Values, unequal, nil) :- all_distinct_values(Values).
values_satisfy_constraint(Values, sum, Target) :- sum_values(Values, Target).
values_satisfy_constraint(Values, less, Target) :- values_sum_less_than(Values, Target).
values_satisfy_constraint(Values, greater, Target) :- values_sum_greater_than(Values, Target).

% cells_from_solution(+Solution, +Pieces, -Cells)
% Converts placed pieces into cell(Coord, Value) terms.
cells_from_solution([], [], []).
cells_from_solution([[C1, C2] | CoordRest], [[V1, V2] | ValueRest], [cell(C1, V1), cell(C2, V2) | CellRest]) :-
    cells_from_solution(CoordRest, ValueRest, CellRest).

% region_satisfied_by_cells(+Region, +Cells)
% True when Cells satisfy the constraint described by Region.
region_satisfied_by_cells(region(Type, Target, Coords), Cells) :-
    cells_for_region(region(Type, Target, Coords), Cells, RegionCells),
    cells_satisfy_constraint(RegionCells, Type, Target).

% regions_satisfied_by_cells(+Regions, +Cells)
% True when every region in Regions is satisfied by Cells.
regions_satisfied_by_cells([], _).
regions_satisfied_by_cells([Region | RegionRest], Cells) :-
    region_satisfied_by_cells(Region, Cells),
    regions_satisfied_by_cells(RegionRest, Cells).

% solucio_pips(+Regions, +Pieces, +Solution)
% True when Solution places Pieces so that all Regions are satisfied.
solucio_pips(Regions, Pieces, Solution) :-
    cells_from_solution(Solution, Pieces, Cells),
    not(cells_overlap(Cells)),
    regions_satisfied_by_cells(Regions, Cells).

% solucio_pips([region(empty, nil, [[0,0]]), region(equals, nil, [[0,1],[0,2],[1,1],[1,2]]), region(sum, 5, [[0,3]]), region(sum, 12, [[2,1],[2,2]])], [[2,2], [5,2], [2,3], [6,6]], [[[1,1],[1,2]], [[0,3],[0,2]], [[0,1],[0,0]], [[2,1],[2,2]]]).

/*******************************************************/

/*
solucio_pips([region(empty, nil, [[0,0]]),
              region(equals, nil, [[0,1],[0,2],[1,1],[1,2]]),
              region(sum, 5, [[0,3]]),
              region(sum, 12, [[2,1],[2,2]])],
            [[2,2],
             [5,2],
             [2,3],
             [6,6]],
            Solucio).
Solucio = [[[1,1],[1,2]],
           [[0,3],[0,2]],
           [[0,1],[0,0]],
           [[2,1],[2,2]]].
*/

/*******************************************************/

puzzle(20250818, easy,
  [region(empty, nil, [[0,0]]),
   region(equals, nil, [[0,1],[0,2],[1,1],[1,2]]),
   region(sum, 5, [[0,3]]),
   region(sum, 12, [[2,1],[2,2]])],
  [[2,2],
   [2,3],
   [5,2],
   [6,6]],
  [[[1,1],[1,2]],
   [[0,1],[0,0]],
   [[0,3],[0,2]],
   [[2,1],[2,2]]]).


puzzle(20250818, medium,
  [region(less, 13, [[0,0],[1,0],[1,1]]),
   region(empty, nil, [[0,1]]),
   region(sum, 18, [[1,3],[2,2],[2,3]]),
   region(less, 3, [[1,4]]),
   region(sum, 2, [[2,1]]),
   region(greater, 4, [[2,4]])],
  [[1,6],
   [4,4],
   [6,3],
   [2,6],
   [5,6]],
  [[[1,4],[1,3]],
   [[1,0],[1,1]],
   [[0,1],[0,0]],
   [[2,1],[2,2]],
   [[2,4],[2,3]]]).


puzzle(20250818, hard,
  [region(less, 3, [[0,1],[0,2]]),
   region(empty, nil, [[0,6]]),
   region(equals, nil, [[0,7],[1,7]]),
   region(equals, nil, [[1,0],[1,1]]),
   region(sum, 1, [[1,2]]),
   region(equals, nil, [[1,4],[2,4]]),
   region(sum, 18, [[1,5],[1,6],[2,6]]),
   region(sum, 10, [[1,8],[2,8]]),
   region(sum, 0, [[2,0],[2,1],[2,2],[2,3]]),
   region(sum, 4, [[2,7]])],
  [[0,0],
   [6,6],
   [1,6],
   [1,1],
   [2,0],
   [0,6],
   [2,6],
   [3,1],
   [3,5],
   [4,5]],
  [[[2,1],[2,2]],
   [[1,6],[2,6]],
   [[1,2],[1,1]],
   [[0,1],[0,2]],
   [[2,4],[2,3]],
   [[2,0],[1,0]],
   [[1,4],[1,5]],
   [[0,7],[0,6]],
   [[1,7],[1,8]],
   [[2,7],[2,8]]]).


puzzle(20250819, easy,
  [region(sum, 6, [[0,1]]),
   region(empty, nil, [[1,0]]),
   region(empty, nil, [[1,1]]),
   region(sum, 5, [[1,2]]),
   region(equals, nil, [[2,0],[2,1]]),
   region(empty, nil, [[2,2]]),
   region(sum, 0, [[3,1]])],
  [[6,1],
   [2,4],
   [5,3],
   [2,0]],
  [[[0,1],[1,1]],
   [[2,0],[1,0]],
   [[1,2],[2,2]],
   [[2,1],[3,1]]]).


puzzle(20250819, medium,
  [region(empty, nil, [[0,0]]),
   region(greater, 3, [[0,3]]),
   region(equals, nil, [[1,0],[1,1],[1,2],[1,3]]),
   region(sum, 3, [[2,2],[2,3],[3,3]]),
   region(empty, nil, [[2,4]]),
   region(sum, 2, [[3,2]]),
   region(sum, 6, [[3,4]])],
  [[2,1],
   [1,6],
   [1,3],
   [3,4],
   [3,3],
   [1,0]],
  [[[3,2],[2,2]],
   [[3,3],[3,4]],
   [[0,0],[1,0]],
   [[1,3],[0,3]],
   [[1,1],[1,2]],
   [[2,3],[2,4]]]).


puzzle(20250819, hard,
  [region(unequal, nil, [[0,0],[1,0],[2,0]]),
   region(sum, 0, [[0,1],[1,1]]),
   region(equals, nil, [[2,1],[2,2],[3,2],[3,3],[4,3],[4,4]]),
   region(sum, 2, [[2,3]]),
   region(sum, 7, [[2,5],[3,5]]),
   region(sum, 3, [[3,1]]),
   region(sum, 5, [[3,4]]),
   region(sum, 4, [[4,2]]),
   region(sum, 6, [[4,5]])],
  [[4,1],
   [5,6],
   [6,1],
   [3,1],
   [5,1],
   [1,0],
   [3,4],
   [1,2],
   [0,4]],
  [[[4,2],[4,3]],
   [[1,0],[2,0]],
   [[4,5],[4,4]],
   [[3,1],[3,2]],
   [[3,4],[3,3]],
   [[2,1],[1,1]],
   [[2,5],[3,5]],
   [[2,2],[2,3]],
   [[0,1],[0,0]]]).


puzzle(20250820, easy,
  [region(empty, nil, [[0,0]]),
   region(sum, 0, [[0,1],[0,2],[0,3]]),
   region(sum, 4, [[1,0]]),
   region(empty, nil, [[1,1]]),
   region(sum, 2, [[1,2],[1,3]])],
  [[0,0],
   [4,6],
   [1,0],
   [5,1]],
  [[[0,1],[0,2]],
   [[1,0],[0,0]],
   [[1,3],[0,3]],
   [[1,1],[1,2]]]).


puzzle(20250820, medium,
  [region(equals, nil, [[0,2],[1,2]]),
   region(sum, 2, [[0,3],[1,3]]),
   region(sum, 2, [[1,1]]),
   region(equals, nil, [[2,1],[2,2],[2,3],[3,1]]),
   region(sum, 3, [[3,0]])],
  [[3,3],
   [6,6],
   [6,3],
   [6,2],
   [1,1]],
  [[[0,2],[1,2]],
   [[2,2],[2,3]],
   [[3,1],[3,0]],
   [[2,1],[1,1]],
   [[0,3],[1,3]]]).


puzzle(20250820, hard,
  [region(sum, 6, [[0,0]]),
   region(sum, 2, [[1,0],[2,0]]),
   region(empty, nil, [[3,0]]),
   region(empty, nil, [[4,0]]),
   region(sum, 4, [[4,1],[4,2]]),
   region(equals, nil, [[4,3],[4,4],[4,5],[5,5]]),
   region(empty, nil, [[5,0]]),
   region(equals, nil, [[6,0],[7,0],[8,0]]),
   region(equals, nil, [[6,5],[7,5],[8,5]])],
  [[2,1],
   [2,3],
   [4,6],
   [1,6],
   [4,4],
   [6,6],
   [5,5],
   [2,5],
   [6,5]],
  [[[3,0],[2,0]],
   [[4,1],[4,0]],
   [[6,0],[5,0]],
   [[1,0],[0,0]],
   [[7,0],[8,0]],
   [[7,5],[8,5]],
   [[4,4],[4,5]],
   [[4,2],[4,3]],
   [[6,5],[5,5]]]).


puzzle(20250821, easy,
  [region(sum, 2, [[0,0]]),
   region(sum, 7, [[0,1],[1,1]]),
   region(sum, 7, [[2,1],[3,1]]),
   region(sum, 9, [[4,1],[5,1]]),
   region(sum, 2, [[5,2]])],
  [[2,3],
   [4,5],
   [4,3],
   [4,2]],
  [[[0,0],[0,1]],
   [[3,1],[4,1]],
   [[1,1],[2,1]],
   [[5,1],[5,2]]]).


puzzle(20250821, medium,
  [region(unequal, nil, [[0,1],[1,1],[2,1]]),
   region(sum, 5, [[3,1],[3,2],[4,1],[4,2],[5,2]]),
   region(sum, 5, [[3,3]]),
   region(empty, nil, [[4,0]])],
  [[1,5],
   [1,1],
   [5,0],
   [3,2],
   [6,5]],
  [[[4,1],[4,0]],
   [[4,2],[5,2]],
   [[3,3],[3,2]],
   [[2,1],[3,1]],
   [[0,1],[1,1]]]).


puzzle(20250821, hard,
  [region(equals, nil, [[0,1],[1,0],[1,1],[1,2],[2,1]]),
   region(empty, nil, [[0,2]]),
   region(sum, 10, [[0,3],[1,3]]),
   region(empty, nil, [[2,0]]),
   region(sum, 0, [[3,1],[3,2],[3,3],[3,4]]),
   region(equals, nil, [[4,4],[5,3],[5,4],[5,5],[6,4]]),
   region(empty, nil, [[4,5]]),
   region(sum, 3, [[5,2]]),
   region(sum, 4, [[6,2],[6,3]])],
  [[4,4],
   [1,1],
   [0,5],
   [4,1],
   [5,6],
   [1,0],
   [6,1],
   [2,5],
   [5,5],
   [0,0],
   [0,3]],
  [[[0,2],[0,3]],
   [[5,3],[5,4]],
   [[3,1],[2,1]],
   [[6,3],[6,4]],
   [[1,2],[1,3]],
   [[4,4],[3,4]],
   [[4,5],[5,5]],
   [[2,0],[1,0]],
   [[0,1],[1,1]],
   [[3,2],[3,3]],
   [[6,2],[5,2]]]).


puzzle(20250822, easy,
  [region(sum, 1, [[0,0]]),
   region(empty, nil, [[0,1]]),
   region(sum, 0, [[0,2]]),
   region(empty, nil, [[1,0]]),
   region(sum, 1, [[2,0]]),
   region(sum, 8, [[2,1],[2,2]]),
   region(empty, nil, [[3,2]]),
   region(equals, nil, [[4,0],[4,1]])],
  [[5,1],
   [6,0],
   [1,1],
   [1,6],
   [4,3]],
  [[[2,1],[2,0]],
   [[0,1],[0,2]],
   [[4,0],[4,1]],
   [[0,0],[1,0]],
   [[3,2],[2,2]]]).


puzzle(20250822, medium,
  [region(empty, nil, [[0,0]]),
   region(sum, 3, [[0,1],[0,2]]),
   region(equals, nil, [[1,0],[1,1],[1,2]]),
   region(sum, 5, [[2,0]]),
   region(equals, nil, [[2,1],[3,1]]),
   region(sum, 6, [[2,3],[3,2],[3,3]])],
  [[6,5],
   [5,5],
   [1,1],
   [0,4],
   [4,6],
   [5,3]],
  [[[2,1],[2,0]],
   [[1,0],[1,1]],
   [[2,3],[3,3]],
   [[0,1],[0,0]],
   [[3,2],[3,1]],
   [[1,2],[0,2]]]).


puzzle(20250822, hard,
  [region(sum, 18, [[0,1],[0,2],[0,3]]),
   region(equals, nil, [[0,4],[1,4],[2,4]]),
   region(empty, nil, [[1,0]]),
   region(sum, 0, [[1,1],[1,2],[2,1],[2,2],[2,3]]),
   region(empty, nil, [[1,3]]),
   region(sum, 1, [[3,1]]),
   region(empty, nil, [[3,2]]),
   region(equals, nil, [[4,2],[5,2]]),
   region(sum, 2, [[4,4]]),
   region(equals, nil, [[5,3],[5,4]])],
  [[0,0],
   [0,1],
   [0,2],
   [0,5],
   [6,6],
   [6,3],
   [3,4],
   [2,2],
   [3,2],
   [4,1]],
  [[[1,2],[2,2]],
   [[2,1],[3,1]],
   [[2,3],[2,4]],
   [[1,1],[1,0]],
   [[0,1],[0,2]],
   [[0,3],[1,3]],
   [[5,3],[5,2]],
   [[0,4],[1,4]],
   [[5,4],[4,4]],
   [[4,2],[3,2]]]).


puzzle(20250823, easy,
  [region(empty, nil, [[0,0]]),
   region(sum, 1, [[0,1],[0,2]]),
   region(equals, nil, [[1,0],[1,1],[1,2]]),
   region(sum, 4, [[2,0],[2,1]])],
  [[0,0],
   [3,1],
   [3,3],
   [4,0]],
  [[[0,0],[0,1]],
   [[1,2],[0,2]],
   [[1,0],[1,1]],
   [[2,0],[2,1]]]).


puzzle(20250823, medium,
  [region(less, 2, [[0,1]]),
   region(equals, nil, [[0,2],[1,1],[1,2]]),
   region(empty, nil, [[1,0]]),
   region(sum, 12, [[2,0],[3,0]]),
   region(equals, nil, [[3,1],[3,2],[4,1]]),
   region(empty, nil, [[4,0]]),
   region(empty, nil, [[4,2]])],
  [[6,3],
   [1,4],
   [1,5],
   [4,6],
   [5,5],
   [3,4]],
  [[[2,0],[1,0]],
   [[4,2],[3,2]],
   [[0,1],[0,2]],
   [[3,1],[3,0]],
   [[1,1],[1,2]],
   [[4,0],[4,1]]]).


puzzle(20250823, hard,
  [region(less, 6, [[0,6],[1,6],[2,6],[3,6]]),
   region(empty, nil, [[0,7]]),
   region(sum, 4, [[1,1],[1,2],[1,3],[1,4]]),
   region(sum, 3, [[1,7]]),
   region(equals, nil, [[2,1],[3,0],[3,1],[4,0]]),
   region(sum, 6, [[2,4]]),
   region(greater, 2, [[3,3]]),
   region(sum, 6, [[3,4]]),
   region(sum, 6, [[4,1]]),
   region(sum, 6, [[4,3]]),
   region(empty, nil, [[4,4]])],
  [[1,0],
   [1,1],
   [1,6],
   [1,4],
   [1,3],
   [1,2],
   [6,3],
   [0,0],
   [0,6],
   [6,2]],
  [[[3,6],[2,6]],
   [[3,0],[4,0]],
   [[3,1],[4,1]],
   [[0,6],[0,7]],
   [[1,6],[1,7]],
   [[2,1],[1,1]],
   [[3,4],[3,3]],
   [[1,2],[1,3]],
   [[4,4],[4,3]],
   [[2,4],[1,4]]]).


puzzle(20250824, easy,
  [region(empty, nil, [[0,0]]),
   region(sum, 6, [[1,0]]),
   region(equals, nil, [[1,1],[1,2]]),
   region(empty, nil, [[2,1]]),
   region(equals, nil, [[2,2],[2,3],[3,3]])],
  [[0,4],
   [6,5],
   [4,4],
   [1,1]],
  [[[2,1],[2,2]],
   [[1,0],[0,0]],
   [[2,3],[3,3]],
   [[1,1],[1,2]]]).


puzzle(20250824, medium,
  [region(sum, 1, [[0,1]]),
   region(sum, 16, [[0,2],[1,2],[2,2],[3,2]]),
   region(greater, 2, [[1,3]]),
   region(empty, nil, [[2,0]]),
   region(empty, nil, [[2,3]]),
   region(sum, 0, [[3,0],[3,1]]),
   region(empty, nil, [[4,2]]),
   region(sum, 0, [[5,0]]),
   region(equals, nil, [[5,1],[5,2]])],
  [[1,4],
   [2,0],
   [3,4],
   [4,2],
   [0,1],
   [3,2],
   [0,4]],
  [[[0,1],[0,2]],
   [[5,1],[5,0]],
   [[1,3],[1,2]],
   [[2,2],[2,3]],
   [[3,0],[2,0]],
   [[4,2],[5,2]],
   [[3,1],[3,2]]]).


puzzle(20250824, hard,
  [region(less, 3, [[0,0]]),
   region(equals, nil, [[0,1],[1,1],[1,4],[2,1],[2,2],[2,3],[2,4]]),
   region(less, 2, [[0,4]]),
   region(sum, 2, [[0,5],[1,5]]),
   region(empty, nil, [[1,0]]),
   region(equals, nil, [[2,0],[3,0]]),
   region(sum, 0, [[2,5],[3,5]]),
   region(empty, nil, [[3,1]]),
   region(sum, 10, [[3,2],[3,3]]),
   region(empty, nil, [[3,4]])],
  [[2,6],
   [5,6],
   [4,6],
   [6,0],
   [0,3],
   [4,3],
   [5,5],
   [6,1],
   [0,1],
   [6,6]],
  [[[0,0],[0,1]],
   [[1,0],[1,1]],
   [[2,0],[2,1]],
   [[2,4],[2,5]],
   [[3,5],[3,4]],
   [[3,0],[3,1]],
   [[3,2],[3,3]],
   [[1,4],[1,5]],
   [[0,4],[0,5]],
   [[2,2],[2,3]]]).
