// Written in the D programming language.

/**
 * MessagePack for D, static resolution routine
 *
 * Copyright: Copyright Masahiro Nakagawa 2010.
 * License:   <a href = "http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Masahiro Nakagawa
 */
module msgpack.object;

/*
 * Avoids compile error related object module. Bug or Spec?
 */
import object;

import std.traits;


/**
 * $(D MessagePack) object type
 */
enum mp_Type
{
    NIL,
    BOOLEAN,
    POSITIVE_INTEGER,
    NEGATIVE_INTEGER,
    FLOAT,  // Original version is DOUBLE
    ARRAY,
    MAP,
    RAW
}


/**
 * $(D InvalidTypeException) is thrown on type errors
 */
class InvalidTypeException : Exception
{
    this(string message)
    {
        super(message);
    }
}


/**
 * $(D mp_Object) is a $(D MessagePack) Object representation
 */
struct mp_Object
{
    union Value
    {
        bool          boolean;
        ulong         uinteger;
        long          integer;
        double        floating;
        mp_Object[]   array;
        mp_KeyValue[] map;
        ubyte[]       raw;
    }


    mp_Type type;
    Value   via;   // real value


    /**
     * Constructs a $(D mp_Object) with arguments for nil object.
     *
     * Params:
     *  value   = the real content.
     *  mp_type = the type of object.
     */
    this(mp_Type mp_type = mp_Type.NIL)
    {
        type = mp_type;
    }


    /// ditto
    this(bool value, mp_Type mp_type = mp_Type.BOOLEAN)
    {
        this(mp_type);
        via.boolean = value;
    }


    /// ditto
    this(ulong value, mp_Type mp_type = mp_Type.POSITIVE_INTEGER)
    {
        this(mp_type);
        via.uinteger = value;
    }


    /// ditto
    this(long value, mp_Type mp_type = mp_Type.NEGATIVE_INTEGER)
    {
        this(mp_type);
        via.integer = value;
    }


    /// ditto
    this(double value, mp_Type mp_type = mp_Type.FLOAT)
    {
        this(mp_type);
        via.floating = value;
    }


    /// ditto
    this(mp_Object[] value, mp_Type mp_type = mp_Type.ARRAY)
    {
        this(mp_type);
        via.array = value;
    }


    /// ditto
    this(mp_KeyValue[] value, mp_Type mp_type = mp_Type.MAP)
    {
        this(mp_type);
        via.map = value;
    }


    /// ditto
    this(ubyte[] value, mp_Type mp_type = mp_Type.RAW)
    {
        this(mp_type);
        via.raw = value;
    }


    /**
     * Converts to $(D_PARAM T) type.
     *
     * Returns:
     *  converted value.
     *
     * Throws:
     *  InvalidTypeException if type mismatches.
     *
     * NOTE:
     *  Current implementation uses cast.
     */
    @property T as(T)() if (is(T == bool))
    {
        if (type != mp_Type.BOOLEAN)
            raise();

        return cast(bool)via.boolean;
    }


    /// ditto
    @property T as(T)() if (isIntegral!(T))
    {
        if (type == mp_Type.POSITIVE_INTEGER)
            return cast(T)via.uinteger;

        if (type == mp_Type.NEGATIVE_INTEGER)
            return cast(T)via.integer;

        raise();

        assert(false);
    }


    /// ditto
    @property T as(T)() if (isFloatingPoint!(T))
    {
        if (type != mp_Type.FLOAT)
            raise();

        return cast(T)via.floating;
    }


    /// ditto
    @property T as(T)() if (isArray!(T))
    {
        static if (isSomeString!(T)) {
            if (type != mp_Type.RAW)
                raise();

            return cast(T)via.raw;
        } else {
            alias typeof(T.init[0]) V;

            if (type != mp_Type.ARRAY)
                raise();

            V[] array;

            foreach (elem; via.array)
                array ~= elem.as!(V);

            return array;
        }
    }


    /// ditto
    @property T as(T)() if (isAssociativeArray!(T))
    {
        alias typeof(T.init.keys[0])   K;
        alias typeof(T.init.values[0]) V;

        if (type != mp_Type.MAP)
            raise();

        V[K] map;

        foreach (elem; via.map)
            map[elem.key.as!(K)] = elem.value.as!(V);

        return map;
    }


  private:
    void raise()
    {
        throw new InvalidTypeException("Attempt to cast with another type");
    }
}


/**
 * $(D mp_KeyValue) is a $(D MessagePack) Map Object representation
 */
struct mp_KeyValue
{
    mp_Object key;
    mp_Object value;
}