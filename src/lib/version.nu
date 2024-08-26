use meta.nu [NAME, VERSION, GIT_COMMIT]
# Display nuspawn version
export def "main version" [] {
  $"($NAME) ($VERSION)-($GIT_COMMIT)"
}
# Display nuspawn logo
export def "main version logo" [] {
"888888ba           .d88888b                                           8b
88     8b          88.                                                 8b
88     88 dP    dP  Y88888b. 88d888b. .d8888b. dP  dP  dP 88d888b.      8b
88     88 88    88        8b 88    88 88    88 88  88  88 88    88     .8P
88     88 88.  .88 d8    .8P 88.  .88 88.  .88 88.88b.88  88    88    .8P
dP     dP  88888P   Y88888P  88Y888P   88888P8 8888P Y8P  dP    dP    8P
                             88
                             dP"
}
# Display nuspawn license
export def "main version license" [] {
'Copyright (c) 2024 Tulip <tulilirockz@outlook.com>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of the author nor the names of its contributors may
   be used to endorse or promote products derived from this software

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.'
}
