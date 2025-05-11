# :gem: 01: Shockwave

Shockwave demo in pure Dart.

Inspiration: **Wave animations in SwiftUI** by [Mykola Harmash](https://www.youtube.com/watch?v=-Rzu1Ujcz38)

## Demo

<video src="assets/preview.mp4" placeholder="assets/preview.png" autoplay loop controls muted title="Showckwave Demo" width="300">
Sorry, your browser doesn't support HTML 5 video.
</video>

## Implementation Details

This demo showcases a beautiful wave animation effect that ripples through a grid of elements. The implementation:

- Uses a custom grid layout with animated cells
- Creates a ripple effect that propagates outward from touch points
- Implements smooth animations using Flutter's animation framework
- Calculates wave propagation based on distance from origin

### Key Components

- `ShockwaveGrid`: Main widget that displays the grid and handles touch interactions
- **Wave Propagation**: Mathematical calculations to determine the timing and intensity of the wave effect
- **Color Transitions**: Smooth color transitions as the wave passes through each cell

## Code Structure

The project is organized as follows:

- `lib/main.dart`: Entry point with minimal setup
- `lib/widgets/shockwave_grid.dart`: Core implementation of the grid and wave animation
- No external dependencies beyond Flutter's core libraries

## How It Works

1. The grid detects touch events and calculates the origin point
2. Each cell's animation is delayed based on its distance from the origin
3. The wave effect is achieved through carefully timed animations
4. Pure Dart implementation makes it highly performant across platforms

## License

All code in this repository is licensed under the [MIT License](../../LICENSE).
