import math

def parse_coordinates(file_path):
    coordinates = []
    with open(file_path, 'r') as file:
        lines = file.readlines()

    for line in lines:
        parts = line.strip().split()
        
        # Ensure the line starts with 'c' and has enough parts to process
        if len(parts) > 3 and parts[0] == 'c':
            for i in range(1, 9, 3):
                try:
                    x = float(parts[i])
                    y = float(parts[i + 1])
                    z = float(parts[i + 2])
                    coordinates.append((x, y, z))
                except ValueError:
                    print(f"Skipping invalid coordinate format in line: {line}")

    return coordinates

def find_closest_coordinate(coordinates, target):
    if not coordinates:
        return None
    
    min_distance = math.inf
    closest_coordinate = None

    for coord in coordinates:
        x, y, z = coord
        distance = math.sqrt((x - target[0]) ** 2 + (y - target[1]) ** 2 + (z - target[2]) ** 2)
        if distance < min_distance:
            min_distance = distance
            closest_coordinate = coord
    
    return closest_coordinate

# Example usage
file_path = 'trains1.dat'
coordinates = parse_coordinates(file_path)
# print(coordinates)

target_coordinate = (-513.5604, 1165.768, 137.3378)
closest_coord = find_closest_coordinate(coordinates, target_coordinate)

if closest_coord:
    print(f"The closest coordinate to {target_coordinate} is: {closest_coord}")
else:
    print("No coordinates found or an error occurred.")