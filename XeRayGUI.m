function handle = XeRayGUI(mode)

if isnumeric(mode) && mode == 2
    handle = XeRay2();
else
    handle = XeRay();
end

end