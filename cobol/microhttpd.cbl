identification division.
PROGRAM-ID. microhttpd.

environment division.
configuration section.
repository.
    function all intrinsic.  *> Import all intrinsic functions

data division.
working-storage section.
01 MHD_HTTP_OK               constant   as 200.
01 MHD_USE_SELECT_INTERNALLY constant   as 8.
01 MHD_RESPMEM_PERSISTENT    constant   as 0.
01 MHD_OPTION_END            constant   as 0.
   *> Define constants for libmicrohttpd usage

01 star-daemon               usage pointer. 
01 connection-handler-entry  usage program-pointer.
   *> Define pointers for MHD_start_daemon function usage

01 server-command            pic x(80).
   *> Define a variable to hold user input

*> ***************************************************************
procedure division.
set connection-handler-entry to
    entry "connection-handler"  *> Set the entry point for the connection handler function
call "MHD_start_daemon" using
    by value MHD_USE_SELECT_INTERNALLY
    by value 8080
    by value 0
    by value 0
    by value connection-handler-entry
    by value 0
    by value MHD_OPTION_END
    returning star-daemon      *> Start the MHD daemon and return a pointer to it
    on exception
        display
            "microhttpd: libmicrohttpd failure"
            upon syserr
        end-display
end-call

display "wow, server.  help, info, quit" end-display
perform until server-command = "quit"
    display "server: " with no advancing end-display
    accept server-command end-accept   *> Wait for user input
    if server-command = "help" then
        display
            "microhttpd: help, info, quit"
        end-display
    end-if
    if server-command = "info" then
        display
            "microhttpd: info? help, quit"
        end-display
    end-if
end-perform

call "MHD_stop_daemon" using
    by value star-daemon      *> Stop the MHD daemon using the returned pointer
    on exception
        display
            "microhttpd: libmicrohttpd failure"
            upon syserr
        end-display
end-call

goback.
end program microhttpd.

*> ***************************************************************

*> ***************************************************************
identification division.
program-id. connection-handler.

data division.
working-storage section.
01 MHD_HTTP_OK               constant   as 200.
01 MHD_RESPMEM_PERSISTENT    constant   as 0.
01 webpage              pic x(132) value
    "<html><body>" &
    "Hello, world<br/>" &
    "from <b>GnuCOBOL</b> and <i>libmicrohttpd</i>" &
    "</body></html>".
01 star-response                        usage pointer.
01 mhd-result                           usage binary-long.

linkage section.
01 star-cls                             usage pointer.
01 star-connection                      usage pointer.
01 star-url                             usage pointer.
01 star-method                          usage pointer.
01 star-version                         usage pointer.
01 star-upload-data                     usage pointer.
01 star-upload-data-size                usage pointer.
01 star-star-con-cls                    usage pointer.

procedure division using 
by value star-cls 
by value star-connection
by value star-url
by value star-method
by value star-version
by value star-upload-data
by value star-upload-data-size
by reference star-star-con-cls
.

*> Display a message indicating that the connection handler has been called
display "wow, connection handler" upon syserr end-display

*> Create a response buffer using the contents of the webpage variable
call "MHD_create_response_from_buffer" using
    by value length of webpage
    by reference webpage
    by value MHD_RESPMEM_PERSISTENT
    returning star-response
    on exception
        display
            "microhttpd: libmicrohttpd failure"
            upon syserr
        end-display
end-call

*> Queue the response to be sent back to the client
call "MHD_queue_response" using
    by value star-connection
    by value MHD_HTTP_OK
    by value star-response
    returning mhd-result
    on exception
        display
            "microhttpd: libmicrohttpd failure"
            upon syserr
        end-display
end-call

*> Destroy the response buffer
call "MHD_destroy_response" using
    by value star-response
end-call

*> Move the result to the return code
move mhd-result to return-code

goback.
end program connection-handler.