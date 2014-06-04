import coopyhx as daff
import sqlite3 as sqlite

class SqliteDatabase(daff.coopy_SqlDatabase):
    def __init__(self,db):
        self.db = db
        self.cursor = db.cursor()
        self.row = None

    # needed because pragmas do not support bound parameters
    def getQuotedColumnName(self,name):
        return name  # adequate for test, not real life

    # needed because pragmas do not support bound parameters
    def getQuotedTableName(self,name):
        return name  # adequate for test, not real life

    def getColumns(self,name):
        qname = self.getQuotedColumnName(name)
        info = self.cursor.execute("pragma table_info(%s)"%qname).fetchall()
        return [daff.coopy_SqlColumn.byNameAndPrimaryKey(x[1],x[5]>0) for x in info]

    def begin(self,query,args=[]):
        print(">>> working on " + query)
        self.cursor.execute(query,args)
        return True

    def read(self):
        self.row = self.cursor.fetchone()
        return self.row!=None

    def get(self,index):
        v = self.row[index]
        if v is None:
            return v
        return str(v)


    def end(self):
        pass

db = sqlite.connect(':memory:')
c = db.cursor()

c.execute("CREATE TABLE ver1 (id INTEGER PRIMARY KEY, name TEXT)")
c.execute("CREATE TABLE ver2 (id INTEGER PRIMARY KEY, name TEXT)")
data = [(1, "Paul"),
        (2, "Naomi"),
        (4, "Hobbes")]
c.executemany('INSERT INTO ver1 VALUES (?,?)', data)
data = [(2, "Noemi"),
        (3, "Calvin"),
        (4, "Hobbes")]
c.executemany('INSERT INTO ver2 VALUES (?,?)', data)

for row in c.execute('SELECT * FROM ver1'):
        print ("1 |||" + str(row))
for row in c.execute('SELECT * FROM ver2'):
        print ("2 |||" + str(row))

sd = SqliteDatabase(db)

st1 = daff.coopy_SqlTable(sd,"ver1")
st2 = daff.coopy_SqlTable(sd,"ver2")

sc = daff.coopy_SqlCompare()
sc.db = sd
sc.local = st1
sc.remote = st2

print(sc.apply().toString())
