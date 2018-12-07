pro printhex, var1, var2, var3, var4, var5, var6, var7, var8

case n_params() of

    1: print, conv2hex(var1)
    2: print, conv2hex(var1), conv2hex(var2)
    3: print, conv2hex(var1), conv2hex(var2), conv2hex(var3)
    4: print, conv2hex(var1), conv2hex(var2), conv2hex(var3), conv2hex(var4)
    5: print, conv2hex(var1), conv2hex(var2), conv2hex(var3), conv2hex(var4), conv2hex(var5)
    6: print, conv2hex(var1), conv2hex(var2), conv2hex(var3), conv2hex(var4), conv2hex(var5), conv2hex(var6)
    7: print, conv2hex(var1), conv2hex(var2), conv2hex(var3), conv2hex(var4), conv2hex(var5), conv2hex(var6), conv2hex(var7)
    8: print, conv2hex(var1), conv2hex(var2), conv2hex(var3), conv2hex(var4), conv2hex(var5), conv2hex(var6), conv2hex(var7), conv2hex(var8)
endcase
end
