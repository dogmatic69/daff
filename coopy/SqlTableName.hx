// -*- mode:java; tab-width:4; c-basic-offset:4; indent-tabs-mode:nil -*-

package coopy;

@:expose
class SqlTableName {
    public var name : String;
    public var prefix : String;

    public function new(name: String = "", prefix: String = "") {
        this.name = name;
        this.prefix = prefix;
    }
}

