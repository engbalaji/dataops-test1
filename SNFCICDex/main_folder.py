import snowflake.connector
import os
import datetime
import json
import argparse
import io

def get_conn():
    with open('sf-config.json', 'r') as file:
        data = json.load(file)
        user = data['user']
        password = data['password']
        account = data['account']

    conn = snowflake.connector.connect(
        user=user,
        password=password,
        account=account
    )
    return conn

def read_file_with_encoding(file_path, encoding='utf-8'):
    try:
        with open(file_path, 'r', encoding=encoding) as f:
            return f.read()
    except UnicodeDecodeError:
        if encoding == 'utf-8':
            return read_file_with_encoding(file_path, encoding='ISO-8859-1')
        else:
            raise

def main(dir, ShowSuccesfull_stmt):
    con = get_conn()
    icount = 0
    icountOK = 0
    icountNOK = 0
    for filename in os.listdir(dir):
        f = os.path.join(dir, filename)
        if os.path.isfile(f):
            icount += 1
            last_qry = ''
            try:
                file_content = read_file_with_encoding(f)
                file_like_object = io.StringIO(file_content)
                print(f'Running script in: {f}')
                for cur in con.execute_stream(file_like_object):
                    if ShowSuccesfull_stmt == '1':
                        last_qry += cur.query + '\n'
                print('Script succesvol gedraaid!')
                if ShowSuccesfull_stmt == '1':
                    print(cur.query)
                icountOK += 1
            except snowflake.connector.errors.DatabaseError as db_ex:
                print(f'Foutmelding: {db_ex.msg}')
                if ShowSuccesfull_stmt == '1':
                    print(last_qry)
                icountNOK += 1
                pass
    print(f'Alle scripts gedraaid op Snowflake ({icount} scripts: {icountOK} OK, {icountNOK} NOK).')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run SQL scripts from a directory against a Snowflake database.')
    parser.add_argument('dir', type=str, help='Directory containing SQL scripts')
    parser.add_argument('ShowSuccesfull_stmt', type=str, help='Show successful statements (1 for yes, 0 for no)')
    args = parser.parse_args()

    print(datetime.datetime.now())
    main(args.dir, args.ShowSuccesfull_stmt)
    print(datetime.datetime.now())


# changes for errormessage AttributeError: 'str' object has no attribute 'readline'
# changes for different encoding
# python main_folder.py ./iceberg 0
# run via background
# nohup python main_folder.py ./cost 0 &
