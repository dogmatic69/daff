// -*- mode:java; tab-width:4; c-basic-offset:4; indent-tabs-mode:nil -*-

class Report {
    public function new() : Void {
        changes = new Array<Change>();
    }

    public var changes : Array<Change>;

    public function toString() : String {
        return changes.toString();
    }    
}

