// -*- mode:java; tab-width:4; c-basic-offset:4; indent-tabs-mode:nil -*-

package coopy;

interface SqlDatabase {
    function getColumns(name: SqlTableName) : Array<SqlColumn>;

    function getQuotedTableName(name: SqlTableName) : String;
    function getQuotedColumnName(name: String) : String;

    function begin(query: String, ?args: Array<Dynamic>) : Bool;
    function read() : Bool;
    function get(index: Int) : Dynamic;
    function end() : Bool;
    function width() : Int;
}
