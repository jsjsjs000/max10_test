	/* SVGA 1280x1024 60Hz, 108MHz pixel clock, 9,259259ns
	   63981Hz pixel H, 60.027Hz pixel V */
`define WIDTH			1280	// 1688 total
`define HEIGHT			1024	// 1066 total
`define H_FRONT_PORCH	48
`define H_SYNC			112
`define H_BACK_PORCH	248
`define V_FRONT_PORCH	1
`define V_SYNC			3
`define V_BACK_PORCH	38

	/* SVGA 800x600 60Hz, 40MHz pixel clock, 25ns
	   37879Hz pixel H, 60.317Hz pixel V
`define WIDTH			800		// 1056 total
`define HEIGHT			600		// 628 total
`define H_SYNC			128
`define H_FRONT_PORCH	40
`define H_BACK_PORCH	88
`define V_SYNC			4
`define V_FRONT_PORCH	1
`define V_BACK_PORCH	23 */
	
`define SYNC_H			1		// positive sync
`define SYNC_L	 		0
//`defiine SYNC_H		0		// negative sync
//`defiine SYNC_L		1

`define IMAGE_STATE_RECTANGLE   4'b0001		// ImageState - state machine
`define IMAGE_STATE_V_BARS      4'b0010
`define IMAGE_STATE_H_BARS      4'b0100
`define IMAGE_STATE_GRAY_SCALE  4'b1000

//`define	INITIAL_IMAGE_STATE		`IMAGE_STATE_RECTANGLE
//`define	INITIAL_IMAGE_STATE		`IMAGE_STATE_V_BARS
`define	INITIAL_IMAGE_STATE		`IMAGE_STATE_H_BARS
//`define	INITIAL_IMAGE_STATE		`IMAGE_STATE_GRAY_SCALE

//`define CHANGE_IMAGE
