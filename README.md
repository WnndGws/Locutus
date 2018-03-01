# Locutus

NB. THIS SCRIPT IS CURRENTLY UNFINISHED. THE BARE BONES ARE THERE BUT I HAVE NOT HAD TIME/MOTIVATION TO FINISH IT.

Still in v0.x. Use at your own risk. When I think it is ready to be used I will make a v1.0 release.

Cleaned up version of my data and gmail backup script. 

Built ontop of
* duplicity
* gmvault
* aconfmgr
* megasync

# How to use

This is a bash script and runs as such. 
Step to use:

 1) Edit the configuration section at the beginning of file "locutus.sh" using your favourite text editor
 2) Create a .passwords file using the .passwords.example as a template
    * NB! This file contains SENSITIVE INFORMATION. That is why it is imperative that you encrypt it using gpg
    * Minimum suggested: "gpg -ea .passwords.txt"
    * Shred original file before removing it using "shred" in terminal
    * This process should leave you with a file ".passwords.asc" which you need to reference in the config section of locutus
 3) chmod +x "locutus.sh"
 4) Run locutus.sh as per any other .sh file
 
# Disclaimer 
This software is provided by the author "as is" and any express or implied warranties, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose are disclaimed. In no event shall the author be liable for any direct, indirect, incidental, special, exemplary, or consequential damages (including, but not limited to, procurement of substitute goods or services; loss of use, data, or profits; or business interruption) however caused and on any theory of liability, whether in contract, strict liability, or tort (including negligence or otherwise) arising in any way out of the use of this software, even if advised of the possibility of such damage.
