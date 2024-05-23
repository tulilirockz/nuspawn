#!/usr/bin/env nu
let temp_folder = (mktemp -d)
git clone https://github.com/tulilirockz/nuspawn.git $temp_folder
try {
  sudo sed -i "s~./lib~/usr/libexec/nuspawn~g" $"($temp_folder)/src/nuspawn"
  sudo mkdir "/usr/libexec/nuspawn"
  sudo cp ...(glob $"($temp_folder)/src/lib/*") /usr/libexec/nuspawn
  sudo cp $"($temp_folder)/src/nuspawn" /usr/bin/nuspawn
} catch {
  print "Failed installing due to permission error"
}
