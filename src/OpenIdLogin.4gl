
IMPORT util
IMPORT os

&include "OpenIdLogin.inc"

MAIN
	DEFINE l_oidc t_oidc
	DEFINE l_store, l_user STRING

	CALL ui.Interface.loadStyles("OpenIdLogin")

	OPEN FORM frm FROM "OpenIdLogin"
	DISPLAY FORM frm

	LET l_oidc.email = fgl_getEnv("OIDC_EMAIL")
	LET l_oidc.family = fgl_getEnv("OIDC_FAMILY_NAME")
	LET l_oidc.given  = fgl_getEnv("OIDC_GIVEN_NAME")
	LET l_oidc.idp_issuer  = fgl_getEnv("OIDC_IDP_ISSUER")
	LET l_oidc.idp_token_endpoint  = fgl_getEnv("OIDC_IDP_TOKEN_ENDPOINT")
	LET l_oidc.name  = fgl_getEnv("OIDC_NAME")
	LET l_oidc.picture  = fgl_getEnv("OIDC_PICTURE")
	LET l_oidc.profile  = fgl_getEnv("OIDC_PROFILE")
	LET l_oidc.sub  = fgl_getEnv("OIDC_SUB")
	LET l_oidc.token_expires_in  = fgl_getEnv("OIDC_TOKEN_EXPIRES_IN")
	LET l_oidc.userinfo_endpoint  = fgl_getEnv("OIDC_USERINFO_ENDPOINT")

	LET l_user = NVL(l_oidc.name,l_oidc.email)

	IF l_oidc.email IS NULL THEN
--		DISPLAY "Invalid Login" TO name
		DISPLAY "homer-doh_Login.png" TO img
		CALL dumpEnv()
	ELSE
		DISPLAY "Welcome "||NVL(l_user,"Unknown User!") TO name
		DISPLAY l_oidc.picture TO img
		DISPLAY "Login Okay:",l_oidc.email
	END IF

--	CALL dumpEnv() -- just for testing.

	LET l_store = util.JSONObject.fromFGL( l_oidc ).toString()
	CALL logIt( l_store )
	CALL ui.Interface.frontCall("localStorage", "setItem", ["openid", l_store], [])

	MENU "OpenIdLogin"
		ON ACTION close EXIT MENU
		ON ACTION exit EXIT MENU
		ON IDLE 20 EXIT MENU
	END MENU

END MAIN
--------------------------------------------------------------------------------
-- yyyy/mm/dd hh:mm:ss fffff
-- 1234567890123456789012345
FUNCTION logIt(l_str STRING)
	DEFINE l_file STRING
	DEFINE l_txt TEXT
	DEFINE l_dte CHAR(25)
	LET l_dte = CURRENT

	DISPLAY l_str
	LET l_file = os.path.join("..","logs")
	IF NOT os.path.exists(l_file) THEN
		IF NOT os.path.mkdir(l_file) THEN
			DISPLAY "Log file dir failed to create!"
			RETURN
		END IF
	END IF
	DISPLAY "Log to: ",l_file
	LET l_file = os.path.join(l_file, SFMT("%1%2%3_%4%5%6.log", l_dte[1,4], l_dte[6,7], l_dte[9,10], l_dte[12,13], l_dte[15,16], l_dte[18,19]))

	LOCATE l_txt IN FILE l_file
	LET l_txt = l_str
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION dumpEnv()
	DEFINE c base.channel
	DEFINE l_line STRING
	LET c = base.Channel.create()

	DISPLAY "----------Environment---------"
	CALL c.openPipe("env | sort", "r")
	WHILE NOT c.isEof()
		LET l_line = c.readLine()
		IF l_line.getLength() > 1 THEN
			DISPLAY "Env: "||l_line
		END IF
	END WHILE
	CALL c.close()

END FUNCTION
--------------------------------------------------------------------------------
