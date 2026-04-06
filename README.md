# quality-godot-first-person-2

Actually good first person controller for the Godot Engine.  
MIT License (credit Colormatic Studios)

This first person controller was made because there weren't many first person controllers for Godot at the time, and the ones that did exist were pretty bad.
It is highly customizable and comes with many features, QOL, and clean code.

Originally inspired by StayAtHomeDev's FPS tutorial. You can find that [here](https://www.youtube.com/playlist?list=PLEHvj4yeNfeF6s-UVs5Zx5TfNYmeCiYwf).

# Directions

Move with WASD, space to jump, shift to sprint, C to crouch.

**FEATURES:**

- Extremely configurable
- In-air momentum
- Motion smoothing
- FOV smoothing
- Movement animations
- Crouching
- Sprinting
- 2 crosshairs/reticles, one is animated (more to come?)
- Controller/GamePad support (enabled through code, see wiki)
- In-editor tools (enable editable children to use)

If you make a cool game with this addon, I would love to hear about it!

# Getting Started

Either use a terminal, or use a graphical Git application like [Git Cola](https://git-cola.github.io/).
You need to install Git or a Git GUI application.

**IMPORTANT:** If at any point you get an error, do not continue without fixing it.

**Terminal instructions**

1. Create a new folder for your project, we'll call this the project folder
2. Open a terminal
3. Write `cd ` in the terminal, do not press enter yet (`cd` means change directory)
4. Copy the path of your new folder in your file manager and paste it into the terminal with `ctrl+shift+v` (make sure there is a space after `cd`). This should look like: `cd path/to/project`
5. Press enter in the terminal
6. Paste the command `git clone https://git.colormatic.org/ColormaticStudios/quality-godot-first-person.git .` into the terminal with `ctrl+shift+v` and press enter. This will pull the Quality First Person Controller project into your folder, including the test scene
7. Open Godot Engine and press the import button, then find the `project.godot` in the project folder and open it
8. You should now have the project open in Godot. Remap all of the keys in input map to your preferences

**GUI instructions**

1. In your Git GUI, click the "Clone" button
2. Paste `https://git.colormatic.org/ColormaticStudios/quality-godot-first-person.git` into the URL box and press enter
3. Select the folder where you want to put the project. This will pull the Quality First Person Controller project into your folder, including the test scene
4. Open Godot Engine and press the import button, then find the `project.godot` in the project folder and open it
5. You should now have the project open in Godot. Remap all of the keys in input map to your preferences

# Wiki

**To start out**, you should probably remap all of the movement keys to your own control set.

You can make this a super basic controller by just disabling everything.

**How to add controller/GamePad support**

- In the controls export group, there is a commented section at the end that says "Uncomment this if you want full controller support". Uncomment that block.
- Make a key map for each direction (left, right, up, down) and map them to your joystick.
- Write in these keymaps in the controls section of the player settings.
- In the `handle_head_rotation` function, there is another block of commented code that says the same thing. Uncomment that too.
- You should now be able to look around with the joystick. Make sure you add the other controls to the input map. (movement, jumping, crouching, sprinting, etc.)

**Slope/staircase:**

Credit to [roberto-urbani23](https://github.com/roberto-urbani23)  
In the character inspector, you can uncheck Stop on Slope and set the max angle to 89 (for some reason, 90 will make the player stuck). Also Snap Length to 1 otherwise your character will not remain attached to stairs if you sprint while going downstairs.

**How to change settings:**

Click on the character node and there should be settings in the "Feature Settings" group.

**How to add animations for a mesh:**

- Create a function for your animation and attach it to `_physics_process` to call it every frame.
- Use `input_dir` as a boolean (it is actually a `Vector2`) to know if the player is walking.
- Use the `state` member variable to tell if the player is sprinting or crouching.
- Use the `is_on_floor` function to tell if the player is standing or falling.

**How to change reticles (crosshairs):**

Change the "Default Reticle" setting to your reticle file.  
During runtime:  
Use the `change_reticle` function on the character.

**How to create a new reticle:**

- Choose a reticle to base it off of.
- Open that reticle and save it as a new reticle.
- Remove the script from the reticle and create a new one. (for some reason you have to do this)
- Edit the reticle to your needs.
- Follow the "how to change reticles" directions to use it.

**How to use the editor tools:**

- Enable editable children on the `CharacterBody` node
- Use the options in the Properties tab to change things
- These changes apply in runtime as well
