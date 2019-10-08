IMPORT FGL g2_lib
&include "schema.inc"

PUBLIC DEFINE m_user RECORD LIKE sys_users.*

--------------------------------------------------------------------------------
#+ set the m_user record from passed email or key - preference is email
#+
#+ @param l_key the key for the user or NULL to default to ARG 2
#+ @param l_email the users email address
FUNCTION getUser(l_key LIKE sys_users.user_key, l_email LIKE sys_users.email) RETURNS()

  IF l_email IS NOT NULL THEN
    SELECT * INTO m_user.* FROM sys_users WHERE email = l_email
    IF STATUS = NOTFOUND THEN
      CALL g2_lib.g2_errPopup(SFMT(% "Invalid User Email '%1'!", l_email))
      CALL g2_lib.g2_exitProgram(1, SFMT("Invalid User Email '%1'!", l_email))
    ELSE
      RETURN
    END IF
  END IF

  IF l_key IS NULL OR l_key = 0 THEN
    LET l_key = arg_val(2)
  END IF
  IF l_key IS NULL OR l_key = 0 THEN
    CALL g2_lib.g2_exitProgram(1, "Invalid User Id passed")
  END IF

  SELECT * INTO m_user.* FROM sys_users WHERE user_key = l_key
  IF STATUS = NOTFOUND THEN
    CALL g2_lib.g2_errPopup(SFMT(% "Invalid User Key '%1'!", l_key))
    CALL g2_lib.g2_exitProgram(1, SFMT("Invalid User Key '%1'!", l_key))
  END IF
END FUNCTION
--------------------------------------------------------------------------------
#+ The users full name
FUNCTION getUserName() RETURNS STRING
  IF m_user.surname IS NULL THEN
    CALL getUser(NULL, NULL)
  END IF
  RETURN getFullName(m_user.salutation, m_user.forenames, m_user.surname)
END FUNCTION
--------------------------------------------------------------------------------
#+ The users full name
FUNCTION getFullName(l_sal STRING, l_for STRING, l_sur STRING) RETURNS STRING
  DEFINE l_fullname STRING
  IF l_sal IS NOT NULL AND l_sal != " " THEN
    LET l_fullname = l_sal.trim(), " ", l_for.trim(), " ", l_sur.trim()
  ELSE
    LET l_fullname = l_for.trim(), " ", l_sur.trim()
  END IF
  RETURN l_fullname
END FUNCTION
--------------------------------------------------------------------------------
#+ Check the user has the role
#+
#+ @param l_user_key Users Serial key
#+ @param l_role Role Name
#+ @param l_verb TRUE=Verbose error FALSE=silent
FUNCTION checkUserRoles(l_user_key, l_role, l_verb) RETURNS BOOLEAN
  DEFINE l_user_key LIKE sys_users.user_key
  DEFINE l_user LIKE sys_users.surname
  DEFINE l_role LIKE sys_roles.role_name
  DEFINE l_role_key LIKE sys_roles.role_key
  DEFINE l_verb BOOLEAN
  DEFINE l_u_act LIKE sys_users.active
  DEFINE l_r_act, l_ur_act CHAR(1)
  DEFINE l_err STRING

  DISPLAY "checkUserRoles U:", l_user_key, " r:", l_role

  SELECT u.active, u.surname INTO l_u_act, l_user FROM sys_users u WHERE u.user_key = l_user_key
  IF STATUS = NOTFOUND THEN
    LET l_err = SFMT(% "User key '%1' not found!", l_user_key)
    CALL g2_lib.g2_errPopup(l_err)
    RETURN FALSE
  END IF
  IF NOT l_u_act THEN
    LET l_err = SFMT("User '%1' not active!", l_user)
    IF l_verb THEN
      CALL g2_lib.g2_errPopup(l_err)
    END IF
    RETURN FALSE
  END IF

  SELECT r.active, role_key INTO l_r_act, l_role_key FROM sys_roles r WHERE r.role_name = l_role
  IF STATUS = NOTFOUND THEN
    LET l_err = SFMT("Role '%1' not found!", l_role)
    CALL g2_lib.g2_errPopup(l_err)
    RETURN FALSE
  END IF
  IF l_r_act != "Y" THEN
    LET l_err = SFMT("Role '%1' not longer active!", l_role)
    IF l_verb THEN
      CALL g2_lib.g2_errPopup(l_err)
    END IF
    RETURN FALSE
  END IF
  DISPLAY "checkUserRoles U:", l_u_act, ":", l_user, " R:", l_r_act

  SELECT ur.active
      INTO l_ur_act
      FROM sys_user_roles ur
      WHERE ur.user_key = l_user_key AND ur.role_key = l_role_key
  IF STATUS = NOTFOUND THEN
    IF l_verb THEN
      LET l_err =
          SFMT(% "You don't have permission to do that\nPlease contact your system administrator\nRole:",
              l_role)
      CALL g2_lib.g2_errPopup(l_err)
    END IF
    RETURN FALSE
  END IF
  DISPLAY "checkUserRoles UR:", l_ur_act

  IF NOT l_ur_act THEN
    LET l_err = SFMT(% "Role '%1' not active for this user!", l_role)
    IF l_verb THEN
      CALL g2_lib.g2_errPopup(l_err)
    END IF
    RETURN FALSE
  END IF

  RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION toggle(l_var CHAR(1)) RETURNS CHAR(1)
  IF l_var = "Y" THEN
    RETURN "N"
  END IF
  RETURN "Y"
END FUNCTION
--------------------------------------------------------------------------------
-- Setup actions based on a allowed actions
FUNCTION setActions(l_row INT, l_max INT, l_allowedActions CHAR(6)) RETURNS()
  DEFINE d ui.Dialog
&define ACT_FIND l_allowedActions[1]
&define ACT_LIST l_allowedActions[2]
&define ACT_UPD l_allowedActions[3]
&define ACT_INS l_allowedActions[4]
&define ACT_DEL l_allowedActions[5]
&define ACT_SAM l_allowedActions[6]
  LET d = ui.Dialog.getCurrent()
  IF ACT_FIND = "N" THEN
    CALL d.setActionActive("find", FALSE)
  END IF
  IF ACT_LIST = "N" THEN
    CALL d.setActionActive("list", FALSE)
  END IF
  IF ACT_UPD = "N" THEN
    CALL d.setActionActive("update", FALSE)
  END IF
  IF ACT_INS = "N" THEN
    CALL d.setActionActive("insert", FALSE)
  END IF
  IF ACT_DEL = "N" THEN
    CALL d.setActionActive("delete", FALSE)
  END IF
  --IF ACT_SAM = "N" THEN CALL d.setActionActive("sample",FALSE) END IF
  IF l_max > 1 THEN
    IF ACT_UPD = "Y" THEN
      CALL d.setActionActive("update", TRUE)
    END IF
    IF ACT_DEL = "Y" THEN
      CALL d.setActionActive("delete", TRUE)
    END IF
  ELSE
    IF ACT_UPD = "Y" THEN
      CALL d.setActionActive("update", FALSE)
    END IF
    IF ACT_DEL = "Y" THEN
      CALL d.setActionActive("delete", FALSE)
    END IF
  END IF
  IF l_row > 0 AND l_row < l_max THEN
    CALL d.setActionActive("nextrow", TRUE)
    CALL d.setActionActive("lastrow", TRUE)
  ELSE
    CALL d.setActionActive("lastrow", FALSE)
    CALL d.setActionActive("nextrow", FALSE)
  END IF
  IF l_row > 1 THEN
    CALL d.setActionActive("prevrow", TRUE)
    CALL d.setActionActive("firstrow", TRUE)
  ELSE
    CALL d.setActionActive("prevrow", FALSE)
    CALL d.setActionActive("firstrow", FALSE)
  END IF

END FUNCTION
--------------------------------------------------------------------------------
