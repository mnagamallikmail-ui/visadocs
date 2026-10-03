/**
 * ProValuer Commercial - Official Valuation & Verification Portal
 * Interactive 11-Stage Workflow & Only Next Valid Action Controller
 */

// The 11 Sequential Workflow Stages
const WORKFLOW_STAGES = [
  {
    id: 'REQUEST',
    name: 'REQUEST',
    shortLabel: 'Request',
    icon: '📝',
    sla: 'Immediate',
    nextValidActionLabel: '[ Select Service ]',
    nextActionType: 'SELECT_SERVICE',
    actionTitle: 'Configure Valuation Scope & Service Tier',
    actionDesc: 'Select your valuation purpose (Visa Immigration, Commercial Real Estate, Net Worth) and property classification to generate the official fee quote.',
    buttonClass: 'big-action-trigger-btn',
    assignedPerson: 'Intake Desk (System)',
    stageStatus: 'Action Required',
    nextMilestone: '2. QUOTE (Instant Estimation)'
  },
  {
    id: 'QUOTE',
    name: 'QUOTE',
    shortLabel: 'Quote',
    icon: '📊',
    sla: 'Generated Instant',
    nextValidActionLabel: '[ View Quote ]',
    nextActionType: 'VIEW_QUOTE',
    actionTitle: 'Review Official Valuation Fee Quote',
    actionDesc: 'Your transparent fee estimation and turnaround SLA schedule have been prepared. Please inspect the itemized quotation to proceed.',
    buttonClass: 'big-action-trigger-btn btn-gold-action',
    assignedPerson: 'Pricing Engine V2.4',
    stageStatus: 'Client Acceptance Pending',
    nextMilestone: '3. PAYMENT (Intake Deposit)'
  },
  {
    id: 'PAYMENT',
    name: 'PAYMENT',
    shortLabel: 'Payment',
    icon: '💳',
    sla: 'Instant Processing',
    nextValidActionLabel: '[ Submit Payment ]',
    nextActionType: 'SUBMIT_PAYMENT',
    actionTitle: 'Submit Valuation Intake Fee',
    actionDesc: 'Submit the intake deposit of ₹ 9,500 via secure UPI / Card gateway to trigger automated legal registry checks and report pool assignment.',
    buttonClass: 'big-action-trigger-btn btn-gold-action',
    assignedPerson: 'Escrow Payment Controller',
    stageStatus: 'Payment Pending',
    nextMilestone: '4. VERIFICATION (Document Integrity)'
  },
  {
    id: 'VERIFICATION',
    name: 'VERIFICATION',
    shortLabel: 'Verification',
    icon: '🔍',
    sla: '3-4 Working Hours',
    nextValidActionLabel: '[ Upload Documents ]',
    nextActionType: 'UPLOAD_DOCS',
    actionTitle: 'Upload & Verify Title Documents',
    actionDesc: 'Upload mandatory registered title deeds, municipal tax receipts, and sanction layouts for automated OCR parsing and compliance clearance.',
    buttonClass: 'big-action-trigger-btn',
    assignedPerson: 'Document Verification Cell',
    stageStatus: 'Awaiting Document Upload',
    nextMilestone: '5. POOL (Operational Queue)'
  },
  {
    id: 'POOL',
    name: 'POOL',
    shortLabel: 'Pool',
    icon: '⏳',
    sla: 'Under 2 Hours',
    nextValidActionLabel: '[ Track Progress ]',
    nextActionType: 'TRACK_PROGRESS',
    actionTitle: 'Order Queued in Unassigned Operational Pool',
    actionDesc: 'Your verified dossier is currently in the operational pool ready to be claimed by a registered Government/IBBI certified Property Analyst.',
    buttonClass: 'big-action-trigger-btn',
    assignedPerson: 'Global PA Allocation Pool',
    stageStatus: 'Queue Priority: High',
    nextMilestone: '6. ASSIGNMENT (Analyst Claim)'
  },
  {
    id: 'ASSIGNMENT',
    name: 'ASSIGNMENT',
    shortLabel: 'Assignment',
    icon: '👤',
    sla: 'Active SLA (6h Limit)',
    nextValidActionLabel: '[ Track Progress ]',
    nextActionType: 'TRACK_PROGRESS',
    actionTitle: 'Claimed by Certified Property Analyst',
    actionDesc: 'Property Analyst Rajesh Sharma (Reg #IBBI/RV/02/2021) has claimed your file. Telemetry heartbeat is actively recording processing time.',
    buttonClass: 'big-action-trigger-btn',
    assignedPerson: 'Rajesh Sharma (PA)',
    stageStatus: 'Analyst Working (Telemetry Live)',
    nextMilestone: '7. INSPECTION (Physical / Desk Audit)'
  },
  {
    id: 'INSPECTION',
    name: 'INSPECTION',
    shortLabel: 'Inspection',
    icon: '📐',
    sla: 'Scheduled Today',
    nextValidActionLabel: '[ Track Progress ]',
    nextActionType: 'TRACK_PROGRESS',
    actionTitle: 'Site Inspection & Geo-spatial Audit',
    actionDesc: 'Physical site verification or satellite municipal boundary geo-tagging is in progress to assess construction quality, carpet area, and depreciation.',
    buttonClass: 'big-action-trigger-btn',
    assignedPerson: 'Field Surveyor / GIS Team',
    stageStatus: 'Site Audit Active',
    nextMilestone: '8. DRAFTING (Template Engine)'
  },
  {
    id: 'DRAFTING',
    name: 'DRAFTING',
    shortLabel: 'Drafting',
    icon: '📄',
    sla: 'Within 4 Hours',
    nextValidActionLabel: '[ Track Progress ]',
    nextActionType: 'TRACK_PROGRESS',
    actionTitle: 'Compiling Dynamic Report via Docx4j Engine',
    actionDesc: 'Compiling valuation formulas, guideline value comparisons, and replacement cost algorithms into institutional embassy-standard templates.',
    buttonClass: 'big-action-trigger-btn',
    assignedPerson: 'Docx Template Engine & PA',
    stageStatus: 'Draft 85% Compiled',
    nextMilestone: '9. REVIEW (Senior Analyst QA)'
  },
  {
    id: 'REVIEW',
    name: 'REVIEW',
    shortLabel: 'Review',
    icon: '⚖️',
    sla: 'Final QA Review',
    nextValidActionLabel: '[ Track Progress ]',
    nextActionType: 'TRACK_PROGRESS',
    actionTitle: 'Senior Property Analyst (SPA) QA & Sign-Off',
    actionDesc: 'Senior Valuer is validating guideline discrepancies, valuation fairness, and attaching Cloud HSM Class 3 digital signature tokens.',
    buttonClass: 'big-action-trigger-btn',
    assignedPerson: 'Vikramaditya Rao (SPA)',
    stageStatus: 'Review & Sign-Off Pending',
    nextMilestone: '10. DELIVERY (Signed Report Release)'
  },
  {
    id: 'DELIVERY',
    name: 'DELIVERY',
    shortLabel: 'Delivery',
    icon: '📥',
    sla: 'Delivered',
    nextValidActionLabel: '[ Download Report ]',
    nextActionType: 'DOWNLOAD_REPORT',
    actionTitle: 'Certified Valuation Report Ready For Download',
    actionDesc: 'Your official valuation certificate (₹ 1,92,40,000) has been cryptographically signed and sealed. You can now download the official PDF and DOCX.',
    buttonClass: 'big-action-trigger-btn btn-success-action',
    assignedPerson: 'Signed via Class 3 Cloud HSM',
    stageStatus: 'Report Ready for Download',
    nextMilestone: '11. CLOSED (Archived)'
  },
  {
    id: 'CLOSED',
    name: 'CLOSED',
    shortLabel: 'Closed',
    icon: '🏁',
    sla: 'Completed & Stored',
    nextValidActionLabel: '[ Download Report ]',
    nextActionType: 'DOWNLOAD_REPORT',
    actionTitle: 'Order Fulfilled & Securely Archived',
    actionDesc: 'This order is successfully closed and stored in immutable compliance storage for 7 years as mandated by IBBI regulations. Report download remains active.',
    buttonClass: 'big-action-trigger-btn btn-success-action',
    assignedPerson: 'Compliance Archive System',
    stageStatus: 'Order Finalized (Closed)',
    nextMilestone: 'All Stages Complete'
  }
];

// App Global State
let currentStageIndex = 0; // Starts at REQUEST (0)
let currentSelectedService = 'Visa Immigrations & Study Abroad';
let currentSelectedProperty = 'Commercial Office Unit';
let activeOrder = {
  id: 'PV-2026-9842',
  property: 'Cyber Towers Unit 402, HITEC City',
  client: 'Anand Mehta',
  category: 'COMMERCIAL VALUATION',
  intakeAmount: '₹ 9,500',
  valuationAmount: '₹ 1,92,40,000'
};

// Initialize App
document.addEventListener('DOMContentLoaded', () => {
  renderSimulatorButtons();
  updateStageUI(currentStageIndex);
});

// View Navigation Switcher
function switchView(viewName) {
  const views = {
    'landing': document.getElementById('viewLanding'),
    'request': document.getElementById('viewRequest'),
    'auth': document.getElementById('viewAuth'),
    'dashboard': document.getElementById('viewDashboard')
  };

  const navButtons = {
    'landing': document.getElementById('navBtnLanding'),
    'request': document.getElementById('navBtnRequest'),
    'auth': document.getElementById('navBtnAuth'),
    'dashboard': document.getElementById('navBtnDashboard')
  };

  // Hide all views & remove active class
  Object.keys(views).forEach(key => {
    if (views[key]) views[key].classList.remove('active-view');
    if (navButtons[key]) navButtons[key].classList.remove('active');
  });

  // Activate selected view
  if (views[viewName]) {
    views[viewName].classList.add('active-view');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }
  if (navButtons[viewName]) {
    navButtons[viewName].classList.add('active');
  }

  showToast(`Switched to ${viewName.toUpperCase()} view`);
}

// Render Simulator Buttons for Demonstration
function renderSimulatorButtons() {
  const container = document.getElementById('simulatorButtons');
  if (!container) return;

  container.innerHTML = '';
  WORKFLOW_STAGES.forEach((stage, idx) => {
    const btn = document.createElement('button');
    btn.className = `btn btn-sm ${idx === currentStageIndex ? 'btn-primary' : 'btn-secondary'}`;
    btn.style.fontSize = '11px';
    btn.style.padding = '4px 10px';
    btn.textContent = `${idx + 1}. ${stage.shortLabel}`;
    btn.title = `Jump to ${stage.name}`;
    btn.onclick = () => {
      setWorkflowStage(idx);
    };
    container.appendChild(btn);
  });
}

// Set Stage Directly (Interactive Simulation)
function setWorkflowStage(index) {
  if (index < 0 || index >= WORKFLOW_STAGES.length) return;
  currentStageIndex = index;
  updateStageUI(currentStageIndex);
  renderSimulatorButtons();
  showToast(`Stage updated to ${WORKFLOW_STAGES[index].name}`);
}

// Advance Workflow to Next Stage
function advanceSimulatedStep() {
  if (currentStageIndex < WORKFLOW_STAGES.length - 1) {
    currentStageIndex++;
    updateStageUI(currentStageIndex);
    renderSimulatorButtons();
    closeAllModals();
    showToast(`Order progressed to ${WORKFLOW_STAGES[currentStageIndex].name}`);
  } else {
    showToast('Order is already at the final CLOSED stage.');
  }
}

// -----------------------------------------------------------------------------
// PROGRESS TRACKER (TOP OF PAGE) & ONLY NEXT VALID ACTION (MIDDLE OF PAGE)
// -----------------------------------------------------------------------------
function updateStageUI(stageIdx) {
  const stage = WORKFLOW_STAGES[stageIdx];

  // 1. Update Header & Subheader
  const currentStageNameElem = document.getElementById('currentStageName');
  if (currentStageNameElem) currentStageNameElem.textContent = stage.name;

  const currentStageStatusElem = document.getElementById('ctxStageStatus');
  if (currentStageStatusElem) currentStageStatusElem.textContent = stage.stageStatus;

  // 2. Render the 11-Stage Progress Tracker Nodes
  const chainContainer = document.getElementById('stagesChainContainer');
  if (chainContainer) {
    // Keep background line & fill line
    chainContainer.innerHTML = `
      <div class="chain-line-bg"></div>
      <div class="chain-line-fill" id="chainLineFill"></div>
    `;

    WORKFLOW_STAGES.forEach((s, idx) => {
      const node = document.createElement('div');
      node.className = 'stage-node';
      if (idx < stageIdx) node.classList.add('is-completed');
      if (idx === stageIdx) node.classList.add('is-current');

      node.onclick = () => setWorkflowStage(idx);

      const circleIcon = idx < stageIdx ? '✓' : (idx + 1);

      node.innerHTML = `
        <div class="stage-icon-circle" title="Click to view ${s.name} stage">
          ${circleIcon}
        </div>
        <div class="stage-label-text">${s.name}</div>
        <div class="stage-eta-text">${s.sla}</div>
      `;

      chainContainer.appendChild(node);
    });

    // Calculate progress fill width
    const fillPercent = (stageIdx / (WORKFLOW_STAGES.length - 1)) * 95 + 2.5;
    const fillElem = document.getElementById('chainLineFill');
    if (fillElem) fillElem.style.width = `${fillPercent}%`;
  }

  // 3. Update the "Only Next Valid Action" Spotlight Card
  const actionTitle = document.getElementById('actionTitleText');
  const actionDesc = document.getElementById('actionDescText');
  const actionBtn = document.getElementById('primaryNextActionBtn');
  const ctxCurrentStage = document.getElementById('ctxCurrentStage');
  const ctxNextMilestone = document.getElementById('ctxNextMilestone');
  const ctxAssignedPerson = document.getElementById('ctxAssignedPerson');

  if (actionTitle) actionTitle.textContent = stage.actionTitle;
  if (actionDesc) actionDesc.textContent = stage.actionDesc;
  if (ctxCurrentStage) ctxCurrentStage.textContent = `${stageIdx + 1}. ${stage.name}`;
  if (ctxNextMilestone) ctxNextMilestone.textContent = stage.nextMilestone;
  if (ctxAssignedPerson) ctxAssignedPerson.textContent = stage.assignedPerson;

  if (actionBtn) {
    actionBtn.className = stage.buttonClass;
    actionBtn.textContent = stage.nextValidActionLabel;
  }
}

// -----------------------------------------------------------------------------
// ACTION BUTTON DISPATCHER
// Triggers precisely the modal/operation corresponding to the current state
// -----------------------------------------------------------------------------
function handleCurrentNextAction() {
  const stage = WORKFLOW_STAGES[currentStageIndex];

  switch (stage.nextActionType) {
    case 'SELECT_SERVICE':
      openModal('serviceSelectModal');
      break;

    case 'VIEW_QUOTE':
      openModal('viewQuoteModal');
      break;

    case 'SUBMIT_PAYMENT':
      openModal('paymentModal');
      break;

    case 'UPLOAD_DOCS':
      openModal('uploadDocsModal');
      break;

    case 'TRACK_PROGRESS':
      openModal('trackProgressModal');
      break;

    case 'DOWNLOAD_REPORT':
      openModal('downloadReportModal');
      break;

    default:
      showToast(`Action ${stage.nextValidActionLabel} initiated.`);
      break;
  }
}

// -----------------------------------------------------------------------------
// MODAL MANAGEMENT & FORM INTERACTIONS
// -----------------------------------------------------------------------------
function openModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.classList.add('active');
  }
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.classList.remove('active');
  }
}

function closeAllModals() {
  document.querySelectorAll('.modal-overlay').forEach(modal => {
    modal.classList.remove('active');
  });
}

// Modal: Service Pick
function confirmServiceModalPick(serviceName) {
  currentSelectedService = serviceName;
  document.querySelectorAll('#serviceSelectModal .select-card-option').forEach(el => {
    el.classList.remove('selected');
  });
  if (event && event.currentTarget) {
    event.currentTarget.classList.add('selected');
  }
}

function applyServiceSelection() {
  closeModal('serviceSelectModal');
  showToast(`Service selected: ${currentSelectedService}`);
  // If in REQUEST stage, offer the property type selection
  openModal('propertySelectModal');
}

// Modal: Property Pick
function confirmPropertyModalPick(propertyName) {
  currentSelectedProperty = propertyName;
  document.querySelectorAll('#propertySelectModal .select-card-option').forEach(el => {
    el.classList.remove('selected');
  });
  if (event && event.currentTarget) {
    event.currentTarget.classList.add('selected');
  }
}

function applyPropertySelection() {
  closeModal('propertySelectModal');
  showToast(`Property type confirmed: ${currentSelectedProperty}`);
  // Advance to QUOTE stage
  setWorkflowStage(1); // QUOTE
}

// Modal: Accept Quote
function acceptQuoteAndProceedToPayment() {
  closeModal('viewQuoteModal');
  showToast('Quote approved by client. Moving to Payment stage.');
  setWorkflowStage(2); // PAYMENT
  setTimeout(() => {
    openModal('paymentModal');
  }, 400);
}

// Modal: Process Payment
function processSimulatedPayment() {
  closeModal('paymentModal');
  showToast('Processing payment of ₹ 9,500...');

  // Add audit timeline entry
  addAuditLogEntry('Payment Verified', 'Client paid ₹ 9,500 via secure UPI. Receipt generated: TXN-894102.');

  setTimeout(() => {
    showToast('Payment Successful! Advancing to Document Verification.');
    setWorkflowStage(3); // VERIFICATION
  }, 1000);
}

// Modal: Upload Document
function handleModalFileUpload(e) {
  const file = e.target.files[0];
  if (file) {
    showToast(`Attached ${file.name} (${(file.size / (1024 * 1024)).toFixed(1)} MB)`);
  }
}

function confirmUploadModal() {
  closeModal('uploadDocsModal');
  showToast('Documents uploaded & verified by OCR.');
  addAuditLogEntry('Documents Verified', 'Registered Sale Deed and Tax receipts verified by compliance engine.');
  setWorkflowStage(4); // POOL
}

// Report Download Simulation
function simulateFileDownload(type) {
  showToast(`Downloading official ${type} valuation report with Class 3 signature...`);
  setTimeout(() => {
    showToast(`Valuation_Report_PV-2026-9842.${type.toLowerCase()} downloaded successfully.`);
    if (currentStageIndex === 9) {
      setWorkflowStage(10); // CLOSED
    }
  }, 1500);
}

// Helper: Add Audit Log Entry
function addAuditLogEntry(title, description) {
  const stream = document.getElementById('auditTimelineStream');
  if (!stream) return;

  const now = new Date();
  const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  const entry = document.createElement('div');
  entry.className = 'timeline-entry';
  entry.innerHTML = `
    <div class="timeline-dot" style="background: #10B981;"></div>
    <div class="timeline-content">
      <div style="font-weight: 600;">${title}</div>
      <div style="font-size: 12px; color: var(--text-muted);">${description}</div>
      <div class="timeline-time">Today, ${timeStr} • Client Portal</div>
    </div>
  `;
  stream.insertBefore(entry, stream.firstChild);
}

// -----------------------------------------------------------------------------
// INTAKE WIZARD (VIEW 2) LOGIC
// -----------------------------------------------------------------------------
function selectServiceOption(elem, serviceName) {
  document.querySelectorAll('#serviceOptions .select-card-option').forEach(el => el.classList.remove('selected'));
  elem.classList.add('selected');
  currentSelectedService = serviceName;
}

function selectPropertyOption(elem, propertyName) {
  document.querySelectorAll('#propertyOptions .select-card-option').forEach(el => el.classList.remove('selected'));
  elem.classList.add('selected');
  currentSelectedProperty = propertyName;
}

function handleFileSelected(e) {
  const files = e.target.files;
  if (!files || files.length === 0) return;

  const preview = document.getElementById('uploadListPreview');
  for (let i = 0; i < files.length; i++) {
    const f = files[i];
    // Check 20MB limit
    if (f.size > 20 * 1024 * 1024) {
      alert(`File ${f.name} exceeds maximum allowed size of 20MB!`);
      continue;
    }
    const pill = document.createElement('div');
    pill.className = 'file-item-pill';
    pill.innerHTML = `
      <div style="display: flex; align-items: center; gap: 8px;">
        <span>📄</span>
        <strong>${f.name}</strong>
        <span style="font-size: 11px; color: var(--text-dim);">(${(f.size / (1024 * 1024)).toFixed(1)} MB)</span>
      </div>
      <span style="color: #10B981; font-weight: 600; font-size: 11px;">✓ Attached</span>
    `;
    preview.appendChild(pill);
  }
  showToast(`${files.length} document(s) attached successfully.`);
}

function submitIntakeRequest() {
  const clientName = document.getElementById('intakeClientName').value;
  const address = document.getElementById('intakeAddress').value;

  activeOrder.client = clientName;
  activeOrder.property = address;

  const heading = document.getElementById('propertyHeading');
  if (heading) heading.textContent = address;

  showToast('Intake parameters captured! Proceeding to Client Login / Register.');
  switchView('auth');
}

// -----------------------------------------------------------------------------
// AUTHENTICATION (VIEW 3) LOGIC
// -----------------------------------------------------------------------------
function switchAuthTab(mode) {
  const tabLogin = document.getElementById('tabLogin');
  const tabReg = document.getElementById('tabRegister');
  if (mode === 'login') {
    tabLogin.classList.add('active');
    tabReg.classList.remove('active');
  } else {
    tabReg.classList.add('active');
    tabLogin.classList.remove('active');
  }
}

function performDemoLogin() {
  document.getElementById('authEmail').value = 'anand.mehta@visadocs.com';
  document.getElementById('authTermsAgree').checked = true;
  showToast('Demo Client Verified. Redirecting to Client Dashboard...');
  setTimeout(() => {
    switchView('dashboard');
    setWorkflowStage(0); // Start at REQUEST stage
  }, 400);
}

function handleAuthSubmit() {
  const termsAgree = document.getElementById('authTermsAgree').checked;
  if (!termsAgree) {
    alert('You must accept the Terms & Conditions (v2.4) to enter the portal.');
    return;
  }
  showToast('Authentication successful!');
  switchView('dashboard');
  setWorkflowStage(0);
}

// -----------------------------------------------------------------------------
// THEME SWITCHER & TOAST NOTIFICATION UTILS
// -----------------------------------------------------------------------------
function toggleTheme() {
  const html = document.documentElement;
  const current = html.getAttribute('data-theme');
  const next = current === 'dark' ? 'light' : 'dark';
  html.setAttribute('data-theme', next);
  showToast(`Switched to ${next.toUpperCase()} mode`);
}

let toastTimer = null;
function showToast(message) {
  const toast = document.getElementById('globalToast');
  const toastMsg = document.getElementById('toastMessage');
  if (!toast || !toastMsg) return;

  toastMsg.textContent = message;
  toast.style.display = 'flex';

  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    toast.style.display = 'none';
  }, 3200);
}
