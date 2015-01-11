function mysql --description 'Admin interface to mysql server on localhost'
    if count $argv >/dev/null
        switch $argv[1]
            case errlog
                tail -f /usr/local/var/mysql/host.local.err
            case restart
                launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist
                sleep 3
                launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist
            case root
                /usr/local/bin/mysql --user=root --password --host=localhost
            case rtuser
                /usr/local/bin/mysql --user=rtuser --password --host=localhost --database=rtdb
            case start
                launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist
            case status
                /usr/local/bin/mysql.server status
            case stop
                launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist
            case '*'
                echo "Usage: mysql [ command ]"
                echo -e "\nClient session commands:"
                echo " root     start mysql client as user 'root'"
                echo " rtuser   start mysql client as user 'rtuser'"
                echo -e "\nServer administration commands:"
                echo " errlog   monitor server error log"
                echo " start    start mysql server"
                echo " stop     stop mysql server"
                echo " restart  restart mysql server"
                echo " status   report server status"
        end
    else
        echo "Usage: mysql [ command ], try mysql --help"
    end
end
