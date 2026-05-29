def systemInfoString
    str = ""
    str += "Platform: #{System.platform}\r\n"
    if Input.joystick
        str += "Joystick: #{Input.joystick[:name]},#{Input.joystick[:power]}\r\n"
    else
        str += "Joystick: none\r\n"
    end
    str += "Data Directory: #{System.data_directory}\r\n"
    str += "Language: #{System.user_language}\r\n"
    return str
rescue NoMethodError
    return ""
end

def displaySystemInfo
    pbMessage(systemInfoString)
end
