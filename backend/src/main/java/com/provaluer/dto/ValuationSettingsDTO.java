package com.provaluer.dto;

import java.math.BigDecimal;

public class ValuationSettingsDTO {
    private BigDecimal realizablePercentage;
    private BigDecimal distressSalePercentage;
    private BigDecimal salvagePercentage;
    private Integer rccUsefulLife;
    private Integer shedUsefulLife;

    public ValuationSettingsDTO() {}

    public ValuationSettingsDTO(BigDecimal realizablePercentage, BigDecimal distressSalePercentage, BigDecimal salvagePercentage, Integer rccUsefulLife, Integer shedUsefulLife) {
        this.realizablePercentage = realizablePercentage;
        this.distressSalePercentage = distressSalePercentage;
        this.salvagePercentage = salvagePercentage;
        this.rccUsefulLife = rccUsefulLife;
        this.shedUsefulLife = shedUsefulLife;
    }

    public BigDecimal getRealizablePercentage() { return realizablePercentage; }
    public void setRealizablePercentage(BigDecimal realizablePercentage) { this.realizablePercentage = realizablePercentage; }

    public BigDecimal getDistressSalePercentage() { return distressSalePercentage; }
    public void setDistressSalePercentage(BigDecimal distressSalePercentage) { this.distressSalePercentage = distressSalePercentage; }

    public BigDecimal getSalvagePercentage() { return salvagePercentage; }
    public void setSalvagePercentage(BigDecimal salvagePercentage) { this.salvagePercentage = salvagePercentage; }

    public Integer getRccUsefulLife() { return rccUsefulLife; }
    public void setRccUsefulLife(Integer rccUsefulLife) { this.rccUsefulLife = rccUsefulLife; }

    public Integer getShedUsefulLife() { return shedUsefulLife; }
    public void setShedUsefulLife(Integer shedUsefulLife) { this.shedUsefulLife = shedUsefulLife; }
}
