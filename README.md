# quality-godot-first-person-2
Actually good first person controller for the Godot Engine.  
MIT License (credit Colormatic Studios)

This first person controller was made because there aren't many first person controllers for Godot, and the ones that do exist are pretty bad.
It is highly customizable and comes with many features, QOL, and clean code.

Some parts came from StayAtHomeDev's FPS tutorial. You can find that [here](https://www.youtube.com/playlist?list=PLEHvj4yeNfeF6s-UVs5Zx5TfNYmeCiYwf).

# Directions
Move with WASD, space to jump, shift to sprint, C to crouch.

**FEATURES:**
 - In-air momentum
 - Motion smoothing
 - FOV smoothing
 - Head bobbing
 - Crouching
 - Sprinting
 - 2 crosshairs/reticles, one is animated (more to come?)

If you make a cool game with this addon, I would love to hear about it!

# Wiki
**To start out**, you should probably remap all of the movement keys to your own control set.  
You can make this a super basic controller by just disabling everything.

**How to change settings:**  

Click on the character node and there should be settings in the "Feature Settings" group.

**How to add animations for a mesh:**  

In the `_physics_process` function, add a line to check whether you are walking or aren't walking. You can do this by checking whether `input_dir` is true or false. Optionally, set the  animation speed to `speed / base_speed`. This will make it so when the player is walking, your animation speed is 1. If the player is sprinting, your animation goes up and if the player is crouching your animation speed goes down.

In  the `toggle_sprint` function, add a line at the end where if `is_sprinting` is true, your animation is set to sprint.

In the `toggle_crouch` function, add a line where if `is_crouching` is true, your animation is set to crouch.

To check if the player is in the air, add a line in the `_physics_process` function where it says `if not is_on_floor():`set your animation to falling/in the air. Add an else statement to change it to the normal state.

**How to change reticles (crosshairs):**  
- Find the folder at `res://addons/fpc/reticles`
- Pick one and add it to the `UserInterface` node in the character scene. You may need to right click on the character and enable "Editable Children".
- Set the Character value to your character node (it's under the Nodes group)
- Change the `anchors_preset` value on the reticle to Center

**How to create a new reticle**  
- Choose a reticle to base it off of
- Open that reticle and save it as a new reticle
- Edit the reticle to your needs
- Follow the "how to change reticles" directions to use it

