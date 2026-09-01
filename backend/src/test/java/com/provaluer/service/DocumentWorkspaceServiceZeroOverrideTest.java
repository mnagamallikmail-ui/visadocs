package com.provaluer.service;

import com.provaluer.dto.ValuationBundleResponse;
import com.provaluer.model.Order;
import com.provaluer.model.OrderInput;
import com.provaluer.model.ValuationData;
import com.provaluer.model.ValuationLandItem;
import com.provaluer.model.ValuationBuildingItem;
import com.provaluer.repository.OrderInputRepository;
import com.provaluer.repository.OrderRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class DocumentWorkspaceServiceZeroOverrideTest {

    @Mock
    private OrderInputRepository orderInputRepository;

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private ValuationEngineService valuationEngineService;

    @InjectMocks
    private DocumentWorkspaceService service;

    @Test
    public void testZeroAndEmptyValuesAreOverriddenByValuationBundle() {
        Long orderId = 42L;

        // 1. Existing order inputs in database contain "0", "0.00", "₹ 0" or blank
        List<OrderInput> mockInputs = List.of(
                new OrderInput(orderId, "TOTAL_LAND_VALUE", "0"),
                new OrderInput(orderId, "TOTAL_BUILDING_VALUE", "0.00"),
                new OrderInput(orderId, "FAIR_VALUE", "₹ 0"),
                new OrderInput(orderId, "GOVERNMENT_VALUE", "INR 0"),
                new OrderInput(orderId, "REALIZABLE_VALUE", "Rupees Zero Only"),
                new OrderInput(orderId, "CLIENT_NAME", "State Bank of India") // Non-zero text value
        );
        when(orderInputRepository.findAllByOrderId(orderId)).thenReturn(mockInputs);

        // 2. Valuation bundle has real computed numbers
        ValuationData valData = new ValuationData(orderId);
        valData.setTotalLandValue(new BigDecimal("2250000.00"));
        valData.setTotalBuildingValue(new BigDecimal("4625000.00"));
        valData.setFairValue(new BigDecimal("6875000.00"));
        valData.setGovernmentValue(new BigDecimal("13050000.00"));
        valData.setRealizableValue(new BigDecimal("5843750.00"));

        Map<String, String> placeholders = new HashMap<>();
        placeholders.put("TOTAL_LAND_VALUE", "22,50,000");
        placeholders.put("total_land_value", "22,50,000");
        placeholders.put("TOTAL_BUILDING_VALUE", "46,25,000");
        placeholders.put("total_building_value", "46,25,000");
        placeholders.put("FAIR_VALUE", "68,75,000");
        placeholders.put("fair_value", "68,75,000");
        placeholders.put("GOVERNMENT_VALUE", "1,30,50,000");
        placeholders.put("government_value", "1,30,50,000");
        placeholders.put("REALIZABLE_VALUE", "58,43,750");
        placeholders.put("realizable_value", "58,43,750");

        ValuationLandItem landItem = new ValuationLandItem();
        landItem.setDescription("Commercial Plot (Sy.No.42/A)");
        landItem.setValue(new BigDecimal("2250000.00"));

        ValuationBuildingItem bldgItem = new ValuationBuildingItem();
        bldgItem.setDescription("Commercial Office Building");
        bldgItem.setBuildingValue(new BigDecimal("4625000.00"));

        ValuationBundleResponse bundle = new ValuationBundleResponse(
                valData,
                List.of(landItem),
                List.of(bldgItem),
                Collections.emptyList(),
                Collections.emptyList(),
                placeholders,
                false
        );

        when(valuationEngineService.getValuationBundle(orderId)).thenReturn(bundle);

        // 3. Execute getConsolidatedValues
        Map<String, String> consolidated = service.getConsolidatedValues(orderId);

        // 4. Verify that "0", "0.00", "₹ 0" were overwritten by real valuation bundle values
        assertEquals("22,50,000", consolidated.get("TOTAL_LAND_VALUE"));
        assertEquals("46,25,000", consolidated.get("TOTAL_BUILDING_VALUE"));
        assertEquals("68,75,000", consolidated.get("FAIR_VALUE"));
        assertEquals("1,30,50,000", consolidated.get("GOVERNMENT_VALUE"));
        assertEquals("58,43,750", consolidated.get("REALIZABLE_VALUE"));
        assertEquals("State Bank of India", consolidated.get("CLIENT_NAME"));

        // Verify JSON was populated for tables
        assertNotNull(consolidated.get("RAW_LAND_ITEMS_JSON"));
        assertTrue(consolidated.get("RAW_LAND_ITEMS_JSON").contains("Commercial Plot (Sy.No.42/A)"));
        assertNotNull(consolidated.get("RAW_BUILDING_ITEMS_JSON"));
        assertTrue(consolidated.get("RAW_BUILDING_ITEMS_JSON").contains("Commercial Office Building"));
    }
}
