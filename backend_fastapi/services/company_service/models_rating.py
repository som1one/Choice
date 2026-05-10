"""Модели для фраз отзывов и услуг компании."""

from sqlalchemy import Boolean, Column, ForeignKey, Index, Integer, String, UniqueConstraint

from common.database import Base


class RatingCriterion(Base):
    """Фраза отзыва, доступная для конкретной оценки."""

    __tablename__ = "rating_criteria"
    __table_args__ = (
        UniqueConstraint("grade", "text", name="uq_rating_criteria_grade_text"),
        Index("ix_rating_criteria_grade", "grade"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    grade = Column(Integer, nullable=False)
    text = Column(String, nullable=False)
    sort_order = Column(Integer, nullable=False, default=0)
    is_active = Column(Boolean, nullable=False, default=True)

    def __repr__(self):
        return (
            f"<RatingCriterion(id={self.id}, grade={self.grade}, "
            f"text={self.text!r}, is_active={self.is_active})>"
        )


class CompanyService(Base):
    """Модель услуги компании."""

    __tablename__ = "company_services"

    id = Column(Integer, primary_key=True, autoincrement=True)
    company_guid = Column(
        String,
        ForeignKey("Companies.guid"),
        nullable=False,
        index=True,
    )
    name = Column(String, nullable=False)

    def __repr__(self):
        return f"<CompanyService(id={self.id}, company_guid={self.company_guid}, name={self.name})>"


class CompanyProduct(Base):
    """Модель товара компании."""

    __tablename__ = "company_products"

    id = Column(Integer, primary_key=True, autoincrement=True)
    company_guid = Column(
        String,
        ForeignKey("Companies.guid"),
        nullable=False,
        index=True,
    )
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    price = Column(Integer, nullable=True)

    def __repr__(self):
        return f"<CompanyProduct(id={self.id}, company_guid={self.company_guid}, name={self.name})>"
