// -*- mode:java; tab-width:4; c-basic-offset:4; indent-tabs-mode:nil -*-

package coopy;

@:expose
class SqlCompare {
    public var db: SqlDatabase;
    public var parent: SqlTable;
    public var local: SqlTable;
    public var remote: SqlTable;

    public function new() {
    }

    private function equalArray(a1: Array<String>, a2: Array<String>) : Bool {
        if (a1.length!=a2.length) return false;
        for (i in 0...a1.length) {
            if (a1[i]!=a2[i]) return false;
        }
        return true;
    }

    public function validateSchema() : Bool {
        var all_cols1 = local.getColumnNames();
        var all_cols2 = remote.getColumnNames();
        if (!equalArray(all_cols1,all_cols2)) { 
            return false;
        }
        var key_cols1 = local.getPrimaryKey();
        var key_cols2 = remote.getPrimaryKey();
        if (!equalArray(key_cols1,key_cols2)) {
            return false;
        }
        if (key_cols1.length==0) {
            return false;
        }
        return true;
    }

    private function denull(x: Null<Int>) : Int {
        if (x==null) return -1;
        return x;
    }

    public function apply() : Alignment {
        if (db==null) return null;
        if (!validateSchema()) return null;

        var align = new Alignment();

        var key_cols = local.getPrimaryKey();
        var data_cols = local.getAllButPrimaryKey();
        var all_cols = local.getColumnNames();

        var sql_table1 = local.getQuotedTableName();
        var sql_table2 = remote.getQuotedTableName();
        var sql_key_cols: String = "";
        for (i in 0...(key_cols.length)) {
            if (i>0) sql_key_cols += ",";
            sql_key_cols += local.getQuotedColumnName(key_cols[i]);
        }
        var sql_all_cols: String = "";
        for (i in 0...(all_cols.length)) {
            if (i>0) sql_all_cols += ",";
            sql_all_cols += local.getQuotedColumnName(all_cols[i]);
        }
        var sql_key_match : String = "";
        for (i in 0...(key_cols.length)) {
            if (i>0) sql_key_match += " AND ";
            var n : String = local.getQuotedColumnName(key_cols[i]);
            sql_key_match += sql_table1 + "." + n + " IS " + sql_table2 + "." + n;
        }
        var sql_data_mismatch : String = "";
        for (i in 0...(data_cols.length)) {
            if (i>0) sql_data_mismatch += " OR ";
            var n : String = local.getQuotedColumnName(data_cols[i]);
            sql_data_mismatch += sql_table1 + "." + n + " IS NOT " + sql_table2 + "." + n;
        }
        var sql_dbl_cols: String = "";
        for (i in 0...(all_cols.length)) {
            if (i>0) sql_dbl_cols += ",";
            var n : String = local.getQuotedColumnName(all_cols[i]);
            var buf : String = "__coopy_" + i;
            sql_dbl_cols += sql_table1 + "." + n + " AS " + buf;
            sql_dbl_cols += ",";
            sql_dbl_cols += sql_table2 + "." + n + " AS " + buf + "b";
        }
        var sql_order: String = "";
        for (i in 0...(key_cols.length)) {
            if (i>0) sql_order += ",";
            var n : String = local.getQuotedColumnName(key_cols[i]);
            sql_order += n;
        }
        var sql_dbl_order: String = "";
        for (i in 0...(key_cols.length)) {
            if (i>0) sql_dbl_order += ",";
            var n : String = local.getQuotedColumnName(key_cols[i]);
            sql_dbl_order += sql_table1 + "." + n;
        }

        // _rowid_ is sqlite specific
        var sql_inserts : String = "SELECT NULL, _rowid_, " + sql_all_cols + " FROM " + sql_table2 + " WHERE NOT EXISTS (SELECT 1 FROM " + sql_table1 + " WHERE " + sql_key_match + ")";
        var sql_updates : String = "SELECT " + sql_table1 + "._rowid_, " + sql_table2 + "._rowid_, " + sql_dbl_cols + " FROM " + sql_table1 + " INNER JOIN " + sql_table2 + " ON " + sql_key_match + " WHERE " + sql_data_mismatch;
        // + " ORDER BY " + sql_dbl_order;
        var sql_deletes : String = "SELECT _rowid_, NULL, " + sql_all_cols + " FROM " + sql_table1 + " WHERE NOT EXISTS (SELECT 1 FROM " + sql_table2 + " WHERE " + sql_key_match + ")";
 
        trace(" SQL to find inserts: " + sql_inserts);

        if (db.begin(sql_inserts)) {
            while (db.read()) {
                trace(" -- " + db.get(0) + " " + db.get(1) + " --");
                align.link(denull(db.get(0)),denull(db.get(1)));
                //RowChange rc;
                //rc.mode = ROW_CHANGE_INSERT;
                for (i in 0...all_cols.length) {
                    var c = db.get(i+2);
                    var key = all_cols[i];
                    trace(key + " ... " + c);
                    //rc.val[key] = c;
                    //rc.names.push_back(key);
                }
                //rc.allNames = all_cols;
                //rc.indexes = indexes;
                //output.changeRow(rc);
            }
            db.end();
        }

        trace(" SQL to find updates: " + sql_updates);

        if (db.begin(sql_updates)) {
            while (db.read()) {
                trace(" -- " + db.get(0) + " " + db.get(1) + " --");
                align.link(denull(db.get(0)),denull(db.get(1)));
                //RowChange rc;
                //rc.mode = ROW_CHANGE_UPDATE;
                for (i in 0...all_cols.length) {
                    var c1 = db.get(2+2*i);
                    var c2 = db.get(2+2*i+1);
                    var key = all_cols[i];
                    trace(key + " ... " + c1 + " -> " + c2);
                    //rc.cond[key] = c1;
                    //if (c1!=c2) {
                    //    rc.val[key] = c2;
                    //}
                    //rc.names.push_back(key);
                }
                //rc.allNames = all_cols;
                //rc.indexes = indexes;
                //output.changeRow(rc);
            }
            db.end();
        }

        trace(" SQL to find deletes: " + sql_deletes);

        if (db.begin(sql_deletes)) {
            while (db.read()) {
                trace(" -- " + db.get(0) + " " + db.get(1) + " --");
                align.link(denull(db.get(0)),denull(db.get(1)));
                //RowChange rc;
                //rc.mode = ROW_CHANGE_DELETE;
                for (i in 0...all_cols.length) {
                    var c = db.get(2+i);
                    var key = all_cols[i];
                    trace(key + " ... " + c);
                    //rc.cond[key] = c;
                    //rc.names.push_back(key);
                }
                //rc.allNames = all_cols;
                //rc.indexes = indexes;
                //output.changeRow(rc);
            }
            db.end();
        }
        
        return align;
    }
}

