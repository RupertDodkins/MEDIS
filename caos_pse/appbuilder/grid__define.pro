;T+
; \subsubsection{Object Description}
; 
; The graphical aspect of the {\tt AB} worksheet is a rectangular area
; with a regular grid of {\bf slots}.
; 
; The grid is defined as a subclass of the IDL standard graphic object 
; 'IDLgrModel' by the following code.
; 
;T-
;
; NAME:
;        Grid  - Grid object
; 
; This procedure defines the grid for building the application. It
; returns an object of type "IDLgrModel" which can be added to a view
;
; Usage:
;
;	MyGrid = Obj_New('Grid',Xslots,Yslots);
;
; Methods: 
;
;	[xs,ys,xc,yc] = Grid::GetSize
;	[x0,x1,y0,y1] = Grid::EnclosingBox, PrjBox  ; Returns the coordinates 
;	                                            ; of the given slot box
;	[xs,ys] = Grid::Screen2slot, xy	   ; returns slot number corresponding
;	                                     to screen position
;	[xc,yc] = Grid::Slot2screen, slot  ; returns the coordinates of given
;	                                     slot
;	retstat = Grid::Put, Module, slot  ; puts module into given slot
;	Module = Grid::GetModule, slot	   ; returns module in given slot
;	Module = Grid::Remove, slot	   ; Remove module from given slot
;
;T+
; \subsubsection{Method: {\tt INIT}}
;
; The INIT method initializes a GRID object with a given number of slots
; in X and Y directions. If the numbers are not provided in the call a suitable
; default is assumed.
;
; \noindent
; {\bf Note:} Slot numbers are couples {\tt [x,y]} with x increasing from left
; to right and {\tt y} increasing from top to bottom. The upper left slot is
; numberd {\tt [0,0]}.
;
;T-

FUNCTION Grid::INIT, Xslots, Yslots

COMMON GenDims, ModWidth, ModHeigth, Slotspace

ModWidth=50
ModHeigth=30
SlotSpace=20

IF(self->IDLgrModel::INIT() NE 1) THEN RETURN, 0

self.Xslots=Xslots
self.Yslots=Yslots
self.Xstart=SlotSpace
self.Xspace=ModWidth
self.Xstep=self.Xspace+self.Xstart
self.Ystart=Yslots*(SlotSpace+ModHeigth)
self.Yspace=Modheigth
self.Ystep= SlotSpace+ModHeigth
self.Xsize= Xslots*self.Xstep+self.Xstart
self.Ysize= Yslots*self.Ystep+SlotSpace

Yvert =  [self.Ystart, self.Ysize-self.Ystart]

self.Slots=PTR_NEW(OBJARR(self.Xslots,self.Yslots))
self.HConnect=PTR_NEW(INTARR(self.Yslots))
self.VConnect=PTR_NEW(INTARR(self.Xslots))

self.myColor = [200,200,200]

FOR i=0, self.Xslots-1 DO BEGIN			; Draw Boxes
	    x0 = self.Xstart+i*self.Xstep
	    x1 = x0+self.Xspace
	    FOR j=0, self.Yslots-1 DO BEGIN
		    y0 = self.Ystart-j*self.Ystep
		    y1 = y0-self.Yspace

		    box = OBJ_NEW( 'IDLgrPolygon',           $
				   [x0, x1, x1, x0],    $ ; X coords
				   [y0, y0, y1, y1],    $ ; Y coords
				   COLOR=self.myColor,  $
				   STYLE=1,             $
				   LINESTYLE = 0          )
		    self->add, box
	    ENDFOR
ENDFOR

RETURN, 1
END

;T+
; \subsubsection{Method: {\tt GetSize}}
;
; This function returns the size of the grid. The value returned is a four
; elements integer array which gives both sizes in screen coordinates and
; in number of slots.
;
;T-

FUNCTION Grid::GetSize

RETURN, [self.Xsize, self.Ysize, self.Xslots, self.Yslots]

END

;T+
; \subsubsection{Method: {\tt EnclosingBox}}
;
; The following function returns the coordinates (in screen units) of a
; given rectangular subset of the grid slots.
;
;T-

FUNCTION Grid::EnclosingBox, PrjBox	; Returns coordinates of Box enclosing
					; the given slot box

xy1 = self->Slot2screen([PrjBox[0],PrjBox[2]])
xy2 = self->Slot2screen([PrjBox[1],PrjBox[3]])

RETURN, [xy1[0], xy2[0]+self.Xspace, xy1[1]+self.Yspace, xy2[1]]

END

;T+
; \subsubsection{Method: {\tt Screen2slot}}
;
; The following function returns the slot number of the grid slot
; containing the given screen point. The function returns {\tt [-1,-1]}
; if the point is not contained in any slot.
;
;T-

FUNCTION Grid::Screen2slot, xy		; returns the Number of the slot
					; containing given point

xslot=FLOOR((xy[0]-self.Xstart)/self.Xstep)

IF xslot GE self.Xslots THEN RETURN, [-1, -1]
IF xslot LT 0.0         THEN RETURN, [-1, -1]

rel = (xy[0]-self.Xstart) MOD self.Xstep

IF rel GT self.Xspace THEN RETURN, [-1, -1]

yslot=FLOOR((self.Ystart-xy[1])/self.Ystep)

IF yslot LT 0.0         THEN RETURN, [-1, -1]
IF yslot GE self.Yslots THEN RETURN, [-1, -1]

rel = (self.Ystart-xy[1]) MOD self.Ystep
IF rel GT self.Yspace THEN RETURN, [-1, -1]

RETURN, [xslot,yslot]

END


;T+
; \subsubsection{Method: {\tt Slot2screen}}
;
; The following function returns the coordinates of the lower
; left corner of given slot.
;
;T-

FUNCTION Grid::Slot2screen, slot	; returns the coordinates of the 
					    ; lower left point of given slot

IF slot[0] LT 0 OR slot[0] GE self.Xslots THEN RETURN, [-1, -1]
IF slot[1] LT 0 OR slot[1] GE self.Yslots THEN RETURN, [-1, -1]

x = slot[0]*self.Xstep + self.Xstart
y = self.Ysize - (slot[1]+1)*self.Ystep

RETURN, [x, y]

END


;T+
; \subsubsection{Method: {\tt Put}}
;
; The following function puts a module into a given slot
;
;T-

FUNCTION Grid::Put, Module, slot		; Put module into given slot
						; return 1 on success

IF (*self.Slots)[slot[0], slot[1]] NE OBJ_NEW() THEN BEGIN
	    r=DIALOG_MESSAGE('Slot is not empty')
	    RETURN, 0
ENDIF
	    
xy = self->Slot2screen(slot)
offst = xy - Module.myPos
Module.mySlot = slot

Module.Graph.Model->Translate, offst[0], offst[1], 0.0

(*self.Slots)[slot[0],slot[1]] = Module

RETURN, 1
END

;T+
; \subsubsection{Method: {\tt GetModule}}
;
; The following function returns the module contained in given slot.
;
; \noindent
; {\bf Note:} Empty slots are ``filled'' with {\tt NULL} objects, so if
; the object returned is {\tt OBJ\_NEW()}, the slot is empty.
;
;T-

FUNCTION Grid::GetModule, slot		; returns the module
					; in given slot

theObj = (*self.Slots)[slot[0],slot[1]]

RETURN, theObj

END

;T+
; \subsubsection{Method: {\tt Remove}}
;
; The following function removes a module from a slot. It returns
; the module object just removed.
;
;T-

FUNCTION Grid::Remove, slot			; Remove module from given slot
						    ; returns the module removed
theObj = (*self.Slots)[slot[0],slot[1]]
IF theObj NE OBJ_NEW() THEN BEGIN

	    offst = -1 * theObj.myPos

	    theObj.Graph.Model->Translate, offst[0], offst[1], 0.0
	    theObj.myPos=[0,0]
	    theObj.mySlot= [-1,-1]
	    (*self.Slots)[slot[0],slot[1]] = OBJ_NEW()

ENDIF

RETURN, theObj

END


;T+
;
; \subsubsection{Method: {\tt Cleanup}}
;
;T-

PRO Grid::Cleanup

self->IDLgrModel::Cleanup

END

;T+
; \subsubsection{Data Structure}
;
; The following procedure is the required structure definition for the grid
; object.
; 
;T-


PRO Grid__define			; Grid data structure definition

struct = { Grid, INHERITS IDLgrModel,   $
                Xslots:0,               $
                Yslots:0,               $
                Xstart:0,               $
                Xspace:0,               $
                Xstep:0,                $
                Xsize:0,                $
                Ystart:0,               $
                Yspace:0,               $
                Ystep:0,                $
                Ysize:0,                $
                Slots:PTR_NEW(),        $
                Hconnect:PTR_NEW(),     $
                Vconnect:PTR_NEW(),     $
                myColor:[0,0,0]       }

END
