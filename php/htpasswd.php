<?php

/**
 * Settings
 */
$str_auth_file = '/home/jasper/htpasswd';
$int_min_pass = 5;

/**
 * Default values
 */
$str_sys_call = 'htpasswd -b';
$str_pass = '';
$bln_pass_changed = false;
$str_error = '';

/**
 * User input
 */
$str_oldpass1 = escapeshellarg($_POST['password0']);
$str_oldpass2 = escapeshellarg($_SERVER['PHP_AUTH_PW']);

$str_pass1 = ($_POST['password1']);
$str_pass2 = ($_POST['password2']);
if (!empty ($_SERVER['PHP_AUTH_USER'])) {
	if ($_SERVER['REQUEST_METHOD'] == 'POST') {
		$bln_post = true;
		if (!empty ($str_auth_file) and is_file($str_auth_file) and is_writable($str_auth_file)) {
			if ($str_oldpass1 === $str_oldpass2) {
				if ($str_pass1 === $str_pass2) {
					$str_pass = $str_pass1;
					if (strlen($str_pass) >= $int_min_pass) {
						$str_sys_call = $str_sys_call . ' ' . $str_auth_file . ' ' . $_SERVER['PHP_AUTH_USER'] . ' ' . $str_pass;
						shell_exec($str_sys_call);
						$bln_pass_changed = true;
					} else {
						$str_error = 'Wachtwoord moet minimaal ' . $int_min_pass . 'karakters zijn.<br />';
					}
				} else {
					$str_error = 'ww1+2 matchen niet<br />';
				}
			} else {
				$str_error = 'Oude pass klopt niet<br />';
			}
		} else {
			$str_error = 'Geen pass-file of niet writable<br />';
		}
	} else {

	}
} else {
	echo 'U zit niet in een realm<br />';
	die();
}
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<title>htpasswd password changer</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body onload="onLoad()">

<script type="text/javascript">
	function onLoad() {
		document.getElementById('password0').focus();
	}
</script>

<p>U bent ingelogd als <b><?php echo $_SERVER['PHP_AUTH_USER']; ?></b></p>

<?php if (!$bln_pass_changed) { ?>

<?php if (!empty($str_error)) { ?>
<div style="color:red"><?php echo $str_error; ?><br /></div>
<?php } ?>


<form action="htpasswd.php" method="post">
<div>
<table>
<tr>
	<td>Oude wachtwoord</td>
	<td><input type="password" name="password0" id="password0" value="" /></td>
</tr>
<tr>
	<td>Nieuw 1/2</td>
	<td><input type="password" name="password1" id="password1"  value="" /></td>
</tr>
<tr>
	<td>Nieuw 2/2</td>
	<td><input type="password" name="password2" id="password2"  value="" /></td>
</tr>
<tr>
	<td></td>
	<td><input type="submit" value="Wijzig wachtwoord" /></td>
</tr>
</table>
</div>
</form>
<?php } else { ?>
<p>Uw wachtwoord is gewijzigd, klik <a href="htpasswd.php">hier</a> om opnieuw in te loggen</p>
<?php } ?>

</body>
</html>