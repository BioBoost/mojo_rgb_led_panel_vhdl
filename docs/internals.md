# Internals

## Buffer layout

Internally each panel component contains four buffers of 16 lines of 32 pixels (a pixel being R, G and B) each. These buffers are grouped together as an upper and lower part. Together they contain the information for a full frame.

--------------------------------
-                              -
-                              -
-         UPPER BUFFER         -
-                              -
-                              -
--------------------------------
-                              -
-                              -
-         LOWER BUFFER         -
-                              -
-                              -
--------------------------------

While one buffer group is used for fetching the data to be displayed the other group can be used for writing using the SPI interface. The buffers groups can be switched using an SPI command.