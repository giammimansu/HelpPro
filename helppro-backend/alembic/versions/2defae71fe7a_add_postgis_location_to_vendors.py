"""Add PostGIS location to vendors

Revision ID: 2defae71fe7a
Revises: ab3710c7dd69
Create Date: 2025-07-14 15:34:43.450373

"""
from alembic import op
import sqlalchemy as sa
from geoalchemy2 import Geometry

# revision identifiers, used by Alembic.
revision = '2defae71fe7a'
down_revision = 'ab3710c7dd69'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Add the PostGIS location column and spatial index to vendors."""
    # Add a nullable PostGIS geometry column
    op.add_column(
        'vendors',
        sa.Column('location', Geometry('POINT', srid=4326), nullable=True)
    )
    # Create a GiST index for fast spatial queries
    op.create_index(
        'ix_vendors_location',
        'vendors',
        ['location'],
        postgresql_using='gist'
    )


def downgrade() -> None:
    """Remove the PostGIS location column and spatial index from vendors."""
    # Drop the GiST index
    op.drop_index('ix_vendors_location', table_name='vendors')
    # Remove the geometry column
    op.drop_column('vendors', 'location')
