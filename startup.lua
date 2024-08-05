-- HayaOS Startup Script
-- Developed by Keyboard.
-- Licensed under CC BY-SA 4.0.

term.clear()

print([[

    /\
   /  \
  |    |
  |    |
   \  /
    \/

  HayaOS

]])

function welcome()
    print("Welcome to HayaOS, an OS for CraftOS2.")
    print("Type 'help' for a list of commands.")

    print("HayaOS is developed by MrMasterKeyboard and licensed under Creative Commons Attributions Sharealike 4.0.")
end

welcome()

while true do
    write("HayaShell> ")
    local input = read()
    if input == "help" then
        print("HayaHelp:")
        print("To be done.")
    end
end
