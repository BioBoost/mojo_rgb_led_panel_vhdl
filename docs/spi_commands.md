# SPI Commands

## Sending pixel data to the controller

Format:

```
| command | panel id | line address |  pixel data  |
|   0x01  |   0-254  |    0 - 31    |  R |  G | B  |
|  1 byte |  1 byte  |    1 byte    | 32 x 3 bytes |
```

* By using a panel id of 255, you can write the information to all panels
* Line addressing starts at the top with 0


## Requesting a buffer switch

After sending data to the controller you need to request a buffer switch to get the image to display.
This can be achieved by sending a buffer switch command via SPI.

Format:

```
| command |
|   0x08  |
|  1 byte |
```

In an extreme case where you were to lower the refresh rate of the panels and set the clockrate of SPI very high you may need to add a delay between a buffer switch request and sending new data. If not it may occur that the new data is written to the current display buffer. This is a side effect of the fact that the buffer switch happens after a full frame is displayed. So there may be a slight delay between the request for a buffer switch and the actual switch.

