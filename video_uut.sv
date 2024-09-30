module video_uut (
    input  wire         clk_i,            // clock
    input  wire         cen_i,            // clock enable
    input  wire         vid_sel_i,        // select source video
    input  wire [19:0]  vdat_bars_i,      // input video {luma, chroma}
    input  wire [19:0]  vdat_colour_i,    // input video {luma, chroma}
    input  wire [3:0]   fvht_i,           // input video timing signals
    output wire [3:0]   fvht_o,           // 1 clk pulse after falling edge on input signal
    output wire [19:0]  video_o           // video output signal
);

// Box parameters for background
parameter integer box_x_start = 100;     // X coordinate where background box starts
parameter integer box_y_start = 50;      // Y coordinate where background box starts
parameter integer box_width   = 50;      // Width of the background box
parameter integer box_height  = 30;      // Height of the background box
parameter framemax = 2475002475;
reg [31:0] framecount;
//parameter blinktime;
parameter eyelid_size = 20;


// Moving square parameters
parameter integer square_size = 20;      // Size of the moving black square
reg [9:0] square_x_pos;                  // X coordinate of the moving square
reg [9:0] square_y_pos;                  // Y coordinate of the moving square

parameter shape_x_pos = 500;
parameter shape_y_pos = 500;
parameter shape_size = 200;



// Registers
reg [9:0] h_counter;                     // Horizontal counter (X axis)
reg [9:0] v_counter;                     // Vertical counter (Y axis)

reg [9:0] h_counter2;                     // Horizontal counter (X axis)
reg [9:0] v_counter2;                     // Vertical counter (Y axis)

reg [19:0] vid_d1;                       // Register for video output
reg [3:0] fvht_d1;                       // Register for video timing signals

wire H_IN = fvht_i[1];
wire V_IN = fvht_i[2];
reg H_DLY;
reg V_DLY;

wire H_POS = H_IN & ~H_DLY;
wire H_NEG = ~H_IN & H_DLY;

wire V_POS = V_IN & ~V_DLY;
wire V_NEG = ~V_IN & V_DLY;

reg no_box = 1;

// Slow counter
reg [15:0] slow_counter;                 // 16-bit slow counter to slow down the pixel updates
wire slow_enable;                        // Slow enable signal

// Define a simple black color for the box (20-bit value)
parameter [9:0] Y_VALUE = 10'h040;
parameter [9:0] CB_VALUE = 10'h200;
parameter [9:0] CR_VALUE = 10'h200;

parameter [9:0] Y_RED = 10'h040;     //logic for red
parameter [9:0] CB_RED = 10'h350;
parameter [9:0] CR_RED = 10'h1b3;


parameter [9:0] Y_BEIGE = 10'h0f2;     //logic for beige
parameter [9:0] CB_BEIGE = 10'h073;
parameter [9:0] CR_BEIGE = 10'h082;


bit flip = 0;

// Slow enable signal generation
assign slow_enable = (slow_counter == 16'hFFFF);  // Slow signal when the counter overflows

// Direction for the moving square
reg [1:0] direction;                     // Direction: 0 = right, 1 = down, 2 = left, 3 = up

// Initialization
initial begin
    square_x_pos = 0;
    square_y_pos = 0;
    direction = 0;  // Start moving right
    slow_counter = 0;
	 framecount = 0 ;
end

// Movement logic for the square
always @(posedge clk_i) begin
    if (cen_i) begin
	

        // Increment the slow counter
       if(framecount < framemax) begin
		 framecount <= framecount +1;
		  
		 end
		 else begin
		 framecount = 0;
		 end
        slow_counter <= slow_counter + 1;

        // Change square position based on direction
        if (slow_enable) begin
            case (direction)
                2'b00: square_x_pos <= square_x_pos + 1; // Move right
                2'b01: square_y_pos <= square_y_pos + 1; // Move down
                2'b10: square_x_pos <= square_x_pos - 1; // Move left
                2'b11: square_y_pos <= square_y_pos - 1; // Move up
            endcase

            // Change direction when hitting a boundary
            if (square_x_pos >= (1024 - square_size)) begin
                square_x_pos <= 1024 - square_size; // Prevent going out of bounds
                direction <= 2'b01; // Move down
            end
            if (square_y_pos >= (768 - square_size)) begin
                square_y_pos <= 768 - square_size; // Prevent going out of bounds
                direction <= 2'b10; // Move left
            end
            if (square_x_pos < 0) begin
                square_x_pos <= 0; // Prevent going out of bounds
                direction <= 2'b11; // Move up
            end
            if (square_y_pos < 0) begin
                square_y_pos <= 0; // Prevent going out of bounds
                direction <= 2'b00; // Move right
            end
        end
    end
end

// Pixel and timing registers
always @(posedge clk_i) begin
    if (cen_i) begin
        // Latch video timing signal
        fvht_d1 <= fvht_i;
		  
		
			H_DLY <= H_IN;
			V_DLY <= V_IN;
			h_counter2 <= (H_NEG) ? 0 : h_counter2 + 1;
			v_counter2 <= (H_POS & V_POS) ? 1 : (H_POS) ? v_counter2 + 1 : v_counter2;
			
		
			
			if ((h_counter2 >= shape_x_pos) && (h_counter2 < (shape_x_pos + shape_size)) &&
				 (v_counter2 >= shape_y_pos) && (v_counter2 < (shape_y_pos + shape_size))) begin
				  // If pixel is inside the moving square, set the color to black
//					no_box <= 0;

                 if(v_counter2 >= shape_y_pos && v_counter2 < shape_y_pos + eyelid_size)begin
//							vid_d1 <= (flip) ? {Y_BEIGE, CR_BEIGE} : {Y_BEIGE, CB_BEIGE};
							vid_d1 <= (flip) ? {Y_VALUE, CB_VALUE} : {Y_VALUE, CB_VALUE};
						end
						else begin
							vid_d1 <= (flip) ? {Y_RED, CR_RED} : {Y_RED, CB_RED};
						end
					
					flip <= ~flip;
					
//			 end else no_box <= 1;
			end else begin 
					if (slow_enable) begin
					// Check if the current pixel is inside the moving square
					if ((h_counter >= square_x_pos) && (h_counter < (square_x_pos + square_size)) &&
						 (v_counter >= square_y_pos) && (v_counter < (square_y_pos + square_size))) begin
						 // If pixel is inside the moving square, set the color to BOX_COLOR (black)
						 if (no_box) begin
							vid_d1 <= {Y_VALUE,CB_VALUE};
						 end
					end
					// Check if the current pixel is inside the background box boundaries
					else if ((h_counter >= box_x_start) && (h_counter < (box_x_start + box_width)) &&
								(v_counter >= box_y_start) && (v_counter < (box_y_start + box_height))) begin
						 // If pixel is inside the background box, set the color to BOX_COLOR
						 
						 if (no_box) begin
							vid_d1 <= {Y_VALUE,CB_VALUE};
						 end
					end else begin
						 // Otherwise, select video source based on vid_sel_i
						 if (no_box) begin
							vid_d1 <= (vid_sel_i) ? vdat_colour_i : vdat_bars_i;
						 end
					end

					// Update horizontal and vertical counters
					if (h_counter == 1023) begin    // Assuming 1024 pixels per line
						 h_counter <= 0;
						 if (v_counter == 767)       // Assuming 768 lines per frame
							  v_counter <= 0;
						 else
							  v_counter <= v_counter + 1;
					end else begin
						 h_counter <= h_counter + 1;
					end
			  end
			end    
    end
end


//always @(posedge clk_i) begin
//	if (cen_i) begin
//		H_DLY <= H_IN;
//		V_DLY <= V_IN;
//		h_counter2 <= (H_NEG) ? 0 : h_counter2 + 1;
//		v_counter2 <= (H_POS & V_POS) ? 1 : (H_POS) ? v_counter2 + 1 : v_counter2;
//		
//		if ((h_counter2 >= square_x_pos) && (h_counter2 < (square_x_pos + square_size)) &&
//          (v_counter2 >= square_y_pos) && (v_counter2 < (square_y_pos + square_size))) begin
//           // If pixel is inside the moving square, set the color to black
//				no_box <= 0;
//				vid_d1 <= {Y_VALUE,CB_VALUE};
//       end else no_box <= 1;
//		 
//		
//		
//		
//	end
//end


// OUTPUT
assign fvht_o  = fvht_d1;                // Assign timing signal
assign video_o = vid_d1;                 // Assign video output

endmodule

