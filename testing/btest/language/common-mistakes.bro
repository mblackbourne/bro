# These tests show off common scripting mistakes, which should be
# handled internally by way of throwing an exception to unwind out
# of the current event handler body.

# @TEST-EXEC: bro -b 1.bro >1.out 2>&1
# @TEST-EXEC: btest-diff 1.out

# @TEST-EXEC: bro -b 2.bro >2.out 2>&1
# @TEST-EXEC: btest-diff 2.out

# @TEST-EXEC: bro -b 3.bro >3.out 2>&1
# @TEST-EXEC: btest-diff 3.out

@TEST-START-FILE 1.bro
type myrec: record {
	f: string &optional;
};

function foo(mr: myrec)
	{
	print "foo start";
	# Unitialized field access: unwind out of current event handler body
	print mr$f;
	# Unreachable
	print "foo done";
	}

function bar()
	{
	print "bar start";
	foo(myrec());
	# Unreachable
	print "bar done";
	}

event bro_init()
	{
	bar();
	# Unreachable
	print "bro_init done";
	}

event bro_init() &priority=-10
	{
	# Reachable
	print "other bro_init";
	}
@TEST-END-FILE

@TEST-START-FILE 2.bro
function foo()
	{
	print "in foo";
	local t: table[string] of string = table();

	# Non-existing index access: (sub)expressions should not be evaluated
	if ( t["nope"] == "nope" )
		# Unreachable
		print "yes";
	else
		# Unreachable
		print "no";

	# Unreachable
	print "foo done";
	}

event bro_init()
	{
	foo();
	# Unreachable
	print "bro_init done";
	}

@TEST-END-FILE

@TEST-START-FILE 3.bro
function foo(v: vector of any)
	{
	print "in foo";
	# Vector append incompatible element type
	v += "ok";
	# Unreachable
	print "foo done";
	}

event bro_init()
	{
	local v: vector of count;
	v += 1;
	foo(v);
	# Unreachable
	print "bro_init done", v;
	}
@TEST-END-FILE
