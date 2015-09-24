if [ -e "rebar" ]
then
    echo "rebar already installed"
else
    git clone git://github.com/rebar/rebar.git rebar_source
    cd rebar_source/
    ./bootstrap
    cp rebar ..
    cd ..
fi
./rebar get
./rebar compile
