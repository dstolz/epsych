
function levels = calculate_harmonics_levels(f0_level,weights_relative_to_f0)

levels = zeros(size(weights_relative_to_f0));
for ih = 1:numel(weights_relative_to_f0)
    levels(ih) = f0_level + (10 * log2(weights_relative_to_f0(ih)));
    
    if ~isfinite(levels(ih))
        levels(ih) = 0;
    end
end

end
