// -*- mode:java; tab-width:4; c-basic-offset:4; indent-tabs-mode:nil -*-

package coopy;

class SqlTable {
    private var db: SqlDatabase;
    private var columns: Array<SqlColumn>;
    private var name: SqlTableName;
    private var quotedTableName: String;

    private function getColumns() : Void {
        if (columns!=null) return;
        if (db==null) return;
        columns = db.getColumns(name);
    }

    public function new(db: SqlDatabase, name: SqlTableName) {
        this.db = db;
        this.name = name;
    }

    public function getPrimaryKey() : Array<String> {
        getColumns();
        var result = new Array<String>();
        for (col in columns) {
            if (!col.isPrimaryKey()) continue;
            result.push(col.getName());
        }
        return result;
    }

    public function getAllButPrimaryKey() : Array<String> {
        getColumns();
        var result = new Array<String>();
        for (col in columns) {
            if (col.isPrimaryKey()) continue;
            result.push(col.getName());
        }
        return result;
    }

    public function getColumnNames() : Array<String> {
        getColumns();
        var result = new Array<String>();
        for (col in columns) {
            result.push(col.getName());
        }
        return result;
    }

    public function getQuotedTableName() : String {
        if (quotedTableName!=null) return quotedTableName;
        quotedTableName = db.getQuotedTableName(name);
        return quotedTableName;
    }

    public function getQuotedColumnName(name : String) : String {
        return db.getQuotedColumnName(name);
    }
}


