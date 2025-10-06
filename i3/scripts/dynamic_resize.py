'''
    This script is a dynamic resizer for i3.

    i3wm only allows you to grow in a specific
    direction, but this script will shrink the
    focused window if there is nothing in that
    direction.

    It will do this by attempting to grow in
    the direction passed in, and if it cant, it
    will grow a neighbor in the opposite direction.
'''
import asyncio
import i3ipc
import argparse
from i3ipc.aio import Connection
from enum import Enum

class Direction(Enum):
    LEFT = 0
    RIGHT = 1
    UP = 2
    DOWN = 3

    def __str__(self):
        return self.name.lower()

    def __repr__(self):
        return str(self)

    def opposite(self):
        if self.value % 2 == 0:
            return Direction(self.value + 1);
        else:
            return Direction(self.value - 1);

class Resizer:
    def __init__(self, step=10, gaps=[0,0]):
        self.i3 = i3ipc.Connection()
        self.focused = self.i3.get_tree().find_focused()
        self.step = step
        self.inner_gap, self.outer_gap = gaps

    def __is_window_at_edge(self, direction):
        '''
          Returns whether or not the focused window is
          at the specified edge of the screen.
        '''
        rect = self.focused.rect
        deco_rect = self.focused.deco_rect
        wsrect = self.focused.workspace().rect

        offset = self.inner_gap + self.outer_gap - 1

        match direction:
            case Direction.LEFT:
                left = rect.x
                right = wsrect.x + offset
            case Direction.RIGHT:
                left = rect.x + rect.width
                right = wsrect.x + wsrect.width - offset
            case Direction.DOWN:
                left = rect.y + rect.height
                right = wsrect.y + wsrect.height - offset
            case Direction.UP:
                left = rect.y - deco_rect.height
                right = wsrect.y + offset
            case _:
                print(f"Undefined direction: {direction} not type: {type(Direction.LEFT)}, instead: {type(direction)}")
                return False

        return left == right

    def resize_window(self, direction):
        '''
            Tries to grow the window to the specified direction,
            by the specified step count. If it's at the edge,
            it shrinks in the opposite direction.
        '''
        if self.__is_window_at_edge(direction):
            print(f"We are at the {direction} edge, so we will shrink {direction.opposite()} instead")
            self.i3.command(f"resize shrink {direction.opposite()} {self.step}px or {self.step}ppt")
        else:
            print(f"We are not at the {direction} edge, growing like normal")
            self.i3.command(f"resize grow {direction} {self.step}px or {self.step}ppt")

def main():
    parser = argparse.ArgumentParser(description="Demonstrate argparse with Enums.")
    parser.add_argument(
        '-d',
        '--direction',
        nargs=1,
        type=lambda s: (
            Direction[s.upper()]
            if s.upper() in Direction.__members__
            else (_ for _ in ()).throw(
                argparse.ArgumentTypeError(
                    f"Invalid direction '{s}'. Must be one of: {', '.join(d.name.lower() for d in Direction)}"
                )
            )
        ),
        choices=list(Direction),
        required=True,
        help="Specify the direction to resize"
    )
    parser.add_argument(
        '-s',
        '--steps',
        nargs=1,
        type=int,
        default=10,
        required=False,
        help="Specify how much to resize by"
    )
    parser.add_argument(
        '-g',
        '--gaps',
        nargs=2,
        default=[0,0],
        type=int,
        required=False,
        metavar=('inner', 'outer'),
        help='Optionally specify inner and outer gaps'
    )
    args = parser.parse_args()

    resizer = Resizer(args.steps, args.gaps)
    resizer.resize_window(args.direction[0])

if __name__ == "__main__":
    main()
