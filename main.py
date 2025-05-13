from flask import Flask, request, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor
import bcrypt
import logging
import os
from flask_cors import CORS
from datetime import datetime, timedelta
from configparser import ConfigParser

app = Flask(__name__)
CORS(app)
app.config['SECRET_KEY'] = 'your_secret_key'

# Logging setup
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Load DB config from database.ini
def load_db_config(filename='database.ini', section='postgresql'):
    parser = ConfigParser()
    parser.read(filename)

    if not parser.has_section(section):
        raise Exception(f'Section {section} not found in {filename}')
    
    return {param[0]: param[1] for param in parser.items(section)}

config = load_db_config()
DB_USER = config['user']
DB_PASSWORD = config['password']
DB_HOST = config['host']
DB_PORT = config['port']
DB_NAME = config['database']

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
os.environ["PSYCOPG2_FORCE_IPV4"] = "1"


def get_db_connection():
    try:
        conn = psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor, sslmode='require')
        logger.debug("✅ Database connection successful")
        return conn
    except Exception as e:
        logger.error(f"❌ DB connection error: {e}")
        raise

def test_db_connection_on_startup():
    try:
        conn = get_db_connection()
        conn.close()
        logger.info("✅ DB check passed at startup")
    except Exception as e:
        logger.error(f"❌ Startup DB error: {e}")
        raise

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"message": "Email and password are required"}), 400

    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("INSERT INTO users (email, password_hash) VALUES (%s, %s)", (email, hashed_password))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "User registered successfully!"}), 201
    except psycopg2.errors.UniqueViolation:
        return jsonify({"message": "Email already registered"}), 409
    except Exception as e:
        logger.error(f"Registration error: {e}")
        return jsonify({"message": "Error during registration"}), 500

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"message": "Email and password are required"}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT user_id, email, password_hash FROM users WHERE email = %s", (email,))
        user = cur.fetchone()
        cur.close()
        conn.close()

        if user and bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
            return jsonify({
                "message": "Login successful",
                "userId": user['user_id']
            }), 200
        else:
            return jsonify({"message": "Invalid credentials"}), 401
    except Exception as e:
        logger.error(f"Login error: {e}")
        return jsonify({"message": "Error during login"}), 500

@app.route('/add-transaction', methods=['POST'])
def add_transaction():
    data = request.get_json()
    user_id = data.get('user_id')
    category = data.get('category')
    amount = data.get('amount')
    transaction_type = data.get('transaction_type')
    description = data.get('description')

    if not all([user_id, category, amount, transaction_type]):
        return jsonify({"message": "All transaction details are required"}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO transactions (user_id, category, amount, transaction_type, description)
            VALUES (%s, %s, %s, %s, %s)
        """, (user_id, category, amount, transaction_type, description))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "Transaction added successfully!"}), 201
    except Exception as e:
        logger.error(f"Add transaction error: {e}")
        return jsonify({"message": "Error adding transaction"}), 500

@app.route('/get-transactions/<user_id>', methods=['GET'])
def get_transactions(user_id):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT category, amount, transaction_type AS type, description, created_at AS date
            FROM transactions
            WHERE user_id = %s
            ORDER BY created_at DESC
        """, (user_id,))
        transactions = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify(transactions), 200
    except Exception as e:
        logger.error(f"Fetch transactions error: {e}")
        return jsonify({"message": f"Error fetching transactions: {e}"}), 500

@app.route('/set-budget/<user_id>', methods=['POST'])
def set_budget(user_id):
    data = request.get_json()
    category = data.get('category')
    amount = data.get('amount')

    if not category or not amount:
        return jsonify({"message": "Category and amount are required"}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        # Check if a monthly budget already exists for the category
        cur.execute("""
            SELECT * FROM budgets
            WHERE user_id = %s AND category = %s AND period = 'monthly'
        """, (user_id, category))
        existing = cur.fetchone()

        if existing:
            # Update existing budget
            cur.execute("""
                UPDATE budgets
                SET amount = %s, start_date = CURRENT_DATE, end_date = CURRENT_DATE + INTERVAL '1 month'
                WHERE user_id = %s AND category = %s AND period = 'monthly'
            """, (amount, user_id, category))
        else:
            # Insert new budget
            cur.execute("""
                INSERT INTO budgets (user_id, category, amount, period, start_date, end_date)
                VALUES (%s, %s, %s, 'monthly', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month')
            """, (user_id, category, amount))

        conn.commit()
        cur.close()
        conn.close()

        return jsonify({"message": "Budget updated"}), 200
    except Exception as e:
        logger.error(f"Set budget error: {e}")
        return jsonify({"message": "Error setting budget"}), 500


@app.route('/get-budgets/<user_id>', methods=['GET'])
def get_budgets(user_id):
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        # Get start and end of current month using the same dashboard logic
        now = datetime.now()
        start_of_month = now.replace(day=1)
        end_of_month = (start_of_month + timedelta(days=32)).replace(day=1)

        # Use created_at (not 'date') for correct timestamp filtering
        cur.execute("""
            SELECT 
                b.category, 
                b.amount,
                COALESCE((
                    SELECT SUM(t.amount)
                    FROM transactions t
                    WHERE t.user_id = b.user_id
                      AND t.category = b.category
                      AND t.transaction_type = 'expense'
                      AND t.created_at >= %s
                      AND t.created_at < %s
                ), 0) AS spent
            FROM budgets b
            WHERE b.user_id = %s AND b.period = 'monthly'
        """, (start_of_month, end_of_month, user_id))

        budgets = cur.fetchall()
        cur.close()
        conn.close()

        return jsonify(budgets), 200
    except Exception as e:
        logger.error(f"Get budgets error: {e}")
        return jsonify({"message": "Error fetching budgets"}), 500




@app.route('/get-dashboard/<user_id>', methods=['GET'])
def get_dashboard(user_id):
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("SELECT SUM(amount) FROM transactions WHERE user_id = %s AND transaction_type = 'income'", (user_id,))
        total_income = cur.fetchone()['sum'] or 0

        cur.execute("SELECT SUM(amount) FROM transactions WHERE user_id = %s AND transaction_type = 'expense'", (user_id,))
        total_expense = cur.fetchone()['sum'] or 0

        # Monthly spending for last 3 months
        now = datetime.now()
        spending_by_month = {}
        for i in range(2, -1, -1):
            month_date = (now.replace(day=1) - timedelta(days=30*i))
            month_key = month_date.strftime('%Y-%m')
            spending_by_month[month_key] = 0.0

        cur.execute("""
            SELECT amount, created_at
            FROM transactions
            WHERE user_id = %s AND transaction_type = 'expense'
              AND created_at >= (CURRENT_DATE - INTERVAL '3 months')
        """, (user_id,))
        rows = cur.fetchall()

        for row in rows:
            created_at = row['created_at']
            if created_at:
                month = created_at.strftime('%Y-%m')
                if month in spending_by_month:
                    spending_by_month[month] += float(row['amount'])

        monthly_spending = list(spending_by_month.values())

        cur.close()
        conn.close()

        return jsonify({
            "totalIncome": float(total_income),
            "totalExpense": float(total_expense),
            "monthlySpending": monthly_spending
        }), 200
    except Exception as e:
        logger.error(f"Dashboard error: {e}")
        return jsonify({"message": "Error fetching dashboard data"}), 500
    
@app.route('/get-report/<user_id>', methods=['GET'])
def get_report(user_id):
    period = request.args.get('period', 'weekly').lower()
    now = datetime.now()

    if period == "weekly":
        start = now - timedelta(days=now.weekday())
        end = start + timedelta(days=7)
    elif period == "monthly":
        start = now.replace(day=1)
        end = (start + timedelta(days=32)).replace(day=1)
    elif period == "yearly":
        start = now.replace(month=1, day=1)
        end = now.replace(year=now.year + 1, month=1, day=1)
    else:
        return jsonify({"message": "Invalid period"}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        # Income
        cur.execute("""
            SELECT COALESCE(SUM(amount), 0) as income
            FROM transactions
            WHERE user_id = %s AND transaction_type = 'income'
              AND created_at BETWEEN %s AND %s
        """, (user_id, start, end))
        income = float(cur.fetchone()['income'])

        # Expense
        cur.execute("""
            SELECT COALESCE(SUM(amount), 0) as expense
            FROM transactions
            WHERE user_id = %s AND transaction_type = 'expense'
              AND created_at BETWEEN %s AND %s
        """, (user_id, start, end))
        expense = float(cur.fetchone()['expense'])

        net_savings = income - expense

        # Avg daily spending
        days = (end - start).days
        avg_daily_spending = round(expense / days, 2) if days > 0 else 0

        # Ratio
        ratio = round(income / expense, 2) if expense > 0 else "N/A"

        # Budget utilization
        cur.execute("""
            SELECT COALESCE(SUM(b.amount), 0) as total_budget
            FROM budgets b
            WHERE user_id = %s
              AND b.start_date >= %s
              AND b.end_date <= %s
        """, (user_id, start, end))
        total_budget = float(cur.fetchone()['total_budget'])

        budget_util = round((expense / total_budget) * 100, 2) if total_budget > 0 else 0

        # Top 3 spending categories
        cur.execute("""
            SELECT category
            FROM transactions
            WHERE user_id = %s AND transaction_type = 'expense'
              AND created_at BETWEEN %s AND %s
            GROUP BY category
            ORDER BY SUM(amount) DESC
            LIMIT 3
        """, (user_id, start, end))
        top_categories = [row['category'] for row in cur.fetchall()]

        # Highest expense
        cur.execute("""
            SELECT MAX(amount) AS max_exp
            FROM transactions
            WHERE user_id = %s AND transaction_type = 'expense'
              AND created_at BETWEEN %s AND %s
        """, (user_id, start, end))
        highest_expense = float(cur.fetchone()['max_exp'] or 0)

        # Highest income
        cur.execute("""
            SELECT MAX(amount) AS max_inc
            FROM transactions
            WHERE user_id = %s AND transaction_type = 'income'
              AND created_at BETWEEN %s AND %s
        """, (user_id, start, end))
        highest_income = float(cur.fetchone()['max_inc'] or 0)

        # All transactions for export
        cur.execute("""
            SELECT category, amount, transaction_type, description, created_at
            FROM transactions
            WHERE user_id = %s AND created_at BETWEEN %s AND %s
            ORDER BY created_at DESC
        """, (user_id, start, end))
        all_transactions = cur.fetchall()

        cur.close()
        conn.close()

        return jsonify({
            "income": income,
            "expense": expense,
            "net_savings": net_savings,
            "average_daily_spending": avg_daily_spending,
            "income_expense_ratio": ratio,
            "budget_utilization": budget_util,
            "top_categories": top_categories,
            "highest_expense": highest_expense,
            "highest_income": highest_income,
            "transactions": all_transactions  # for PDF export
        }), 200

    except Exception as e:
        logger.error(f"Report error: {e}")
        return jsonify({"message": "Error generating report"}), 500

from fpdf import FPDF
from flask import send_file
import io

@app.route('/download-report/<user_id>', methods=['GET'])
def download_report(user_id):
    period = request.args.get('period', 'weekly').lower()

    # Date filtering
    now = datetime.now()
    if period == 'weekly':
        start_date = now - timedelta(days=7)
    elif period == 'monthly':
        start_date = now.replace(day=1)
    elif period == 'yearly':
        start_date = now.replace(month=1, day=1)
    else:
        return jsonify({"message": "Invalid period"}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        # Fetch insights
        cur.execute("""
            SELECT
                COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0) AS income,
                COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) AS expense,
                COALESCE(AVG(amount), 0) AS avg_spend
            FROM transactions
            WHERE user_id = %s AND created_at >= %s
        """, (user_id, start_date))
        summary = cur.fetchone()

        net_savings = summary['income'] - summary['expense']
        income_expense_ratio = round((summary['income'] / summary['expense']), 2) if summary['expense'] != 0 else 'N/A'

        # Top categories
        cur.execute("""
            SELECT category, SUM(amount) as total
            FROM transactions
            WHERE user_id = %s AND transaction_type = 'expense' AND created_at >= %s
            GROUP BY category ORDER BY total DESC LIMIT 3
        """, (user_id, start_date))
        top_categories = cur.fetchall()

        # Highest income/expense
        cur.execute("""
            SELECT MAX(CASE WHEN transaction_type = 'income' THEN amount ELSE NULL END) as max_income,
                   MAX(CASE WHEN transaction_type = 'expense' THEN amount ELSE NULL END) as max_expense
            FROM transactions
            WHERE user_id = %s AND created_at >= %s
        """, (user_id, start_date))
        max_data = cur.fetchone()

        # All transactions
        cur.execute("""
            SELECT category, amount, transaction_type, description, created_at
            FROM transactions
            WHERE user_id = %s AND created_at >= %s
            ORDER BY created_at DESC
        """, (user_id, start_date))
        all_transactions = cur.fetchall()

        cur.close()
        conn.close()

        # PDF generation
        pdf = FPDF()
        pdf.add_page()
        pdf.set_font("Arial", size=12)

        pdf.cell(200, 10, txt=f"Finance Report ({period.title()})", ln=True, align='C')
        pdf.ln(10)

        pdf.cell(200, 10, txt=f"Total Income: Rs{summary['income']}", ln=True)
        pdf.cell(200, 10, txt=f"Total Expense: Rs{summary['expense']}", ln=True)
        pdf.cell(200, 10, txt=f"Net Savings: Rs{net_savings}", ln=True)
        pdf.cell(200, 10, txt=f"Average Daily Spending: Rs{round(summary['avg_spend'], 2)}", ln=True)
        pdf.cell(200, 10, txt=f"Income-Expense Ratio: {income_expense_ratio}", ln=True)
        pdf.ln(5)

        pdf.cell(200, 10, txt="Top 3 Spending Categories:", ln=True)
        for cat in top_categories:
            pdf.cell(200, 10, txt=f"- {cat['category']}: Rs{cat['total']}", ln=True)

        pdf.cell(200, 10, txt=f"Highest Income: Rs{max_data['max_income'] or 0}", ln=True)
        pdf.cell(200, 10, txt=f"Highest Expense: Rs{max_data['max_expense'] or 0}", ln=True)
        pdf.ln(5)

        pdf.set_font("Arial", 'B', size=12)
        pdf.cell(200, 10, txt="All Transactions:", ln=True)
        pdf.set_font("Arial", size=11)
        for tx in all_transactions:
            date_str = tx['created_at'].strftime('%Y-%m-%d')
            pdf.multi_cell(0, 10, f"{date_str} - {tx['category']} - {tx['transaction_type']} - Rs{tx['amount']} - {tx['description'] or ''}")

        # Send PDF
        pdf_output = io.BytesIO()
        pdf.output(pdf_output)
        pdf_output.seek(0)

        return send_file(pdf_output, download_name=f"{period}_report.pdf", as_attachment=True)

    except Exception as e:
        logger.error(f"PDF generation failed: {e}")
        return jsonify({"message": "Failed to generate report"}), 500


@app.route('/test-db')
def test_db_connection():
    try:
        with app.app_context():
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute("SELECT 1;")
            cur.fetchone()
            cur.close()
            conn.close()
        return jsonify({"message": "Database connection successful ✅"}), 200
    except Exception as e:
        return jsonify({"error": f"Database connection failed: {e}"}), 500

if __name__ == '__main__':
    
    test_db_connection_on_startup()
    app.run(debug=True, host='0.0.0.0', port=5000)
