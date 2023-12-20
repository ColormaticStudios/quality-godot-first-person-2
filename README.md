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
 - Controller/GamePad support (enabled through code, see wiki)

If you make a cool game with this addon, I would love to hear about it!

# Wiki
**To start out**, you should probably remap all of the movement keys to your own control set.

You can make this a super basic controller by just disabling everything.

**How to add controller/GamePad support**  
- In the controls export group, there is a commented section at the end that says "Uncomment this if you want full controller support". Uncomment that block.
- Make a key map for each direction (left, right, up, down) and map them to your joystick.
- Write in these keymaps in the controls section of the player settings.
- In the `_process` function, there is another block of commented code at the end that says the same thing. Uncomment that too.
- You should now be able to look around with the joystick. Make sure you add the other controls to the input map. (movement, jumping, crouching, sprinting, etc.)

**How to change settings:**  
Click on the character node and there should be settings in the "Feature Settings" group.

**How to add animations for a mesh:**  
- Create a function for your animation and attach it to `_physics_process` to call it every frame.
- Use `input_dir` as a boolean (it is actually a `Vector2`) to know if the player is walking.
- Use the `state` member variable to tell if the player is sprinting or crouching.
- Use the `is_on_floor` function to tell if the player is standing or falling.

**How to change reticles (crosshairs):**  
- Find the folder at `res://addons/fpc/reticles`.
- Pick one and add it to the `UserInterface` node in the character scene. You may need to right click on the character and enable "Editable Children".
- Set the Character value to your character node. (it's under the Nodes group)
- Change the `anchors_preset` value on the reticle to Center.

**How to create a new reticle:**  
- Choose a reticle to base it off of.
- Open that reticle and save it as a new reticle.
- Remove the script from the reticle and create a new one. (for some reason you have to do this)
- Edit the reticle to your needs.
- Follow the "how to change reticles" directions to use it.

