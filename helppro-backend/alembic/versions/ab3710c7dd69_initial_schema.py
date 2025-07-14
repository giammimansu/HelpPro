"""Initial schema

Revision ID: ab3710c7dd69
Revises: 
Create Date: 2025-07-14 15:33:27.649077

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'ab3710c7dd69'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create initial application tables: users, vendor_accounts, vendors."""
    # Create users table
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), primary_key=True, nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('full_name', sa.String(), nullable=True),
        sa.Column('hashed_password', sa.String(), nullable=False),
        sa.Column('disabled', sa.Boolean(), nullable=True),
        sa.Column('role', sa.Enum('client', 'professional', name='roleenum'), nullable=False),
    )
    op.create_index('ix_users_email', 'users', ['email'], unique=True)

    # Create vendor_accounts table
    op.create_table(
        'vendor_accounts',
        sa.Column('id', sa.Integer(), primary_key=True, nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('hashed_password', sa.String(), nullable=False),
    )
    op.create_index('ix_vendor_accounts_email', 'vendor_accounts', ['email'], unique=True)

    # Create vendors table
    op.create_table(
        'vendors',
        sa.Column('id', sa.Integer(), primary_key=True, nullable=False),
        sa.Column('account_id', sa.Integer(), sa.ForeignKey('vendor_accounts.id'), nullable=False),
        sa.Column('company_name', sa.String(), nullable=False),
        sa.Column('category', sa.Enum('haircut', 'beautician', 'plumber', 'mason', name='categoryenum'), nullable=False),
        sa.Column('country', sa.String(), nullable=False),
        sa.Column('city', sa.String(), nullable=False),
        sa.Column('postcode', sa.String(), nullable=False),
        sa.Column('address', sa.String(), nullable=False),
        sa.UniqueConstraint('account_id'),
    )
    op.create_index('ix_vendors_id', 'vendors', ['id'], unique=False)


def downgrade() -> None:
    """Drop initial application tables: vendors, vendor_accounts, users."""
    op.drop_index('ix_vendors_id', table_name='vendors')
    op.drop_table('vendors')
    op.drop_index('ix_vendor_accounts_email', table_name='vendor_accounts')
    op.drop_table('vendor_accounts')
    op.drop_index('ix_users_email', table_name='users')
    op.drop_table('users')
    # Drop enums
    op.execute("DROP TYPE IF EXISTS roleenum;")
    op.execute("DROP TYPE IF EXISTS categoryenum;")