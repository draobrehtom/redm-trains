Here is what I managed to uncover:

The train behaves differently depending on whether it is **migrated**. That is, if its owner has been changed, or as you called it "orphaned," the train begins to behave differently. For example, I tested the following scenario:

### Scenario
The train moves away from the owner and goes beyond the streaming range (owner's scope of 424.0 units). How will the train behave if:
- It does not enter the scope of another player
- It enters the scope of another player

### Test Results

1. **Non-migrated train leaves the owner's scope (original owner).**
   - If it does not enter the scope of another player - **it continues moving** (i.e., it continues to exist even beyond the scope).
   - Enters the scope of another player - continues moving, but now belongs to the other player. Possible bugs with the train teleporting.

2. **Migrated (orphaned) train leaves the new owner's scope:**
   - If the train does not enter the scope of another player - **it gets deleted**.
   - Enters the scope of another player - continues moving, but now belongs to the other player. Possible bugs with the train teleporting.

**Conclusion: ** There is a difference in the behaviour of the train when leaving the owner's scope - if the train leaves the original owner's scope versus if the train leaves the new owner's scope. 

Some other issues I encountered during testing include:
- **Missing train wagons**: Sometimes wagons disappear. This mainly happens during train migration.
- **Train teleportation**: Sometimes the train gets teleported to certain coordinates, which are defined in `trains3.dat`.
- **Train migration and deletion**: When I create a train on Client 1, if the train is in Client 2's zone, closer to Client 2 than to Client 1, or not in the scope of Client 1, then the train migrates to Client 2 and immediately gets deleted.

![image](https://github.com/draobrehtom/redm-trains/assets/6503721/dcd96ee7-3541-45f0-903a-f34a151ddcf4)


Also, I mentioned possible teleportation bugs. Sometimes the train can teleport to specific points on the map, such as:

Train train1 position suddenly changed for more than 400.0 (2711.560546875) units from vector3(28.9978, 224.9934, 108.0022) to vector3(2659.636, -429.244, 42.57434)

These coordinates match the beginning of the trains3.dat file:

```
147 142 open
c 2659.79 -435.711 42.5659 2659.79 -435.711 42.5659 2659.12 -413.096 42.6814 72.8832 8 freight_group
```
