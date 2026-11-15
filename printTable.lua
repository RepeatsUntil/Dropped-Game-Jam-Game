local function prnt(tbl, spacing)
    print(spacing.."tableId:", tbl)
    if tbl ~= nil then
        print(spacing.."{")
        for index, value in pairs(tbl) do
            if type(value) == "table" then
                print(spacing.."    ["..index.."] =", "{VVV}")
                prnt(value, spacing.."      ")
            elseif type(value) == "boolean" then
                if value == true then
                    print(spacing.."    ["..index.."] = ", "true")
                else
                    print(spacing.."    ["..index.."] = ", "false")
                end
            else
                print(spacing.."    ["..index.."] = ", value)
            end
        end
        print(spacing.."}")
    else
        print(spacing.."{nil}")
    end
end

return function(tbl)
    prnt(tbl, "")
    print("------")
end