# Locutus

Still in v0.x. Use at your own risk Ammar. When i think it is ready to be used i will make a v1.0 release.

Cleaned up version of my data and gmail backup script. 

Built ontop of
* rsync
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
 3) chmod +x "locutus.sh"
 4) Run locutus.sh as per any other .sh file
 
# Disclaimer 
THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
