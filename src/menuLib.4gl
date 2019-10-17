IMPORT os
IMPORT FGL g2_lib
IMPORT FGL g2_about
IMPORT FGL g2_appInfo
IMPORT FGL lib_login

&include "schema.inc"

CONSTANT C_RESOURCEPATHLIST = "../resources/resourcePath.txt"
CONSTANT C_IMAGEPATHLIST = "../resources/imagePath.txt"
PUBLIC DEFINE m_curMenu SMALLINT
PUBLIC DEFINE m_args STRING

DEFINE m_menu DYNAMIC ARRAY OF RECORD
  menu_key LIKE sys_menus.menu_key,
  m_id LIKE sys_menus.m_id,
  m_pid LIKE sys_menus.m_pid,
  m_type LIKE sys_menus.m_type,
  m_text LIKE sys_menus.m_text,
  m_item LIKE sys_menus.m_item,
  m_passw LIKE sys_menus.m_passw,
  m_img STRING
END RECORD
DEFINE m_menus DYNAMIC ARRAY OF VARCHAR(6)
DEFINE m_prf STRING
DEFINE m_useUR BOOLEAN
--------------------------------------------------------------------------------
FUNCTION do_menu(l_logo STRING, l_appInfo g2_appInfo.appInfo INOUT)
	DEFINE l_form ui.Form
  WHENEVER ANY ERROR CALL g2_lib.g2_error
  OPEN WINDOW w_menu WITH FORM "menu"
	LET l_form = ui.Window.getCurrent().getForm()
	LET m_prf = "FGLPROFILE="||fgl_getEnv("FGLPROFILE")
	LET m_useUR = FALSE
	IF m_prf.getIndexOf(".ur",1) > 1 THEN
		LET m_useUR = TRUE
		CALL l_form.setElementImage("renderer_toggle","fa-toggle-on")
	END IF
	IF NOT m_isGDC OR  m_prf.getIndexOf("profile.",1) = 0 THEN -- not got .nat or .ur on FGLPROFILE!
		CALL l_form.setElementHidden("renderer_toggle", TRUE)
		CALL l_form.setElementHidden("l_renderer", TRUE)
	END IF

  DISPLAY l_logo TO logo
  CALL ui.Interface.setText(l_appInfo.progDesc)

  LET m_curMenu = 1
  LET m_menus[m_curMenu] = "main"
  IF NOT populate_menu(m_menus[m_curMenu]) THEN -- should not happen!
    CALL g2_lib.g2_exitProgram(0, "'main' menu not found!")
  END IF

  DISPLAY l_appInfo.userName TO userName

  WHILE NOT int_flag
    DISPLAY CURRENT, ":Dialog Started."

    DISPLAY ARRAY m_menu TO menu.* ATTRIBUTE(FOCUSONFIELD, CANCEL = FALSE, ACCEPT = FALSE)
      BEFORE DISPLAY
        IF m_curMenu > 1 THEN
          CALL DIALOG.setActionActive("back", TRUE)
        ELSE
          CALL DIALOG.setActionActive("back", FALSE)
        END IF

      BEFORE FIELD m_text
        IF m_menu[arr_curr()].m_text IS NOT NULL THEN
          EXIT DISPLAY
        ELSE
          NEXT FIELD m_type
        END IF

			ON ACTION about
				CALL g2_about.g2_about(l_appInfo)

      ON ACTION logout
        CALL lib_login.logout()
        IF quit() THEN
          LET int_flag = TRUE
          EXIT DISPLAY
        END IF

      ON ACTION close
        IF quit() THEN
          LET int_flag = TRUE
          EXIT DISPLAY
        END IF

			ON ACTION renderer_toggle
				LET m_useUR = NOT m_useUR
				IF m_useUR THEN
					CALL swap_nat_ur( "ur" )
					CALL l_form.setElementImage("renderer_toggle","fa-toggle-on")
				ELSE
					CALL swap_nat_ur( "nat" )
					CALL l_form.setElementImage("renderer_toggle","fa-toggle-off")
				END IF

      ON ACTION back
        DISPLAY CURRENT, ":BACK m_curMenu:", m_curMenu
        IF m_curMenu > 1 THEN
          IF populate_menu(m_menus[m_curMenu - 1]) THEN
            LET m_curMenu = m_curMenu - 1
          END IF
          IF m_curMenu = 1 THEN
            CALL DIALOG.setActionActive("back", FALSE)
          END IF
        END IF

    END DISPLAY
    IF NOT int_flag THEN
      CALL process_menu_item(arr_curr())
    END IF
  END WHILE

  CLOSE WINDOW w_menu
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION process_menu_item(x SMALLINT)
  DEFINE l_cmd, l_prog, l_args STRING

  DISPLAY CURRENT, ":Process_menu_item:" || x || ":", m_menu[x].m_type || "-" || m_menu[x].m_text

  CASE m_menu[x].m_type
    WHEN "C"
      CASE m_menu[x].m_item
        WHEN "quit"
          IF quit() THEN
            LET int_flag = TRUE
            RETURN
          END IF

        WHEN "back"
          IF m_curMenu > 1 AND populate_menu(m_menus[m_curMenu - 1]) THEN
            LET m_curMenu = m_curMenu - 1
          END IF
      END CASE

    WHEN "F" -- Run a standard 42r - with defaults args
      CALL progArgs(m_menu[x].m_item) RETURNING l_prog, l_args
			LET l_cmd = SFMT("%1 fglrun %2 %3 %4",  m_prf, l_prog, m_args, l_args)
      IF NOT os.path.exists(l_prog) THEN
        CALL g2_lib.g2_errPopup(SFMT(% "This program '%1' appears to not be installed!", l_prog))
      END IF
			CALL run_withoutWaiting( l_cmd )

    WHEN "S" -- Run a simple 42r - no args
      IF NOT os.path.exists(m_menu[x].m_item) THEN
        CALL g2_lib.g2_errPopup(
            SFMT(% "This program '%1' appears to not be installed!", m_menu[x].m_item))
      END IF 
			LET l_cmd = SFMT("fglrun %1", m_menu[x].m_item )
			CALL run_withoutWaiting( l_cmd )

    WHEN "P"
      CALL progArgs(m_menu[x].m_item) RETURNING l_prog, l_args
			LET l_cmd = SFMT("%1 %2", l_prog, l_args )
			CALL run_withoutWaiting( l_cmd )

    WHEN "O"
			CALL run_withoutWaiting( m_menu[x].m_item )

    WHEN "M"
      LET m_menus[m_curMenu + 1] = m_menu[x].m_item
      IF populate_menu(m_menus[m_curMenu + 1]) THEN
        LET m_curMenu = m_curMenu + 1
      END IF
  END CASE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION populate_menu(l_mname LIKE sys_menus.m_id) RETURNS BOOLEAN
  DEFINE l_role_name LIKE sys_roles.role_name
  DEFINE l_prev_key LIKE sys_menus.menu_key
  DEFINE l_titl LIKE sys_menus.m_text

  DISPLAY CURRENT, ": Menu:", l_mname, " m_curMenu:", m_curMenu
  SELECT m_text INTO l_titl FROM sys_menus WHERE m_id = l_mname AND m_type = "T"
  IF STATUS = NOTFOUND THEN
    DISPLAY "Menu:" || l_mname || " not found!"
    RETURN FALSE
  END IF
  DISPLAY BY NAME l_titl;

  CALL m_menu.clear()
  DECLARE cur CURSOR FOR
      SELECT sys_menus.*, sys_roles.role_name
          FROM sys_menus --OUTER(sys_menu_roles,sys_roles)
                  LEFT OUTER
                  JOIN sys_menu_roles
                  ON sys_menu_roles.menu_key = sys_menus.menu_key
              LEFT OUTER
              JOIN sys_roles
              ON sys_menu_roles.role_key = sys_roles.role_key
          WHERE m_id = l_mname AND m_type != "T"
          ORDER BY sys_menus.menu_key

  LET l_prev_key = -1
  FOREACH cur INTO m_menu[m_menu.getLength() + 1].*, l_role_name
    IF l_role_name IS NOT NULL THEN
      IF m_menu[m_menu.getLength()].menu_key = l_prev_key THEN
        CALL m_menu.deleteElement(m_menu.getLength())
        CONTINUE FOREACH
      END IF
      LET l_prev_key = m_menu[m_menu.getLength()].menu_key
    END IF
    CASE m_menu[m_menu.getLength()].m_type
      WHEN "C"
        LET m_menu[m_menu.getLength()].m_img = "quit"
      WHEN "M"
        LET m_menu[m_menu.getLength()].m_img = "fa-angle-double-right"
      WHEN "P"
        LET m_menu[m_menu.getLength()].m_img = "fa-cog"
      WHEN "F"
        LET m_menu[m_menu.getLength()].m_img = "fa-cog"
      WHEN "S"
        LET m_menu[m_menu.getLength()].m_img = "fa-cog"
    END CASE
  END FOREACH
  LET m_menu[m_menu.getLength()].m_type = "C"
  LET m_menu[m_menu.getLength()].m_text = "Back"
  LET m_menu[m_menu.getLength()].m_item = "back"
  LET m_menu[m_menu.getLength()].m_img = "fa-angle-double-left"
  IF m_menu[m_menu.getLength() - 1].m_pid IS NULL THEN
    LET m_menu[m_menu.getLength()].m_text = "Quit"
    LET m_menu[m_menu.getLength()].m_item = "quit"
    LET m_menu[m_menu.getLength()].m_img = "quit"
  END IF
  RETURN TRUE

END FUNCTION
--------------------------------------------------------------------------------
-- split program and args to two variables
FUNCTION progArgs(l_prog STRING) RETURNS(STRING, STRING)
  DEFINE l_args STRING
  DEFINE y SMALLINT
  LET y = l_prog.getIndexOf(" ", 1)
  LET l_args = " "
  IF y > 0 THEN
    LET l_args = l_prog.subString(y, l_prog.getLength())
    LET l_prog = l_prog.subString(1, y - 1)
  END IF
  IF l_args IS NULL THEN
    LET l_args = " "
  END IF
  DISPLAY "l_prog:", l_prog, " l_args:", l_args
  RETURN l_prog, l_args
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION quit() RETURNS BOOLEAN
  IF ARG_VAL(1) = "MDI" THEN
    IF ui.Interface.getChildCount() > 0 THEN
      CALL g2_lib.g2_warnPopup(% "Must close child windows first!")
      RETURN FALSE
    END IF
  END IF
  RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION run_withoutWaiting(l_cmd STRING)
  CALL g2_lib.g2_log.logit("RUN: "||NVL(l_cmd,"NULL!"))
	RUN l_cmd WITHOUT WAITING
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION swap_nat_ur(l_renderer STRING) RETURNS ()
	DEFINE x SMALLINT
	LET x = m_prf.getIndexOf("profile.",1)
	IF x < 1 THEN RETURN END IF
	LET m_prf = m_prf.subString(1,x-1)||"profile."||l_renderer
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION setResourcePath() RETURNS ()
	DEFINE l_pathList STRING
	DEFINE l_c base.Channel
	IF NOT os.path.exists(C_RESOURCEPATHLIST) THEN RETURN END IF
	LET l_c = base.Channel.create()
	CALL l_c.openFile(C_RESOURCEPATHLIST,"r")
	WHILE NOT l_c.isEof()
		LET l_pathList = l_pathList.append( l_c.readLine())||os.path.pathSeparator()
	END WHILE
	DISPLAY "ResourcePath:",l_pathList
	CALL fgl_setEnv("FGLRESOURCEPATH", l_pathList)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION setImagePath() RETURNS ()
	DEFINE l_pathList STRING
	DEFINE l_defFontList STRING
	DEFINE l_c base.Channel
	IF NOT os.path.exists(C_IMAGEPATHLIST) THEN RETURN END IF
	LET l_c = base.Channel.create()
	CALL l_c.openFile(C_IMAGEPATHLIST,"r")
	WHILE NOT l_c.isEof()
		LET l_pathList = l_pathList.append( l_c.readLine())||os.path.pathSeparator()
	END WHILE
	LET l_defFontList = os.path.join("lib","image2font.txt")
	LET l_pathList = l_pathList.append( os.path.join(fgl_getEnv("FGLDIR"),l_defFontList))
	DISPLAY "ImagePath:",l_pathList
	CALL fgl_setEnv("FGLIMAGEPATH", l_pathList)
END FUNCTION
