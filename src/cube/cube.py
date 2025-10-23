import sys
import time


def cube():
    w, h, out = 80, 24, sys.stdout
    cube = [(x, y, z) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    s = 0.1  # sine
    c = (1 - s**2) ** 0.5  # cosine

    ym = h / 3  # Y magnification
    xm = 2 * ym  # X magnification

    # Define the edges of the cube as a list of vertex pairs.
    edges = [
        (0, 1),
        (1, 3),
        (3, 2),
        (2, 0),  # Bottom square
        (4, 5),
        (5, 7),
        (7, 6),
        (6, 4),  # Top square
        (0, 4),
        (1, 5),
        (2, 6),
        (3, 7),  # Connecting edges
    ]

    while True:
        cube = [
            (c * x + s * z, y, -s * x + c * z) for x, y, z in cube
        ]  # Rotate around the Y-axis
        proj = [
            (round(w / 2 + xm * x / (z + 2)), round(h / 2 + ym * y / (z + 2)))
            for x, y, z in cube
        ]

        # Draw the edges of the cube
        for edge in edges:
            start = proj[edge[0]]
            end = proj[edge[1]]
            for i in range(
                1, 9
            ):  # Interpolate between start and end for smoother lines
                x = start[0] + i * (end[0] - start[0]) // 10
                y = start[1] + i * (end[1] - start[1]) // 10
                proj.append((x, y))

        out.write(
            "\033[H"
            + "\n".join(
                "".join(("*" if (x, y) in proj else " ") for x in range(w))
                for y in range(h)
            )
        )
        out.flush()
        time.sleep(1 / 15.0)
