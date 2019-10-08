#+ A simple container program for MDI

MAIN
  DEFINE l_children SMALLINT
  CALL ui.Interface.loadStyles("container") --"||UPSHIFT(ui.interface.getFrontEndName()))

  CALL ui.Interface.setType("container")
  CALL ui.Interface.setName("container")

--	CALL ui.Interface.loadToolBar("container")
  CALL ui.Interface.loadStartMenu("container") -- required for GBC!!!

  CALL ui.Interface.setText("Container 1.2")
  OPEN FORM f FROM "container"
  DISPLAY FORM f

  MENU
    ON ACTION close
      DISPLAY "Check for children!"
      LET l_children = childCount()
      IF l_children > 0 THEN
        CALL fgl_winMessage(
            "Warning", SFMT("Must close the %1 child programs first!", l_children), "exclamation")
        CONTINUE MENU
      END IF
      EXIT MENU
  END MENU
END MAIN
--------------------------------------------------------------------------------
FUNCTION childCount()
{
  DEFINE l_num STRING
  IF ui.interface.getFrontEndName() = "GBC" THEN
    CALL ui.Interface.frontCall("mymodule", "appcount", [], [l_num])
    LET l_num = l_num - 1 -- the gbc count includes the container!
  ELSE
}
    RETURN ui.Interface.getChildCount()
{
  END IF
  RETURN l_num
}
END FUNCTION
