# trust-line-ios [Work in progress]
trust line iOS app

On going dev. Do not use yet unless you know what you're doing.


------------------

#### Pairing procedure

![](https://github.com/amoriello/trust-line-ios/raw/develop/demos/demo_pairing.gif)

This is the first view. You only need to go through this step once.

- You need to connect the token to a power source, like a USB port.
- Make sure the bluetooth is enabled
- Push the pair button (central) in order to start the paring procedure
- The trustline secrets are the token secrets keys. They are represented in the form of a QR Code to be printed.
This is a critical piece of information. This QRCode can decrypt your password, so keep it somewhere safe. Note that Airprint feature will be added soon.

------------------

#### Create a new password

![](https://github.com/amoriello/trust-line-ios/raw/develop/demos/demo_create_password.gif)

- Create a new account (Will contain a title, an optional login, and your password (encrypted version)
- You can also specify your login, and a size (strength) for your password
- Note that login is optional
- Also note that neihter the account name, nor the login are encrypted by default (see #4)
- the account is saved on the phone, and synchronized via iCloud (if activated)

------------------
#### Send keystrokes

![](https://github.com/amoriello/trust-line-ios/raw/develop/demos/demo_keyboard.gif)

When your token is connected to a computer via USB port, it simulates a HID keyboard :
- Sliding a row from left to rigth will send the encrypted password to the token, and ask the token to type it.
- The token will decrypt the password and type it where your focus is
- When the color is green : release the row, then the password is typed
- When the color is yellow (further green) : release the row, then the password is typed, followed by "ENTER"


------------------

More features to come
