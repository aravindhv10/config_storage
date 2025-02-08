#!/usr/local/bin/nu
for i in (ps | where name == sleeper).pid {ln -vfs /proc/($i|into string)/root ./}
