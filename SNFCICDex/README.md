# SFexecute
Executing local SQL scripts in your Snowflake account

## Disclaimer
This is a script mainly constructed from stuff I found on Stackoverflow.

Modifications have been made using CoPilot

## Updates
Sep-24: added the option to specify a folder parameter

## Config

Adding your account details to the config file:

For trial accounts: on the line "account": 

-> from the "welcome to Snowflake" e-mail for your trial account

Add the Dedicated Login URL to your "account" 

-> and then especially the part between :// and .snow

## How to execute (in the background)
nohup python main_folder.py ./cost 0 &

### What does the command do
nohup: execute without being cancelled when the terminal window is closed

./cost: the folder that needs to be executed

0: Show successful statements (1 for yes, 0 for no)

&: Run in the background
