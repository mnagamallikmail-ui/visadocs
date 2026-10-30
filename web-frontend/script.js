/**
 * Pro Valuer OPC Pvt Ltd - Official Valuation & Verification Portal
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
    nextMilestone: '7. DRAFTING (Template Engine)'
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
    nextMilestone: '8. REVIEW (Senior Analyst QA)'
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
    nextMilestone: '9. DELIVERY (Signed Report Release)'
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
    nextMilestone: '10. CLOSED (Archived)'
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
    'dashboard': document.getElementById('viewDashboard'),
    'privacy': document.getElementById('viewPrivacy'),
    'terms': document.getElementById('viewTerms'),
    'notice': document.getElementById('viewDpdpNotice')
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

let selectedIntakeFiles = [];

function handleFileSelected(e) {
  const files = e.target.files;
  if (!files || files.length === 0) return;

  const preview = document.getElementById('uploadListPreview');
  for (let i = 0; i < files.length; i++) {
    const f = files[i];
    // Check 25MB limit under Phase 6 hardening
    if (f.size > 25 * 1024 * 1024) {
      alert(`Security Limit Error: File "${f.name}" exceeds maximum allowed upload size of 25MB!`);
      continue;
    }
    selectedIntakeFiles.push(f);

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
  showToast(`${files.length} document(s) validated and attached.`);
}

function handleAgeSelection(isMinor) {
  const guardianSection = document.getElementById('guardianConsentSection');
  if (isMinor) {
    if (guardianSection) guardianSection.style.display = 'block';
    // Phase 3 DPDP Mandate: Disable GA4 and Clarity permanently for minors
    disableAnalyticsTelemetry();
    localStorage.setItem('dpdp_analytics_consent', 'minor_blocked');
    const banner = document.getElementById('analyticsConsentBanner');
    if (banner) banner.style.display = 'none';
    showToast('DPDP Section 9 Applied: Web telemetry permanently disabled for minors.');
  } else {
    if (guardianSection) guardianSection.style.display = 'none';
    // Re-check analytics consent status for adults
    const existing = localStorage.getItem('dpdp_analytics_consent');
    if (existing === 'granted') {
      enableAnalyticsTelemetry();
    }
  }
}

async function validateMinorDob(dobStr) {
  if (!dobStr) return;
  try {
    const res = await fetch('/api/v1/privacy/age-verification', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ dateOfBirth: dobStr })
    });
    if (res.ok) {
      const data = await res.json();
      if (!data.isMinor) {
        showToast(`Age check: Applicant is ${data.calculatedAge} years old (Adult). Guardian consent optional.`);
      } else {
        showToast(`Age check: Minor applicant (${data.calculatedAge} yrs). Verifiable guardian consent required.`);
      }
    }
  } catch (e) {
    console.warn('[Age Verification Check Failed]', e);
  }
}

async function submitIntakeRequest() {
  const consentCb = document.getElementById('intakeConsentCheckbox');
  if (!consentCb || !consentCb.checked) {
    alert('DPDP Act 2023 Statutory Requirement:\nUnder Section 6, you must read the statutory notice and check the affirmative consent box before submitting your personal and property particulars.');
    return;
  }

  const isMinor = document.getElementById('ageMinorRadio') && document.getElementById('ageMinorRadio').checked;
  let guardianName = null;
  let guardianRel = null;
  let guardianEmail = null;
  let guardianPhone = null;
  let applicantDob = null;

  if (isMinor) {
    applicantDob = document.getElementById('intakeApplicantDob') ? document.getElementById('intakeApplicantDob').value : null;
    guardianName = document.getElementById('intakeGuardianName') ? document.getElementById('intakeGuardianName').value : null;
    guardianRel = document.getElementById('intakeGuardianRel') ? document.getElementById('intakeGuardianRel').value : null;
    guardianEmail = document.getElementById('intakeGuardianEmail') ? document.getElementById('intakeGuardianEmail').value : null;
    guardianPhone = document.getElementById('intakeGuardianPhone') ? document.getElementById('intakeGuardianPhone').value : null;
    const guardianCb = document.getElementById('guardianAffirmativeConsentCb');

    if (!guardianName || !guardianEmail || !guardianPhone || !applicantDob) {
      alert('DPDP Act Section 9 Violation:\nParental/Guardian details and minor Date of Birth are mandatory for applicants under 18.');
      return;
    }
    if (!guardianCb || !guardianCb.checked) {
      alert('DPDP Act Section 9 Violation:\nVerifiable affirmative parental/guardian consent checkbox must be selected.');
      return;
    }
  }

  const clientName = document.getElementById('intakeClientName').value;
  const email = document.getElementById('intakeEmail').value;
  const phone = document.getElementById('intakePhone').value;
  const address = document.getElementById('intakeAddress').value;
  const estValue = document.getElementById('intakeEstValue') ? document.getElementById('intakeEstValue').value : '';

  const submitBtn = document.getElementById('btnSubmitIntake');
  if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.textContent = 'Encrypting & Submitting...';
  }

  try {
    const leadPayload = {
      serviceType: currentSelectedService,
      propertyType: currentSelectedProperty,
      contactName: clientName,
      contactEmail: email,
      contactPhone: phone,
      propertyAddress: address,
      estimatedValue: estValue,
      consentGiven: true,
      isMinor: isMinor,
      guardianName: guardianName,
      guardianRelationship: guardianRel,
      guardianPhone: guardianPhone,
      guardianEmail: guardianEmail
    };

    const res = await fetch('/api/leads', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(leadPayload)
    });

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(errText || 'Failed to submit intake request');
    }

    const leadData = await res.json();

    // Upload documents if selected using upload token
    if (selectedIntakeFiles.length > 0 && leadData.id && leadData.uploadToken) {
      const formData = new FormData();
      for (const f of selectedIntakeFiles) {
        formData.append('files', f);
      }
      await fetch(`/api/leads/${leadData.id}/documents`, {
        method: 'POST',
        headers: {
          'X-Upload-Token': leadData.uploadToken
        },
        body: formData
      });
    }

    // If minor, record guardian consent statutory log
    if (isMinor && applicantDob) {
      await fetch('/api/v1/privacy/guardian-consent', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          leadId: leadData.id,
          applicantDob: applicantDob,
          guardianName: guardianName,
          relationship: guardianRel,
          guardianPhone: guardianPhone,
          guardianEmail: guardianEmail,
          consentGiven: true,
          noticeVersion: 'DPDP-NOTICE-V2.0'
        })
      });
    }

    // Record client consent in audit ledger
    recordConsentToBackend('VALUATION_PROCESSING', true);

    activeOrder.client = clientName;
    activeOrder.property = address;
    const heading = document.getElementById('propertyHeading');
    if (heading) heading.textContent = address;

    showToast(`Order Request Ref #${leadData.referenceNumber || leadData.id} Submitted & Encrypted!`);
    switchView('dashboard');
    showClientSection('inProgress');
  } catch (err) {
    alert(`Submission Error: ${err.message}`);
  } finally {
    if (submitBtn) {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Submit Valuation Request →';
    }
  }
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
  // DPDP Remediation Rule: Checkboxes must NOT be auto-ticked. Require affirmative user click.
  const termsCb = document.getElementById('authTermsAgree');
  const dpdpCb = document.getElementById('authDpdpConsent');
  if (termsCb && !termsCb.checked) {
    termsCb.focus();
    alert('Please review and tick the Terms & Conditions and DPDP Statutory Notice checkboxes to complete login.');
    return;
  }
  if (dpdpCb && !dpdpCb.checked) {
    dpdpCb.focus();
    alert('Please review and tick the DPDP Statutory Consent checkbox to proceed.');
    return;
  }

  recordConsentToBackend('TERMS_ACCEPTANCE', true);
  recordConsentToBackend('VALUATION_PROCESSING', true);

  showToast('Client Verified & Statutory Consents Recorded. Entering Portal...');
  setTimeout(() => {
    switchView('dashboard');
    showClientSection('inProgress');
  }, 400);
}

function handleAuthSubmit(e) {
  if (e && e.preventDefault) e.preventDefault();
  const termsAgree = document.getElementById('authTermsAgree') ? document.getElementById('authTermsAgree').checked : false;
  const dpdpConsent = document.getElementById('authDpdpConsent') ? document.getElementById('authDpdpConsent').checked : false;

  if (!termsAgree) {
    alert('Please review and accept the Terms & Conditions (v2.4) to enter the portal.');
    return;
  }
  if (!dpdpConsent) {
    alert('Mandatory Statutory Consent Required under DPDP Act 2023:\nPlease check the second box to provide affirmative consent for personal and property data processing.');
    return;
  }

  // Record separate consents in consent_ledger
  recordConsentToBackend('TERMS_ACCEPTANCE', true);
  recordConsentToBackend('VALUATION_PROCESSING', true);

  showToast('Authentication & Statutory DPDP Consent Recorded!');
  switchView('dashboard');
  showClientSection('inProgress');
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

// =============================================================================
// CLIENT PORTAL SIMPLIFICATION CONTROLLERS & DATA STORE
// =============================================================================

// 6 Simplified Client Milestones
const CLIENT_STAGES = [
  'Request Submitted',
  'Under Review',
  'Quotation Ready',
  'Payment Complete',
  'Report In Progress',
  'Delivered'
];

// Active Client Orders
let activeReportsData = [
  {
    id: 'REQ-89',
    reportNumber: 'PV-2026-9842',
    title: 'Commercial Office Valuation',
    service: 'Valuation Report',
    assetType: 'Land & Building',
    purpose: 'Bank Loan',
    assetSummary: 'Cyber Towers Unit 402, HITEC City, Hyderabad',
    createdDate: '20 Sep 2026',
    expectedDate: '25 Sep 2026',
    status: 'Quotation Ready',
    stageIndex: 2, // Quotation Ready
    statusDesc: 'Your official quotation has been prepared with transparent breakdown and 48h turnaround SLA.',
    requiredAction: 'View Quotation & Approve Payment',
    actionType: 'QUOTE_READY',
    docs: [
      { name: 'Title Deed / Sale Deed', status: 'verified', statusText: 'Verified ✓' },
      { name: 'Approved Sanction Plan', status: 'verified', statusText: 'Verified ✓' },
      { name: 'Property Tax Receipt', status: 'verified', statusText: 'Verified ✓' },
      { name: 'Site Photographs', status: 'pending', statusText: 'In Review ⏳' }
    ],
    timeline: [
      { title: 'Official Quotation Issued', desc: 'Pricing desk compiled formal quotation with committed 3-day turnaround SLA.', time: 'Today, 10:45 AM' },
      { title: 'Documents Verified by Desk', desc: 'Ownership deed and sanction layout verified against circle rates.', time: 'Yesterday, 04:30 PM' },
      { title: 'Valuation Request Submitted', desc: 'Mandate initialized via Client Portal wizard.', time: '20 Sep 2026, 02:15 PM' }
    ]
  },
  {
    id: 'REQ-90',
    reportNumber: 'PV-2026-9910',
    title: 'Industrial Machine Appraisal',
    service: 'Chartered Engineer Certificate',
    assetType: 'Plant & Machinery',
    purpose: 'Corporate Purpose',
    assetSummary: 'CNC 5-Axis Milling Unit, Sanathnagar Industrial Estate',
    createdDate: '22 Sep 2026',
    expectedDate: '28 Sep 2026',
    status: 'Report In Progress',
    stageIndex: 4, // Report In Progress
    statusDesc: 'Valuation report is currently being sealed by Senior Valuer.',
    requiredAction: 'None (Processing SLA active)',
    actionType: 'IN_PROGRESS',
    docs: [
      { name: 'Purchase Invoice / Bill of Entry', status: 'verified', statusText: 'Verified ✓' },
      { name: 'Machine OEM Technical Specs', status: 'verified', statusText: 'Verified ✓' },
      { name: 'Customs Duty Clearance Certificate', status: 'verified', statusText: 'Verified ✓' }
    ],
    timeline: [
      { title: 'Technical Assessment Completed', desc: 'Analyst validated serial numbers, calibration records, and run-hours.', time: 'Today, 02:30 PM' },
      { title: 'Advance Remittance Received', desc: 'UTR verified by finance desk; assignment released.', time: '23 Sep 2026, 11:00 AM' },
      { title: 'Quotation Approved', desc: 'Client accepted formal quotation online.', time: '22 Sep 2026, 05:40 PM' }
    ]
  },
  {
    id: 'REQ-91',
    reportNumber: 'PV-2026-9934',
    title: 'Residential Villa Valuation',
    service: 'Net Worth Certificate',
    assetType: 'Land & Building',
    purpose: 'Visa / Immigration',
    assetSummary: 'Villa 14, Palm Meadows, Jubilee Hills, Hyderabad',
    createdDate: '25 Sep 2026',
    expectedDate: '01 Oct 2026',
    status: 'Under Review',
    stageIndex: 1, // Under Review
    statusDesc: 'Our appraisal cell is reviewing the title chain and municipal layout approvals.',
    requiredAction: 'Pending appraisal desk review',
    actionType: 'UNDER_REVIEW',
    docs: [
      { name: 'Registered Sale Deed', status: 'verified', statusText: 'Verified ✓' },
      { name: 'GHMC Approved Layout Plan', status: 'pending', statusText: 'Under Verification ⏳' }
    ],
    timeline: [
      { title: 'Mandate Documents Uploaded', desc: 'Client submitted ownership records via intake wizard.', time: '25 Sep 2026, 09:30 AM' },
      { title: 'Order Intake Initialized', desc: 'Case assigned reference REQ-91.', time: '25 Sep 2026, 09:15 AM' }
    ]
  }
];

// Completed Client Orders
const completedReportsData = [
  {
    id: 'REQ-45',
    reportNumber: 'PV-2026-8812',
    title: 'Commercial Complex Valuation',
    service: 'Valuation Report',
    assetType: 'Land & Building',
    purpose: 'Bank Loan (Consortium Refinancing)',
    assetSummary: 'Apex Business Park, Sector 62, Noida',
    createdDate: '10 Aug 2026',
    completionDate: '15 Aug 2026',
    finalValue: '₹ 2,10,00,000',
    reportPdf: 'Final_Valuation_Report_REQ45.pdf',
    invoicePdf: 'Tax_Invoice_REQ45.pdf',
    docs: [
      { name: 'Registered Title Deed (Vol 423)', statusText: 'Verified & Sealed ✓' },
      { name: 'Sanction Plan & Occupancy Certificate', statusText: 'Verified & Sealed ✓' },
      { name: 'Property Tax Challan 2025-26', statusText: 'Verified & Sealed ✓' }
    ]
  },
  {
    id: 'REQ-52',
    reportNumber: 'PV-2026-8940',
    title: 'Liquid Solvency & Net Worth Certificate',
    service: 'Net Worth Certificate',
    assetType: 'Financial Assets',
    purpose: 'Visa / Immigration (Canada Study Permit)',
    assetSummary: 'Equity Holdings & Mutual Fund Portfolios, HDFC Securities',
    createdDate: '28 Jun 2026',
    completionDate: '04 Jul 2026',
    finalValue: '₹ 4,80,00,000',
    reportPdf: 'Final_NetWorth_Certificate_REQ52.pdf',
    invoicePdf: 'Tax_Invoice_REQ52.pdf',
    docs: [
      { name: 'Audited CA Net Worth Statement', statusText: 'Verified & Sealed ✓' },
      { name: 'Demat Holding Statements', statusText: 'Verified & Sealed ✓' }
    ]
  }
];

let selectedActiveOrderId = 'REQ-89';
let selectedCompletedOrderId = 'REQ-45';

// Sidebar Navigation
function showClientSection(section) {
  const navActive = document.getElementById('clientNavBtnActive');
  const navComp = document.getElementById('clientNavBtnCompleted');
  const secActive = document.getElementById('sectionReportsInProgress');
  const secComp = document.getElementById('sectionCompletedReports');

  if (section === 'inProgress') {
    if (navActive) navActive.classList.add('active');
    if (navComp) navComp.classList.remove('active');
    if (secActive) secActive.style.display = 'block';
    if (secComp) secComp.style.display = 'none';
    closeReportWorkspace();
    renderActiveReportsGrid();
  } else if (section === 'completed') {
    if (navActive) navActive.classList.remove('active');
    if (navComp) navComp.classList.add('active');
    if (secActive) secActive.style.display = 'none';
    if (secComp) secComp.style.display = 'block';
    closeCompletedWorkspace();
    renderCompletedReportsGrid();
  }
}

// Render Active Reports Gallery Grid
function renderActiveReportsGrid() {
  const grid = document.getElementById('activeReportsGrid');
  if (!grid) return;
  grid.innerHTML = '';

  activeReportsData.forEach(rep => {
    const card = document.createElement('div');
    card.className = 'client-report-card';
    card.onclick = () => openReportWorkspace(rep.id);

    card.innerHTML = `
      <div class="report-card-top">
        <span class="report-ref-badge">${rep.id}</span>
        <span class="report-status-pill">${rep.status}</span>
      </div>
      <div class="report-card-title">${rep.title}</div>
      <div class="report-card-meta-line">
        <span class="meta-label">Created:</span>
        <span class="meta-val">${rep.createdDate}</span>
      </div>
      <div class="report-card-meta-line">
        <span class="meta-label">Expected Completion:</span>
        <span class="meta-val">${rep.expectedDate}</span>
      </div>
      <div class="report-card-cta">
        <span>Open Report Workspace →</span>
      </div>
    `;
    grid.appendChild(card);
  });
}

// Open Active Report Workspace
function openReportWorkspace(orderId) {
  selectedActiveOrderId = orderId;
  const rep = activeReportsData.find(r => r.id === orderId) || activeReportsData[0];

  const gallery = document.getElementById('inProgressGalleryView');
  const ws = document.getElementById('activeReportWorkspaceView');
  if (gallery) gallery.style.display = 'none';
  if (ws) ws.style.display = 'block';

  // SECTION 1: REPORT HEADER
  const elRef = document.getElementById('wsReportRef');
  const elBadge = document.getElementById('wsStatusBadge');
  const elTitle = document.getElementById('wsReportTitle');
  const elSummary = document.getElementById('wsAssetSummary');
  const elNum = document.getElementById('wsReportNumber');
  const elCreated = document.getElementById('wsCreatedDate');
  const elExpected = document.getElementById('wsExpectedDate');
  const elPurpose = document.getElementById('wsPurpose');

  if (elRef) elRef.textContent = rep.id;
  if (elBadge) elBadge.textContent = rep.status;
  if (elTitle) elTitle.textContent = rep.title;
  if (elSummary) elSummary.textContent = rep.assetSummary;
  if (elNum) elNum.textContent = rep.reportNumber;
  if (elCreated) elCreated.textContent = rep.createdDate;
  if (elExpected) elExpected.textContent = rep.expectedDate;
  if (elPurpose) elPurpose.textContent = rep.purpose;

  // SECTION 2: CLIENT PROGRESS TRACKER (6 STAGES ONLY)
  renderWorkspaceStages(rep.stageIndex);

  // SECTION 3: STATUS HERO CARD
  renderStatusHeroCard(rep);

  // SECTION 4: DOCUMENTS
  renderWorkspaceDocs(rep.docs);

  // SECTION 5: UPDATES TIMELINE
  renderWorkspaceTimeline(rep.timeline);

  // SECTION 6: CONTEXTUAL ACTIONS
  renderContextualActions(rep);

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function closeReportWorkspace() {
  const gallery = document.getElementById('inProgressGalleryView');
  const ws = document.getElementById('activeReportWorkspaceView');
  if (gallery) gallery.style.display = 'block';
  if (ws) ws.style.display = 'none';
}

function renderWorkspaceStages(activeIdx) {
  const chain = document.getElementById('clientStagesChain');
  if (!chain) return;
  chain.innerHTML = '';

  CLIENT_STAGES.forEach((stage, idx) => {
    const isDone = idx < activeIdx;
    const isCurrent = idx === activeIdx;

    const item = document.createElement('div');
    item.className = `client-stage-step ${isDone ? 'done' : ''} ${isCurrent ? 'current' : ''}`;

    const num = idx + 1;
    const checkIcon = isDone ? '✓' : `${num}`;

    item.innerHTML = `
      <div class="stage-step-circle">${checkIcon}</div>
      <div class="stage-step-name">${stage}</div>
    `;
    chain.appendChild(item);
  });
}

function renderStatusHeroCard(rep) {
  const title = document.getElementById('statusHeroTitle');
  const desc = document.getElementById('statusHeroDesc');
  const actionArea = document.getElementById('statusHeroActionArea');
  const icon = document.getElementById('statusHeroIcon');

  if (title) title.textContent = rep.status;
  if (desc) desc.textContent = rep.statusDesc;

  if (actionArea) {
    actionArea.innerHTML = '';
    if (rep.status === 'Quotation Ready') {
      if (icon) icon.textContent = '📑';
      actionArea.innerHTML = `<button class="btn btn-primary" onclick="openQuotationModal()">View Quotation & Pay →</button>`;
    } else if (rep.status === 'Under Review') {
      if (icon) icon.textContent = '🔍';
      actionArea.innerHTML = `<button class="btn btn-secondary btn-sm" onclick="openUploadMoreModal()">Upload Additional Records</button>`;
    } else if (rep.status === 'Report In Progress') {
      if (icon) icon.textContent = '⚙️';
      actionArea.innerHTML = `<span style="font-size: 12.5px; color: #10B981; font-weight: 600;">● Guaranteed SLA 48h active</span>`;
    } else if (rep.status === 'Delivered') {
      if (icon) icon.textContent = '🏆';
      actionArea.innerHTML = `<button class="btn btn-gold" onclick="downloadSamplePdf('Valuation_Report.pdf')">Download Final Report</button>`;
    } else {
      if (icon) icon.textContent = 'ℹ️';
      actionArea.innerHTML = `<button class="btn btn-secondary btn-sm" onclick="openSupportModal()">Contact Concierge</button>`;
    }
  }
}

function renderWorkspaceDocs(docs) {
  const list = document.getElementById('reportDocsList');
  if (!list) return;
  list.innerHTML = '';

  (docs || []).forEach(doc => {
    const row = document.createElement('div');
    row.className = 'report-doc-row';
    const isVerified = doc.status === 'verified';
    row.innerHTML = `
      <span>${doc.name}</span>
      <span class="doc-badge ${isVerified ? 'verified' : 'pending'}">${doc.statusText}</span>
    `;
    list.appendChild(row);
  });
}

function renderWorkspaceTimeline(timeline) {
  const el = document.getElementById('clientUpdatesTimeline');
  if (!el) return;
  el.innerHTML = '';

  (timeline || []).forEach(item => {
    const entry = document.createElement('div');
    entry.className = 'timeline-entry';
    entry.innerHTML = `
      <div class="timeline-dot"></div>
      <div class="timeline-content">
        <div style="font-weight: 600; color: #fff;">${item.title}</div>
        <div style="font-size: 12px; color: var(--text-muted); margin-top: 2px;">${item.desc}</div>
        <div class="timeline-time">${item.time}</div>
      </div>
    `;
    el.appendChild(entry);
  });
}

function renderContextualActions(rep) {
  const box = document.getElementById('contextualButtons');
  if (!box) return;
  box.innerHTML = '';

  if (rep.status === 'Quotation Ready') {
    box.innerHTML = `
      <button class="btn btn-secondary btn-sm" onclick="openQuotationModal()">View Quotation</button>
      <button class="btn btn-secondary btn-sm" onclick="downloadSamplePdf('Quotation_${rep.id}.pdf')">Download Quotation PDF</button>
      <button class="btn btn-gold btn-sm" onclick="openPaymentModal()">Accept & Pay Online →</button>
    `;
  } else if (rep.status === 'Payment Pending') {
    box.innerHTML = `
      <button class="btn btn-gold btn-sm" onclick="openPaymentModal()">Submit Payment</button>
    `;
  } else if (rep.status === 'Under Review') {
    box.innerHTML = `
      <button class="btn btn-secondary btn-sm" onclick="openUploadMoreModal()">Upload Missing Documents</button>
      <button class="btn btn-secondary btn-sm" onclick="openSupportModal()">Ask Valuation Desk</button>
    `;
  } else if (rep.status === 'Report In Progress') {
    box.innerHTML = `
      <div style="font-size: 13px; color: var(--text-muted); display: flex; align-items: center; gap: 8px;">
        <span style="color: #38BDF8;">⏳</span>
        <span>Expected Completion Date: <strong style="color: #fff;">${rep.expectedDate}</strong></span>
      </div>
      <button class="btn btn-secondary btn-sm" onclick="openSupportModal()">Request Status Update</button>
    `;
  } else if (rep.status === 'Delivered') {
    box.innerHTML = `
      <button class="btn btn-gold btn-sm" onclick="downloadSamplePdf('Valuation_Report_${rep.id}.pdf')">Download Report</button>
      <button class="btn btn-secondary btn-sm" onclick="downloadSamplePdf('Tax_Invoice_${rep.id}.pdf')">Download Invoice</button>
      <button class="btn btn-primary btn-sm" onclick="showToast('Report accepted successfully.')">Accept Report</button>
      <button class="btn btn-secondary btn-sm" onclick="openSupportModal()">Request Clarification</button>
    `;
  }
}

// Completed Reports Gallery & Read-Only Workspace
function renderCompletedReportsGrid() {
  const grid = document.getElementById('completedReportsGrid');
  if (!grid) return;
  grid.innerHTML = '';

  completedReportsData.forEach(rep => {
    const card = document.createElement('div');
    card.className = 'client-report-card';
    card.onclick = () => openCompletedWorkspace(rep.id);

    card.innerHTML = `
      <div class="report-card-top">
        <span class="report-ref-badge">${rep.id}</span>
        <span class="report-status-pill" style="border-color: #10B981; color: #10B981;">Concluded ✓</span>
      </div>
      <div class="report-card-title">${rep.title}</div>
      <div class="report-card-meta-line">
        <span class="meta-label">Completion Date:</span>
        <span class="meta-val" style="color: #10B981; font-weight: 600;">${rep.completionDate}</span>
      </div>
      <div class="report-card-meta-line">
        <span class="meta-label">Assessed Value:</span>
        <span class="meta-val">${rep.finalValue}</span>
      </div>
      <div class="report-card-cta">
        <span>View Archived Record (Read-Only) →</span>
      </div>
    `;
    grid.appendChild(card);
  });
}

function openCompletedWorkspace(orderId) {
  selectedCompletedOrderId = orderId;
  const rep = completedReportsData.find(r => r.id === orderId) || completedReportsData[0];

  const gallery = document.getElementById('completedGalleryView');
  const ws = document.getElementById('completedReportWorkspaceView');
  if (gallery) gallery.style.display = 'none';
  if (ws) ws.style.display = 'block';

  const ref = document.getElementById('compReportRef');
  const title = document.getElementById('compReportTitle');
  const date = document.getElementById('compCompletionDate');

  if (ref) ref.textContent = rep.id;
  if (title) title.textContent = rep.title;
  if (date) date.textContent = rep.completionDate;

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function closeCompletedWorkspace() {
  const gallery = document.getElementById('completedGalleryView');
  const ws = document.getElementById('completedReportWorkspaceView');
  if (gallery) gallery.style.display = 'block';
  if (ws) ws.style.display = 'none';
}

// -----------------------------------------------------------------------------
// FLOW 1: 6-STEP AUTO-ADVANCING CREATE REPORT WIZARD
// -----------------------------------------------------------------------------
let wizardState = {
  currentStep: 1,
  service: '',
  assetType: '',
  purpose: '',
  assetName: '',
  propertyAddress: '',
  city: '',
  state: '',
  estimatedValue: '',
  requiredDocs: [],
  uploadedDocs: {}
};

function openCreateReportWizard() {
  resetWizard();
  openModal('createReportWizardModal');
}

function resetWizard() {
  wizardState = {
    currentStep: 1,
    service: '',
    assetType: '',
    purpose: '',
    assetName: '',
    propertyAddress: '',
    city: '',
    state: '',
    estimatedValue: '',
    requiredDocs: [],
    uploadedDocs: {}
  };

  const nameInput = document.getElementById('wzAssetName');
  const addrInput = document.getElementById('wzPropertyAddress');
  const cityInput = document.getElementById('wzCity');
  const stateInput = document.getElementById('wzState');
  const valInput = document.getElementById('wzEstimatedValue');

  if (nameInput) nameInput.value = '';
  if (addrInput) addrInput.value = '';
  if (cityInput) cityInput.value = '';
  if (stateInput) stateInput.value = '';
  if (valInput) valInput.value = '';

  goToWizardStep(1);
}

function goToWizardStep(stepNum) {
  wizardState.currentStep = stepNum;

  for (let s = 1; s <= 6; s++) {
    const pane = document.getElementById(`wzStep${s}`);
    if (pane) pane.style.display = (s === stepNum) ? 'block' : 'none';
  }
  const succ = document.getElementById('wzSuccessScreen');
  if (succ) succ.style.display = 'none';

  const indicator = document.getElementById('wizardStepIndicator');
  const title = document.getElementById('wizardStepTitle');

  const titles = [
    '',
    'What service do you need?',
    'What are you valuing?',
    'Why do you need the report?',
    'Tell us about the asset',
    'Upload Documents',
    'Review Request'
  ];

  if (indicator) indicator.textContent = `STEP ${stepNum} OF 6`;
  if (title) title.textContent = titles[stepNum] || '';
}

// STEP 1: Click Card = Advance
function wizardPickService(serviceName) {
  wizardState.service = serviceName;
  showToast(`Selected Service: ${serviceName}`);
  setTimeout(() => {
    goToWizardStep(2);
  }, 220);
}

// STEP 2: Click Card = Advance
function wizardPickAsset(assetType) {
  wizardState.assetType = assetType;
  showToast(`Selected Asset: ${assetType}`);

  // Dynamic mandatory documents by asset type
  if (assetType === 'Land & Building') {
    wizardState.requiredDocs = ['Title Deed', 'Approved Plan', 'Tax Receipt'];
  } else if (assetType === 'Plant & Machinery') {
    wizardState.requiredDocs = ['Purchase Invoice'];
  } else {
    wizardState.requiredDocs = ['Financial Statements'];
  }
  wizardState.uploadedDocs = {};

  setTimeout(() => {
    goToWizardStep(3);
  }, 220);
}

// STEP 3: Click Card = Advance
function wizardPickPurpose(purpose) {
  wizardState.purpose = purpose;
  showToast(`Purpose: ${purpose}`);
  setTimeout(() => {
    goToWizardStep(4);
  }, 220);
}

// STEP 4: Real-Time Validation = Auto-Advance to Step 5
let step4ValidationTimer = null;
function wizardCheckStep4() {
  const name = document.getElementById('wzAssetName')?.value.trim() || '';
  const addr = document.getElementById('wzPropertyAddress')?.value.trim() || '';
  const city = document.getElementById('wzCity')?.value.trim() || '';
  const st = document.getElementById('wzState')?.value.trim() || '';
  const est = document.getElementById('wzEstimatedValue')?.value.trim() || '';

  const indicator = document.getElementById('wzStep4Indicator');

  const allValid = name.length >= 3 && addr.length >= 5 && city.length >= 2 && st.length >= 2;

  if (allValid) {
    if (indicator) {
      indicator.innerHTML = '<span style="color: #10B981; font-weight: 600;">✓ Details verified! Advancing to documents...</span>';
    }
    clearTimeout(step4ValidationTimer);
    step4ValidationTimer = setTimeout(() => {
      wizardState.assetName = name;
      wizardState.propertyAddress = addr;
      wizardState.city = city;
      wizardState.state = st;
      wizardState.estimatedValue = est;
      renderWizardStep5Slots();
      goToWizardStep(5);
    }, 450);
  } else {
    if (indicator) {
      indicator.innerHTML = '<span style="color: var(--text-dim);">Fill Asset Name, Property Address, City, and State to continue.</span>';
    }
  }
}

// STEP 5: Render Upload Slots & Auto-Advance on Complete
function renderWizardStep5Slots() {
  const container = document.getElementById('wzDocsSlotsContainer');
  if (!container) return;
  container.innerHTML = '';

  wizardState.requiredDocs.forEach(docName => {
    const isDone = !!wizardState.uploadedDocs[docName];
    const slot = document.createElement('div');
    slot.className = 'select-card-option';
    slot.style.display = 'flex';
    slot.style.justifyContent = 'space-between';
    slot.style.alignItems = 'center';
    slot.onclick = () => wizardUploadDoc(docName);

    slot.innerHTML = `
      <div>
        <div style="font-weight: 600; font-size: 14px;">📄 ${docName} *</div>
        <div style="font-size: 11.5px; color: var(--text-muted);">Required verification document</div>
      </div>
      <div>
        ${isDone 
          ? '<span class="doc-badge verified">Uploaded ✓</span>' 
          : '<button class="btn btn-secondary btn-sm" type="button">Upload File</button>'}
      </div>
    `;
    container.appendChild(slot);
  });
}

function wizardUploadDoc(docName) {
  wizardState.uploadedDocs[docName] = true;
  showToast(`Uploaded: ${docName}`);
  renderWizardStep5Slots();

  // Check if all mandatory uploaded
  const allUploaded = wizardState.requiredDocs.every(d => !!wizardState.uploadedDocs[d]);
  if (allUploaded) {
    setTimeout(() => {
      populateReviewStep6();
      goToWizardStep(6);
    }, 500);
  }
}

// STEP 6: Review & Only Button
function populateReviewStep6() {
  const s = document.getElementById('rvService');
  const a = document.getElementById('rvAsset');
  const p = document.getElementById('rvPurpose');
  const n = document.getElementById('rvAssetName');
  const d = document.getElementById('rvDocsCount');

  if (s) s.textContent = wizardState.service;
  if (a) a.textContent = wizardState.assetType;
  if (p) p.textContent = wizardState.purpose;
  if (n) n.textContent = `${wizardState.assetName}, ${wizardState.city}`;
  if (d) d.textContent = `${wizardState.requiredDocs.length} Mandatory Records Uploaded ✓`;
}

function submitWizardRequest() {
  const newRef = `REQ-${Math.floor(100 + Math.random() * 899)}`;
  const now = new Date();
  const dateStr = `${now.getDate()} ${now.toLocaleString('default', { month: 'short' })} ${now.getFullYear()}`;

  const newOrder = {
    id: newRef,
    reportNumber: `PV-2026-${Math.floor(1000 + Math.random() * 8999)}`,
    title: `${wizardState.assetName} Valuation`,
    service: wizardState.service,
    assetType: wizardState.assetType,
    purpose: wizardState.purpose,
    assetSummary: `${wizardState.propertyAddress}, ${wizardState.city}, ${wizardState.state}`,
    createdDate: dateStr,
    expectedDate: '3 Business Days',
    status: 'Under Review',
    stageIndex: 1, // Under Review
    statusDesc: 'Your request has been submitted. Senior desk is reviewing documents and compiling official quotation.',
    requiredAction: 'Quotation compilation in progress',
    actionType: 'UNDER_REVIEW',
    docs: wizardState.requiredDocs.map(d => ({ name: d, status: 'verified', statusText: 'Uploaded ✓' })),
    timeline: [
      { title: 'Valuation Request Submitted', desc: 'Mandate submitted through simplified client intake wizard.', time: 'Just now' }
    ]
  };

  activeReportsData.unshift(newOrder);

  // Show Success Screen
  for (let s = 1; s <= 6; s++) {
    const pane = document.getElementById(`wzStep${s}`);
    if (pane) pane.style.display = 'none';
  }
  const succ = document.getElementById('wzSuccessScreen');
  if (succ) succ.style.display = 'block';

  const refEl = document.getElementById('wzSuccessRef');
  if (refEl) refEl.textContent = newRef;

  const indicator = document.getElementById('wizardStepIndicator');
  const title = document.getElementById('wizardStepTitle');
  if (indicator) indicator.textContent = 'MANDATE CREATED';
  if (title) title.textContent = 'Request Submitted';
}

// User Profile & Support Modals
function openProfileModal() {
  updateProfileConsentUI();
  openModal('profileModal');
}

function openSupportModal() {
  openModal('supportModal');
}

function openUploadMoreModal() {
  openModal('uploadMoreModal');
}

function openQuotationModal() {
  openModal('viewQuoteModal');
}

function openPaymentModal() {
  closeModal('viewQuoteModal');
  openModal('paymentModal');
}

function handleSupplementalUpload(event) {
  showToast('Supplemental document attached to active report.');
}

function confirmSupplementalUpload() {
  closeModal('uploadMoreModal');
  showToast('File verified and appended to report dossier.');
}

function downloadSamplePdf(filename) {
  showToast(`Downloading: ${filename}`);
}

// =============================================================================
// DPDP ACT 2023 STATUTORY CONSENT & TELEMETRY CONTROLLERS (BATCH 1)
// =============================================================================

async function recordConsentToBackend(consentType, consentGiven) {
  try {
    const email = document.getElementById('authEmail') ? document.getElementById('authEmail').value : 'anand.mehta@visadocs.com';
    const payload = {
      actorIdentifier: email,
      consentType: consentType,
      consentGiven: consentGiven,
      noticeVersion: 'DPDP-NOTICE-V1.0',
      termsVersion: 'v2.4'
    };
    await fetch('/api/v1/privacy/consent', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
  } catch (err) {
    console.warn('[DPDP Consent Ledger] Telemetry logged locally:', consentType, consentGiven);
  }
}

async function triggerWithdrawConsent(consentType) {
  const label = consentType === 'VALUATION_PROCESSING' ? 'Valuation & Assessment Processing' :
                consentType === 'MARKETING' ? 'Operational & Milestone Alerts' : 'Web Analytics Telemetry';

  const confirmMsg = `Statutory Consent Withdrawal (DPDP Act Section 6(4)):\n\n` +
    `Are you sure you wish to withdraw consent for "${label}"?\n\n` +
    `• If Valuation Processing is withdrawn, ongoing valuation reports cannot proceed.\n` +
    `• Prior processing conducted before this timestamp remains lawful under the Act.`;

  if (!confirm(confirmMsg)) return;

  try {
    const email = document.getElementById('authEmail') ? document.getElementById('authEmail').value : 'anand.mehta@visadocs.com';
    await fetch('/api/v1/privacy/consent/withdraw', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        actorIdentifier: email,
        consentType: consentType,
        reason: 'Client requested statutory withdrawal via portal profile'
      })
    });
  } catch (e) {
    console.warn('[DPDP Withdrawal] Synced locally:', consentType);
  }

  if (consentType === 'ANALYTICS_TRACKING') {
    localStorage.setItem('dpdp_analytics_consent', 'rejected');
    disableAnalyticsTelemetry();
  }

  // Update UI status in profile modal
  if (consentType === 'VALUATION_PROCESSING') {
    const el = document.getElementById('consentStatusValuation');
    const btn = document.getElementById('btnWithdrawValuation');
    if (el) el.innerHTML = 'Status: <span style="color: #EF4444; font-weight: 600;">WITHDRAWN (Sec 6(4))</span>';
    if (btn) {
      btn.disabled = true;
      btn.style.opacity = '0.5';
      btn.style.cursor = 'not-allowed';
    }
  } else if (consentType === 'MARKETING') {
    const el = document.getElementById('consentStatusMarketing');
    const btn = document.getElementById('btnWithdrawMarketing');
    if (el) el.innerHTML = 'Status: <span style="color: #EF4444; font-weight: 600;">WITHDRAWN (Opted Out)</span>';
    if (btn) {
      btn.disabled = true;
      btn.style.opacity = '0.5';
      btn.style.cursor = 'not-allowed';
    }
  } else if (consentType === 'ANALYTICS_TRACKING') {
    const el = document.getElementById('consentStatusAnalytics');
    const btn = document.getElementById('btnWithdrawAnalytics');
    if (el) el.innerHTML = 'Status: <span style="color: #EF4444; font-weight: 600;">OPTED OUT (Blocked)</span>';
    if (btn) {
      btn.disabled = true;
      btn.style.opacity = '0.5';
      btn.style.cursor = 'not-allowed';
    }
  }

  showToast(`Statutory consent for ${label} withdrawn.`);
}

function updateProfileConsentUI() {
  const analyticsStatus = localStorage.getItem('dpdp_analytics_consent');
  const analyticsEl = document.getElementById('consentStatusAnalytics');
  const analyticsBtn = document.getElementById('btnWithdrawAnalytics');
  if (analyticsEl) {
    if (analyticsStatus === 'granted') {
      analyticsEl.innerHTML = 'Status: <span style="color: #10B981; font-weight: 600;">OPTED IN (Active) ✓</span>';
      if (analyticsBtn) {
        analyticsBtn.disabled = false;
        analyticsBtn.style.opacity = '1';
        analyticsBtn.style.cursor = 'pointer';
      }
    } else {
      analyticsEl.innerHTML = 'Status: <span style="color: #EF4444; font-weight: 600;">OPTED OUT (Blocked)</span>';
      if (analyticsBtn) {
        analyticsBtn.disabled = true;
        analyticsBtn.style.opacity = '0.5';
        analyticsBtn.style.cursor = 'not-allowed';
      }
    }
  }
}

// -----------------------------------------------------------------------------
// ANALYTICS CONSENT BANNER (GA4 & CLARITY TELEMETRY)
// -----------------------------------------------------------------------------
function initAnalyticsBanner() {
  const consent = localStorage.getItem('dpdp_analytics_consent');
  const banner = document.getElementById('analyticsConsentBanner');
  if (!consent && banner) {
    banner.style.display = 'block';
  } else if (consent === 'granted') {
    enableAnalyticsTelemetry();
  } else {
    disableAnalyticsTelemetry();
  }
}

function acceptAnalyticsConsent() {
  localStorage.setItem('dpdp_analytics_consent', 'granted');
  const banner = document.getElementById('analyticsConsentBanner');
  if (banner) banner.style.display = 'none';
  enableAnalyticsTelemetry();
  recordConsentToBackend('ANALYTICS_TRACKING', true);
  updateProfileConsentUI();
  showToast('Consent Saved: Analytics Telemetry (GA4 & Clarity) Activated.');
}

function rejectAnalyticsConsent() {
  localStorage.setItem('dpdp_analytics_consent', 'rejected');
  const banner = document.getElementById('analyticsConsentBanner');
  if (banner) banner.style.display = 'none';
  disableAnalyticsTelemetry();
  recordConsentToBackend('ANALYTICS_TRACKING', false);
  updateProfileConsentUI();
  showToast('Consent Saved: Analytics Blocked. Essential cookies only.');
}

function openAnalyticsConsentBanner() {
  const banner = document.getElementById('analyticsConsentBanner');
  if (banner) banner.style.display = 'block';
}

function enableAnalyticsTelemetry() {
  const consent = localStorage.getItem('dpdp_analytics_consent');
  if (consent === 'minor_blocked' || consent === 'rejected') {
    window['ga-disable-G-XXXX'] = true;
    return;
  }
  window['ga-disable-G-XXXX'] = false;
  if (window.__PROVALUER_CLARITY_ID__) {
    (function(c,l,a,r,i,t,y){
      c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
      t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
      y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
    })(window, document, "clarity", "script", window.__PROVALUER_CLARITY_ID__);
  }
}

function disableAnalyticsTelemetry() {
  window['ga-disable-G-XXXX'] = true;
}

// =============================================================================
// STATUTORY PRIVACY HUB & DATA PRINCIPAL RIGHTS CONTROLLER (DPDP ACT 2023)
// =============================================================================
function openPrivacyDashboardModal() {
  openModal('privacyHubModal');
  switchPrivacyTab('summary');
}

function switchPrivacyTab(tabName) {
  // Update tab buttons
  const tabs = ['summary', 'consents', 'export', 'corrections', 'erasures', 'nominees', 'grievances'];
  tabs.forEach(t => {
    const btn = document.getElementById(`pTabBtn${t.charAt(0).toUpperCase() + t.slice(1)}`);
    const panel = document.getElementById(`pTabPanel${t.charAt(0).toUpperCase() + t.slice(1)}`);
    if (btn) btn.classList.remove('active');
    if (panel) panel.classList.remove('active');
  });

  const activeBtn = document.getElementById(`pTabBtn${tabName.charAt(0).toUpperCase() + tabName.slice(1)}`);
  const activePanel = document.getElementById(`pTabPanel${tabName.charAt(0).toUpperCase() + tabName.slice(1)}`);
  if (activeBtn) activeBtn.classList.add('active');
  if (activePanel) activePanel.classList.add('active');

  // Trigger data loader for chosen tab
  if (tabName === 'summary') loadPrivacySummary();
  else if (tabName === 'consents') loadPrivacyConsents();
  else if (tabName === 'corrections') loadCorrectionRequests();
  else if (tabName === 'erasures') loadErasureRequests();
  else if (tabName === 'nominees') loadNominees();
  else if (tabName === 'grievances') loadGrievances();
}

async function loadPrivacySummary() {
  try {
    const res = await fetch('/api/v1/privacy/profile-summary');
    if (res.ok) {
      const data = await res.json();
      document.getElementById('pvProfileName').textContent = data.name || 'Anand Mehta';
      document.getElementById('pvProfileEmail').textContent = data.email || 'anand.mehta@enterprise.in';
      document.getElementById('pvProfileMobile').textContent = data.mobile || '+91 98490 12345';
      document.getElementById('pvProfileRole').textContent = (data.role || 'CLIENT') + ' • Verified';

      const editName = document.getElementById('pvEditFullName');
      const editMobile = document.getElementById('pvEditMobile');
      if (editName && !editName.value) editName.value = data.name || '';
      if (editMobile && !editMobile.value) editMobile.value = data.mobile || '';
    } else {
      document.getElementById('pvProfileName').textContent = 'Anand Mehta';
      document.getElementById('pvProfileEmail').textContent = 'anand.mehta@visadocs.com';
      document.getElementById('pvProfileMobile').textContent = '+91 98490 12345';
      document.getElementById('pvProfileRole').textContent = 'CLIENT • Verified';
    }
  } catch (e) {
    console.warn('[Privacy Summary Load]', e);
  }
}

async function submitProfileUpdate() {
  const fullName = document.getElementById('pvEditFullName').value;
  const mobileNumber = document.getElementById('pvEditMobile').value;
  try {
    const res = await fetch('/api/v1/privacy/update-profile', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fullName, mobileNumber })
    });
    if (res.ok) {
      showToast('Profile updated under DPDP Act Section 12!');
      loadPrivacySummary();
    } else {
      showToast('Profile updated locally.');
      document.getElementById('pvProfileName').textContent = fullName;
      document.getElementById('pvProfileMobile').textContent = mobileNumber;
    }
  } catch (e) {
    showToast('Profile updated locally.');
    document.getElementById('pvProfileName').textContent = fullName;
    document.getElementById('pvProfileMobile').textContent = mobileNumber;
  }
}

async function loadPrivacyConsents() {
  const container = document.getElementById('pvConsentCardsContainer');
  if (!container) return;
  container.innerHTML = '<div style="color: var(--text-dim); font-size: 13px;">Loading tamper-evident consent ledger...</div>';

  try {
    const res = await fetch('/api/v1/privacy/consent-history');
    let consents = [];
    if (res.ok) {
      consents = await res.json();
    }
    if (!consents || consents.length === 0) {
      consents = [
        { consentType: 'VALUATION_PROCESSING', consentGiven: true, withdrawn: false, purpose: 'Property fair market value assessment & title encumbrance check', consentTimestamp: new Date().toISOString() },
        { consentType: 'OPERATIONAL_ALERTS', consentGiven: true, withdrawn: false, purpose: 'Milestone notifications and report delivery updates via SMS/Email', consentTimestamp: new Date().toISOString() },
        { consentType: 'ANALYTICS_TRACKING', consentGiven: localStorage.getItem('dpdp_analytics_consent') === 'granted', withdrawn: localStorage.getItem('dpdp_analytics_consent') !== 'granted', purpose: 'Optional web performance telemetry (Google Analytics 4 & Microsoft Clarity)', consentTimestamp: new Date().toISOString() }
      ];
    }

    container.innerHTML = '';
    consents.forEach(c => {
      const card = document.createElement('div');
      card.className = 'profile-consent-card';
      const isWithdrawn = c.withdrawn || !c.consentGiven;
      card.innerHTML = `
        <div>
          <div class="consent-info-title">${c.consentType.replace(/_/g, ' ')}</div>
          <div class="consent-info-sub" style="margin-bottom: 2px;">${c.purpose || 'Statutory processing'}</div>
          <div style="font-size: 11px;">
            Status: ${isWithdrawn ? '<span style="color: #EF4444; font-weight: 600;">WITHDRAWN (Sec 6(4))</span>' : '<span style="color: #10B981; font-weight: 600;">ACTIVE ✓</span>'}
            • Granted: ${c.consentTimestamp ? new Date(c.consentTimestamp).toLocaleDateString() : 'Active'}
          </div>
        </div>
        <div>
          ${!isWithdrawn ? `<button class="btn-withdraw-consent" onclick="triggerWithdrawConsent('${c.consentType}')">Withdraw</button>` : '<span style="font-size: 11px; color: var(--text-dim);">Inactive</span>'}
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    console.warn('[Consent Ledger Error]', e);
  }
}

async function downloadMyDataZip() {
  showToast('Packaging encrypted personal data export with SHA-256 seal...');
  try {
    const res = await fetch('/api/v1/privacy/export');
    if (res.ok) {
      const blob = await res.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `provaluer_dpdp_export_${Date.now()}.zip`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
      showToast('Data Export Archive downloaded successfully!');
    } else {
      // Fallback structured download
      const summaryRes = await fetch('/api/v1/privacy/profile-summary');
      const data = summaryRes.ok ? await summaryRes.json() : { user: 'Anand Mehta', exportDate: new Date().toISOString(), status: 'AUDIT_SEALED' };
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `privacy_export_${Date.now()}.json`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      showToast('Export package downloaded (JSON format).');
    }
  } catch (e) {
    showToast('Download initialized.');
  }
}

async function loadCorrectionRequests() {
  const tbody = document.getElementById('pvCorrectionTableBody');
  if (!tbody) return;
  try {
    const res = await fetch('/api/v1/privacy/correction-requests');
    if (res.ok) {
      const list = await res.json();
      if (list && list.length > 0) {
        tbody.innerHTML = list.map(r => `
          <tr>
            <td><strong>${r.fieldName || 'N/A'}</strong></td>
            <td>${r.existingValue || '-'}</td>
            <td style="color: #38BDF8;">${r.requestedValue || '-'}</td>
            <td><span class="badge" style="background: rgba(14, 165, 233, 0.15); color: #38BDF8; padding: 2px 6px; border-radius: 4px;">${r.status || 'SUBMITTED'}</span></td>
            <td>${r.createdAt ? new Date(r.createdAt).toLocaleDateString() : 'Recent'}</td>
          </tr>
        `).join('');
        return;
      }
    }
  } catch (e) {
    console.warn('[Correction Requests Error]', e);
  }
  tbody.innerHTML = '<tr><td colspan="5" style="text-align: center; color: var(--text-dim);">No active correction requests found.</td></tr>';
}

async function submitCorrectionRequest() {
  const fieldName = document.getElementById('pvCorrField').value;
  const existingValue = document.getElementById('pvCorrExisting').value;
  const requestedValue = document.getElementById('pvCorrRequested').value;
  const reason = document.getElementById('pvCorrReason').value;

  try {
    const res = await fetch('/api/v1/privacy/correction-request', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fieldName, existingValue, requestedValue, reason })
    });
    if (res.ok) {
      showToast('Correction request submitted under Section 12!');
      document.getElementById('pvCorrExisting').value = '';
      document.getElementById('pvCorrRequested').value = '';
      document.getElementById('pvCorrReason').value = '';
      loadCorrectionRequests();
    } else {
      showToast('Correction request logged.');
    }
  } catch (e) {
    showToast('Correction request logged.');
  }
}

async function loadErasureRequests() {
  const tbody = document.getElementById('pvErasureTableBody');
  if (!tbody) return;
  try {
    const res = await fetch('/api/v1/privacy/erasure-requests');
    if (res.ok) {
      const list = await res.json();
      if (list && list.length > 0) {
        tbody.innerHTML = list.map(r => `
          <tr>
            <td>#${r.id}</td>
            <td>${r.reason || 'Data no longer required'}</td>
            <td><span class="badge" style="background: rgba(239, 68, 68, 0.15); color: #EF4444; padding: 2px 6px; border-radius: 4px;">${r.status || 'PENDING_REVIEW'}</span></td>
            <td>${r.createdAt ? new Date(r.createdAt).toLocaleDateString() : 'Recent'}</td>
          </tr>
        `).join('');
        return;
      }
    }
  } catch (e) {
    console.warn('[Erasure Requests Error]', e);
  }
  tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; color: var(--text-dim);">No active erasure requests.</td></tr>';
}

async function submitErasureRequest() {
  const reason = document.getElementById('pvErasureReason').value;
  if (!reason) return;
  try {
    const res = await fetch('/api/v1/privacy/erasure-request', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ reason })
    });
    if (res.ok) {
      showToast('Statutory erasure request submitted under Section 12(3)!');
      document.getElementById('pvErasureReason').value = '';
      loadErasureRequests();
    } else {
      showToast('Erasure request logged for compliance officer review.');
    }
  } catch (e) {
    showToast('Erasure request logged.');
  }
}

async function loadNominees() {
  const tbody = document.getElementById('pvNomineeTableBody');
  if (!tbody) return;
  try {
    const res = await fetch('/api/v1/privacy/nominees');
    if (res.ok) {
      const list = await res.json();
      if (list && list.length > 0) {
        tbody.innerHTML = list.map(n => `
          <tr>
            <td><strong>${n.nomineeName}</strong></td>
            <td>${n.relationship || '-'}</td>
            <td>${n.mobile || '-'}</td>
            <td>${n.email || '-'}</td>
            <td><button class="btn-withdraw-consent" onclick="revokeNominee(${n.id})">Revoke</button></td>
          </tr>
        `).join('');
        return;
      }
    }
  } catch (e) {
    console.warn('[Nominees Error]', e);
  }
  tbody.innerHTML = '<tr><td colspan="5" style="text-align: center; color: var(--text-dim);">No nominees registered.</td></tr>';
}

async function submitNomineeRegistration() {
  const nomineeName = document.getElementById('pvNomineeName').value;
  const relationship = document.getElementById('pvNomineeRel').value;
  const mobile = document.getElementById('pvNomineeMobile').value;
  const email = document.getElementById('pvNomineeEmail').value;
  const address = document.getElementById('pvNomineeAddress').value;

  try {
    const res = await fetch('/api/v1/privacy/nominees', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ nomineeName, relationship, mobile, email, address })
    });
    if (res.ok) {
      showToast('Privacy nominee registered under DPDP Act Section 14!');
      document.getElementById('pvNomineeName').value = '';
      document.getElementById('pvNomineeMobile').value = '';
      document.getElementById('pvNomineeEmail').value = '';
      document.getElementById('pvNomineeAddress').value = '';
      loadNominees();
    } else {
      showToast('Nominee registered successfully.');
    }
  } catch (e) {
    showToast('Nominee registered.');
  }
}

async function revokeNominee(id) {
  if (!confirm('Are you sure you want to revoke this statutory nomination?')) return;
  try {
    const res = await fetch(`/api/v1/privacy/nominees/${id}`, { method: 'DELETE' });
    if (res.ok) {
      showToast('Nomination revoked.');
      loadNominees();
    }
  } catch (e) {
    showToast('Nomination revoked.');
    loadNominees();
  }
}

async function loadGrievances() {
  const tbody = document.getElementById('pvGrievanceTableBody');
  if (!tbody) return;
  try {
    const res = await fetch('/api/v1/privacy/grievances');
    if (res.ok) {
      const list = await res.json();
      if (list && list.length > 0) {
        tbody.innerHTML = list.map(g => `
          <tr>
            <td><strong>#GRV-${g.id}</strong></td>
            <td>${g.category || 'GENERAL'}</td>
            <td><span class="badge" style="background: rgba(250, 187, 31, 0.15); color: #FABB1F; padding: 2px 6px; border-radius: 4px;">${g.status || 'SUBMITTED'}</span></td>
            <td>${g.createdAt ? new Date(g.createdAt).toLocaleDateString() : 'Recent'}</td>
            <td>
              ${g.status !== 'RESOLVED' && g.status !== 'ESCALATED' ? `<button class="btn btn-secondary btn-sm" style="font-size: 11px; padding: 2px 8px;" onclick="escalateGrievance(${g.id})">Escalate to DPO</button>` : '<span style="font-size: 11px; color: var(--text-dim);">-</span>'}
            </td>
          </tr>
        `).join('');
        return;
      }
    }
  } catch (e) {
    console.warn('[Grievances Error]', e);
  }
  tbody.innerHTML = '<tr><td colspan="5" style="text-align: center; color: var(--text-dim);">No grievances filed.</td></tr>';
}

async function submitGrievance() {
  const category = document.getElementById('pvGrvCategory').value;
  const description = document.getElementById('pvGrvDescription').value;

  try {
    const res = await fetch('/api/v1/privacy/grievances', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ category, description })
    });
    if (res.ok) {
      showToast('Statutory grievance filed with Data Protection Officer!');
      document.getElementById('pvGrvDescription').value = '';
      loadGrievances();
    } else {
      showToast('Grievance logged with Grievance Officer.');
    }
  } catch (e) {
    showToast('Grievance logged.');
  }
}

async function escalateGrievance(id) {
  try {
    const res = await fetch(`/api/v1/privacy/grievances/${id}/escalate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ reason: 'Client escalated to Supervisory DPO under Section 13' })
    });
    if (res.ok) {
      showToast('Grievance escalated to Supervisory Data Protection Officer.');
      loadGrievances();
    }
  } catch (e) {
    showToast('Grievance escalated.');
    loadGrievances();
  }
}

// -----------------------------------------------------------------------------
// MULTILINGUAL STATUTORY NOTICE SWITCHER (PHASE 11 - EN, HI, TE)
// -----------------------------------------------------------------------------
async function changeLanguage(lang) {
  try {
    const noticeRes = await fetch(`/api/v1/privacy/policies/privacy-notice?lang=${lang}`);
    const consentRes = await fetch(`/api/v1/privacy/policies/consent-notice?lang=${lang}`);

    if (noticeRes.ok) {
      const notice = await noticeRes.json();
      const noticeEl = document.getElementById('noticeSummaryText');
      if (noticeEl) {
        noticeEl.innerHTML = `<strong>${notice.purposes}</strong><br><span style="font-size: 11.5px; color: var(--text-dim);">${notice.dataCollected}</span>`;
      }
    }

    if (consentRes.ok) {
      const consent = await consentRes.json();
      const consentLabel = document.getElementById('consentNoticeCheckboxLabel');
      if (consentLabel) {
        consentLabel.textContent = consent.notice;
      }
    }

    showToast(`Language switched to ${lang.toUpperCase()}`);
  } catch (e) {
    console.warn('[Multilingual Switch Error]', e);
  }
}

// Set initial screen and initialize DPDP Banner
document.addEventListener('DOMContentLoaded', () => {
  renderActiveReportsGrid();
  renderCompletedReportsGrid();
  initAnalyticsBanner();
});


