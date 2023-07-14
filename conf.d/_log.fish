function _log_install --on-event log_install
    # Set universal variables, create bindings, and other initialization logic.
end

function _log_update --on-event log_update
    # Migrate resources, print warnings, and other update logic.
end

function _log_uninstall --on-event log_uninstall
    # Erase "private" functions, variables, bindings, and other uninstall logic.
end
